import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient, GetCommand } from '../../shared/dynamodb';
import { success, unauthorized, notFound, serverError } from '../../shared/response';
import { getUserIdFromEvent } from '../../shared/utils';
import { Diary } from '../../shared/types';

const DIARIES_TABLE = process.env.DIARIES_TABLE!;

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  console.log('GetDiary event:', JSON.stringify(event));

  try {
    // Get user ID from JWT
    const userId = getUserIdFromEvent(event);
    if (!userId) {
      return unauthorized('Invalid token');
    }

    // Get diary ID from path parameters
    const diaryId = event.pathParameters?.diaryId;
    if (!diaryId) {
      return notFound('Diary ID is required');
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
      return notFound('Diary not found'); // Return 404 instead of 403 for security
    }

    return success(diary);
  } catch (error) {
    console.error('Error getting diary:', error);
    return serverError('Failed to get diary');
  }
}
