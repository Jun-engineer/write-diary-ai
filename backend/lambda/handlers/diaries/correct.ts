import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient, GetCommand, UpdateCommand } from '../../shared/dynamodb';
import { success, badRequest, unauthorized, notFound, serverError } from '../../shared/response';
import { getUserIdFromEvent, parseBody, now } from '../../shared/utils';
import { 
  Diary, 
  CorrectDiaryRequest, 
  CorrectDiaryResponse, 
  Correction, 
  CorrectionMode 
} from '../../shared/types';

const DIARIES_TABLE = process.env.DIARIES_TABLE!;

// AI correction prompts by mode
const CORRECTION_PROMPTS: Record<CorrectionMode, string> = {
  beginner: `You are an English teacher helping a beginner student. 
Focus ONLY on grammar and spelling errors. 
Return corrections in a simple, encouraging way.`,
  
  intermediate: `You are an English teacher helping an intermediate student.
Correct grammar, spelling, and suggest more natural expressions.
Explain why certain phrases sound more natural in English.`,
  
  advanced: `You are an English teacher helping an advanced student.
Provide sophisticated corrections including:
- Grammar and spelling
- Natural expressions and idioms
- Paraphrases for variety
- Detailed explanations of nuances`,
};

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  console.log('CorrectDiary event:', JSON.stringify(event));

  try {
    // Get user ID from JWT
    const userId = getUserIdFromEvent(event);
    if (!userId) {
      return unauthorized('Invalid token');
    }

    // Get diary ID from path parameters
    const diaryId = event.pathParameters?.diaryId;
    if (!diaryId) {
      return badRequest('Diary ID is required');
    }

    // Parse request body
    const body = parseBody<CorrectDiaryRequest>(event);
    if (!body) {
      return badRequest('Invalid request body');
    }

    const { mode } = body;

    // Validate mode
    if (!mode || !['beginner', 'intermediate', 'advanced'].includes(mode)) {
      return badRequest('Invalid mode. Use: beginner, intermediate, or advanced');
    }

    // Get diary from DynamoDB
    const result = await docClient.send(new GetCommand({
      TableName: DIARIES_TABLE,
      Key: { diaryId },
    }));

    const diary = result.Item as Diary | undefined;

    if (!diary) {
      return notFound('Diary not found');
    }

    // Verify ownership
    if (diary.userId !== userId) {
      return notFound('Diary not found');
    }

    // Call AI for correction
    const { correctedText, corrections } = await correctWithAI(diary.originalText, mode);

    // Update diary with corrections
    await docClient.send(new UpdateCommand({
      TableName: DIARIES_TABLE,
      Key: { diaryId },
      UpdateExpression: 'SET correctedText = :correctedText, corrections = :corrections, updatedAt = :updatedAt',
      ExpressionAttributeValues: {
        ':correctedText': correctedText,
        ':corrections': corrections,
        ':updatedAt': now(),
      },
    }));

    const response: CorrectDiaryResponse = {
      correctedText,
      corrections,
    };

    return success(response);
  } catch (error) {
    console.error('Error correcting diary:', error);
    return serverError('Failed to correct diary');
  }
}

/**
 * Call AI service for text correction
 * This is a placeholder - replace with actual AI API call (OpenAI, Claude, etc.)
 */
async function correctWithAI(
  originalText: string, 
  mode: CorrectionMode
): Promise<{ correctedText: string; corrections: Correction[] }> {
  // TODO: Replace with actual AI API call
  // Example with OpenAI:
  // const response = await openai.chat.completions.create({
  //   model: 'gpt-4',
  //   messages: [
  //     { role: 'system', content: CORRECTION_PROMPTS[mode] },
  //     { role: 'user', content: `Please correct this diary entry and list all corrections:\n\n${originalText}` },
  //   ],
  //   response_format: { type: 'json_object' },
  // });

  // For now, return a mock response for testing
  console.log('AI correction requested with mode:', mode);
  console.log('System prompt:', CORRECTION_PROMPTS[mode]);
  console.log('Original text:', originalText);

  // Mock response - in production, parse AI response
  return {
    correctedText: originalText, // Would be AI-corrected text
    corrections: [], // Would be list of corrections from AI
  };
}
