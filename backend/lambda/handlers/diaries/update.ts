import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient, GetCommand, UpdateCommand } from '../../shared/dynamodb';
import { success, badRequest, unauthorized, notFound, serverError } from '../../shared/response';
import { getUserIdFromEvent, parseBody, now } from '../../shared/utils';
import { Diary } from '../../shared/types';

const DIARIES_TABLE = process.env.DIARIES_TABLE!;

interface UpdateDiaryRequest {
  originalText: string;
}

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  console.log('UpdateDiary event:', JSON.stringify(event));

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
    const body = parseBody<UpdateDiaryRequest>(event);
    if (!body || !body.originalText) {
      return badRequest('originalText is required');
    }

    // Get diary from DynamoDB to verify ownership
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

    // Update diary - clear corrections if text changed
    const updateExpression = diary.originalText !== body.originalText
      ? 'SET originalText = :originalText, correctedText = :null, corrections = :empty, updatedAt = :updatedAt'
      : 'SET originalText = :originalText, updatedAt = :updatedAt';

    const expressionAttributeValues: Record<string, any> = {
      ':originalText': body.originalText.trim(),
      ':updatedAt': now(),
    };

    if (diary.originalText !== body.originalText) {
      expressionAttributeValues[':null'] = null;
      expressionAttributeValues[':empty'] = [];
    }

    await docClient.send(new UpdateCommand({
      TableName: DIARIES_TABLE,
      Key: { diaryId },
      UpdateExpression: updateExpression,
      ExpressionAttributeValues: expressionAttributeValues,
    }));

    // Return updated diary
    const updatedResult = await docClient.send(new GetCommand({
      TableName: DIARIES_TABLE,
      Key: { diaryId },
    }));

    return success(updatedResult.Item);
  } catch (error) {
    console.error('Error updating diary:', error);
    return serverError('Failed to update diary');
  }
}
