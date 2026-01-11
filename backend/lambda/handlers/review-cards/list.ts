import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient, QueryCommand } from '../../shared/dynamodb';
import { success, unauthorized, serverError } from '../../shared/response';
import { getUserIdFromEvent } from '../../shared/utils';
import { ReviewCard } from '../../shared/types';

const REVIEW_CARDS_TABLE = process.env.REVIEW_CARDS_TABLE!;

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  console.log('GetReviewCards event:', JSON.stringify(event));

  try {
    // Get user ID from JWT
    const userId = getUserIdFromEvent(event);
    if (!userId) {
      return unauthorized('Invalid token');
    }

    // Get query parameters
    const limit = parseInt(event.queryStringParameters?.limit || '50', 10);
    const tag = event.queryStringParameters?.tag;

    // Query review cards by userId
    const queryParams: any = {
      TableName: REVIEW_CARDS_TABLE,
      IndexName: 'userId-index',
      KeyConditionExpression: 'userId = :userId',
      ExpressionAttributeValues: {
        ':userId': userId,
      },
      Limit: limit,
      ScanIndexForward: false, // Newest first
    };

    // Add tag filter if provided
    if (tag) {
      queryParams.FilterExpression = 'contains(tags, :tag)';
      queryParams.ExpressionAttributeValues[':tag'] = tag;
    }

    const result = await docClient.send(new QueryCommand(queryParams));

    const cards = result.Items as ReviewCard[] || [];

    return success({
      cards,
      count: cards.length,
    });
  } catch (error) {
    console.error('Error getting review cards:', error);
    return serverError('Failed to get review cards');
  }
}
