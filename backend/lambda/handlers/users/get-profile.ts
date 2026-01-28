import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient, GetCommand } from '../../shared/dynamodb';
import { success, unauthorized, notFound, serverError } from '../../shared/response';
import { getUserIdFromEvent } from '../../shared/utils';
import { User } from '../../shared/types';

const USERS_TABLE = process.env.USERS_TABLE!;

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  console.log('GetUserProfile event:', JSON.stringify(event));

  try {
    // Get user ID from JWT
    const userId = getUserIdFromEvent(event);
    if (!userId) {
      return unauthorized('Invalid token');
    }

    // Get user from DynamoDB
    const result = await docClient.send(new GetCommand({
      TableName: USERS_TABLE,
      Key: { userId },
    }));

    const user = result.Item as User | undefined;

    if (!user) {
      return notFound('User not found');
    }

    // Return user profile (exclude sensitive fields if any)
    return success({
      userId: user.userId,
      email: user.email,
      displayName: user.displayName || user.email.split('@')[0],
      plan: user.plan,
      targetLanguage: user.targetLanguage || 'english',
      nativeLanguage: user.nativeLanguage || 'japanese',
      createdAt: user.createdAt,
    });
  } catch (error) {
    console.error('Error getting user profile:', error);
    return serverError('Failed to get user profile');
  }
}
