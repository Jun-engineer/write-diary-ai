import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient, GetCommand, PutCommand } from '../../shared/dynamodb';
import { success, created, badRequest, unauthorized, notFound, serverError } from '../../shared/response';
import { getUserIdFromEvent, parseBody, generateId, now } from '../../shared/utils';
import { 
  Diary, 
  ReviewCard,
  CreateReviewCardsRequest, 
  CreateReviewCardsResponse 
} from '../../shared/types';

const DIARIES_TABLE = process.env.DIARIES_TABLE!;
const REVIEW_CARDS_TABLE = process.env.REVIEW_CARDS_TABLE!;

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  console.log('CreateReviewCards event:', JSON.stringify(event));

  try {
    // Get user ID from JWT
    const userId = getUserIdFromEvent(event);
    if (!userId) {
      return unauthorized('Invalid token');
    }

    // Parse request body
    const body = parseBody<CreateReviewCardsRequest>(event);
    if (!body) {
      return badRequest('Invalid request body');
    }

    const { diaryId, selectedCorrections } = body;

    // Validate required fields
    if (!diaryId || !selectedCorrections || !Array.isArray(selectedCorrections)) {
      return badRequest('Missing required fields: diaryId, selectedCorrections');
    }

    if (selectedCorrections.length === 0) {
      return badRequest('No corrections selected');
    }

    // Get diary from DynamoDB
    const diaryResult = await docClient.send(new GetCommand({
      TableName: DIARIES_TABLE,
      Key: { diaryId },
    }));

    const diary = diaryResult.Item as Diary | undefined;

    if (!diary) {
      return notFound('Diary not found');
    }

    // Verify ownership
    if (diary.userId !== userId) {
      return notFound('Diary not found');
    }

    // Check if diary has corrections
    if (!diary.corrections || diary.corrections.length === 0) {
      return badRequest('Diary has no corrections. Run AI correction first.');
    }

    // Create review cards for selected corrections
    const createdCards: ReviewCard[] = [];
    const timestamp = now();

    for (const index of selectedCorrections) {
      if (index < 0 || index >= diary.corrections.length) {
        continue; // Skip invalid indices
      }

      const correction = diary.corrections[index];
      
      // Extract context around the correction (up to 100 chars)
      const context = extractContext(diary.correctedText || diary.originalText, correction.after);

      const card: ReviewCard = {
        cardId: generateId(),
        userId,
        diaryId,
        before: correction.before,
        after: correction.after,
        context,
        tags: [correction.type],
        createdAt: timestamp,
      };

      await docClient.send(new PutCommand({
        TableName: REVIEW_CARDS_TABLE,
        Item: card,
      }));

      createdCards.push(card);
    }

    const response: CreateReviewCardsResponse = {
      created: createdCards.length,
    };

    return created(response);
  } catch (error) {
    console.error('Error creating review cards:', error);
    return serverError('Failed to create review cards');
  }
}

/**
 * Extract context around a phrase from the text
 */
function extractContext(text: string, phrase: string): string {
  const index = text.indexOf(phrase);
  if (index === -1) {
    // If exact phrase not found, return beginning of text
    return text.substring(0, 100) + (text.length > 100 ? '...' : '');
  }

  // Get context with some characters before and after
  const contextPadding = 30;
  const start = Math.max(0, index - contextPadding);
  const end = Math.min(text.length, index + phrase.length + contextPadding);

  let context = text.substring(start, end);
  
  if (start > 0) {
    context = '...' + context;
  }
  if (end < text.length) {
    context = context + '...';
  }

  return context;
}
