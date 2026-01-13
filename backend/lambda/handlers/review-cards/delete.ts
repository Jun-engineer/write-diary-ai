import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient, GetCommand, DeleteCommand } from '../../shared/dynamodb';
import { success, unauthorized, notFound, serverError } from '../../shared/response';
import { getUserIdFromEvent } from '../../shared/utils';
import { ReviewCard } from '../../shared/types';

const REVIEW_CARDS_TABLE = process.env.REVIEW_CARDS_TABLE!;

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  console.log('DeleteReviewCard event:', JSON.stringify(event));

  try {
    // Get user ID from JWT
    const userId = getUserIdFromEvent(event);
    if (!userId) {
      return unauthorized('Invalid token');
    }

    // Get card ID from path parameters
    const cardId = event.pathParameters?.cardId;
    if (!cardId) {
      return notFound('Card ID is required');
    }

    // Get review card from DynamoDB to verify ownership
    const result = await docClient.send(new GetCommand({
      TableName: REVIEW_CARDS_TABLE,
      Key: { cardId },
    }));

    const card = result.Item as ReviewCard | undefined;

    if (!card) {
      return notFound('Review card not found');
    }

    // Verify ownership
    if (card.userId !== userId) {
      return notFound('Review card not found');
    }

    // Delete the review card
    await docClient.send(new DeleteCommand({
      TableName: REVIEW_CARDS_TABLE,
      Key: { cardId },
    }));

    return success({ message: 'Review card deleted successfully' });
  } catch (error) {
    console.error('Error deleting review card:', error);
    return serverError('Failed to delete review card');
  }
}
