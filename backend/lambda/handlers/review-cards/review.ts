import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { createResponse, createErrorResponse } from '../../shared/response';
import { ReviewRating } from '../../shared/types';

const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(dynamoClient);
const REVIEW_CARDS_TABLE = process.env.REVIEW_CARDS_TABLE!;

// SM-2 spaced repetition algorithm
function computeNextReview(
  rating: ReviewRating,
  currentInterval: number,
  currentEaseFactor: number,
): { interval: number; easeFactor: number } {
  let interval: number;
  let easeFactor: number;

  switch (rating) {
    case 'again':
      interval = 1;
      easeFactor = Math.max(1.3, currentEaseFactor - 0.2);
      break;
    case 'hard':
      interval = Math.max(1, Math.floor(currentInterval * 1.2));
      easeFactor = Math.max(1.3, currentEaseFactor - 0.15);
      break;
    case 'good':
      interval = Math.max(1, Math.floor(currentInterval * currentEaseFactor));
      easeFactor = currentEaseFactor; // No change
      break;
    case 'easy':
      interval = Math.max(1, Math.floor(currentInterval * currentEaseFactor * 1.3));
      easeFactor = Math.min(4.0, currentEaseFactor + 0.15);
      break;
  }

  return { interval, easeFactor };
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const userId = event.requestContext.authorizer?.claims?.sub;
  if (!userId) {
    return createErrorResponse(401, 'Unauthorized');
  }

  const cardId = event.pathParameters?.cardId;
  if (!cardId) {
    return createErrorResponse(400, 'Missing cardId');
  }

  if (!event.body) {
    return createErrorResponse(400, 'Missing body');
  }

  let body: { rating: ReviewRating };
  try {
    body = JSON.parse(event.body);
  } catch {
    return createErrorResponse(400, 'Invalid JSON');
  }

  const { rating } = body;
  if (!['again', 'hard', 'good', 'easy'].includes(rating)) {
    return createErrorResponse(400, 'rating must be one of: again, hard, good, easy');
  }

  // Fetch the card to get current SRS values
  const getResult = await docClient.send(
    new GetCommand({
      TableName: REVIEW_CARDS_TABLE,
      Key: { cardId },
    }),
  );

  const card = getResult.Item;
  if (!card) {
    return createErrorResponse(404, 'Card not found');
  }

  if (card.userId !== userId) {
    return createErrorResponse(403, 'Forbidden');
  }

  const currentInterval: number = card.interval ?? 1;
  const currentEaseFactor: number = card.easeFactor ?? 2.5;

  const { interval, easeFactor } = computeNextReview(rating, currentInterval, currentEaseFactor);

  const now = Date.now();
  const dueAt = now + interval * 24 * 60 * 60 * 1000;
  const reviewCount = (card.reviewCount ?? 0) + 1;

  await docClient.send(
    new UpdateCommand({
      TableName: REVIEW_CARDS_TABLE,
      Key: { cardId },
      UpdateExpression:
        'SET #interval = :interval, #easeFactor = :easeFactor, #dueAt = :dueAt, #lastReviewedAt = :lastReviewedAt, #reviewCount = :reviewCount',
      ExpressionAttributeNames: {
        '#interval': 'interval',
        '#easeFactor': 'easeFactor',
        '#dueAt': 'dueAt',
        '#lastReviewedAt': 'lastReviewedAt',
        '#reviewCount': 'reviewCount',
      },
      ExpressionAttributeValues: {
        ':interval': interval,
        ':easeFactor': easeFactor,
        ':dueAt': dueAt,
        ':lastReviewedAt': now,
        ':reviewCount': reviewCount,
      },
    }),
  );

  return createResponse(200, {
    cardId,
    rating,
    interval,
    easeFactor,
    dueAt,
    reviewCount,
  });
};
