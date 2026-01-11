import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient, QueryCommand } from '../../shared/dynamodb';
import { success, unauthorized, serverError, badRequest } from '../../shared/response';
import { getUserIdFromEvent } from '../../shared/utils';
import { Diary } from '../../shared/types';

const DIARIES_TABLE = process.env.DIARIES_TABLE!;

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  console.log('GetDiaries event:', JSON.stringify(event));

  try {
    // Get user ID from JWT
    const userId = getUserIdFromEvent(event);
    if (!userId) {
      return unauthorized('Invalid token');
    }

    // Get query parameters
    const startDate = event.queryStringParameters?.startDate;
    const endDate = event.queryStringParameters?.endDate;
    const limit = parseInt(event.queryStringParameters?.limit || '50', 10);

    // Build query
    let keyConditionExpression = 'userId = :userId';
    const expressionAttributeValues: Record<string, any> = {
      ':userId': userId,
    };

    // Add date range filter if provided
    if (startDate && endDate) {
      keyConditionExpression += ' AND #date BETWEEN :startDate AND :endDate';
      expressionAttributeValues[':startDate'] = startDate;
      expressionAttributeValues[':endDate'] = endDate;
    } else if (startDate) {
      keyConditionExpression += ' AND #date >= :startDate';
      expressionAttributeValues[':startDate'] = startDate;
    } else if (endDate) {
      keyConditionExpression += ' AND #date <= :endDate';
      expressionAttributeValues[':endDate'] = endDate;
    }

    const result = await docClient.send(new QueryCommand({
      TableName: DIARIES_TABLE,
      IndexName: 'userId-date-index',
      KeyConditionExpression: keyConditionExpression,
      ExpressionAttributeNames: startDate || endDate ? { '#date': 'date' } : undefined,
      ExpressionAttributeValues: expressionAttributeValues,
      Limit: limit,
      ScanIndexForward: false, // Sort by date descending (newest first)
    }));

    const diaries = result.Items as Diary[] || [];

    return success({
      diaries,
      count: diaries.length,
    });
  } catch (error) {
    console.error('Error getting diaries:', error);
    return serverError('Failed to get diaries');
  }
}
