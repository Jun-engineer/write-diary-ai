import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import { getUserIdFromEvent, parseBody } from '../../shared/utils';
import { success, badRequest, unauthorized, serverError } from '../../shared/response';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const USERS_TABLE = process.env.USERS_TABLE!;

interface SyncSubscriptionRequest {
  isPremium: boolean;
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const userId = getUserIdFromEvent(event);
    if (!userId) {
      return unauthorized();
    }

    const body = parseBody<SyncSubscriptionRequest>(event);
    if (!body || typeof body.isPremium !== 'boolean') {
      return badRequest('Missing required field: isPremium');
    }

    const newPlan = body.isPremium ? 'premium' : 'free';

    await docClient.send(new UpdateCommand({
      TableName: USERS_TABLE,
      Key: { userId },
      UpdateExpression: 'SET #plan = :plan, updatedAt = :updatedAt',
      ExpressionAttributeNames: {
        '#plan': 'plan',
      },
      ExpressionAttributeValues: {
        ':plan': newPlan,
        ':updatedAt': Date.now(),
      },
    }));

    return success({ plan: newPlan });
  } catch (error) {
    console.error('Sync subscription error:', error);
    return serverError('Failed to sync subscription');
  }
};
