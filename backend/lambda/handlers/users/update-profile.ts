import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient, GetCommand, UpdateCommand } from '../../shared/dynamodb';
import { success, badRequest, unauthorized, notFound, serverError } from '../../shared/response';
import { getUserIdFromEvent, parseBody, now } from '../../shared/utils';
import { User } from '../../shared/types';

const USERS_TABLE = process.env.USERS_TABLE!;

interface UpdateProfileRequest {
  displayName: string;
}

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  console.log('UpdateUserProfile event:', JSON.stringify(event));

  try {
    // Get user ID from JWT
    const userId = getUserIdFromEvent(event);
    if (!userId) {
      return unauthorized('Invalid token');
    }

    // Parse request body
    const body = parseBody<UpdateProfileRequest>(event);
    if (!body || !body.displayName) {
      return badRequest('displayName is required');
    }

    // Validate display name
    const displayName = body.displayName.trim();
    if (displayName.length < 2 || displayName.length > 50) {
      return badRequest('Display name must be between 2 and 50 characters');
    }

    // Check if user exists
    const result = await docClient.send(new GetCommand({
      TableName: USERS_TABLE,
      Key: { userId },
    }));

    if (!result.Item) {
      return notFound('User not found');
    }

    // Update user profile
    await docClient.send(new UpdateCommand({
      TableName: USERS_TABLE,
      Key: { userId },
      UpdateExpression: 'SET displayName = :displayName, updatedAt = :updatedAt',
      ExpressionAttributeValues: {
        ':displayName': displayName,
        ':updatedAt': now(),
      },
    }));

    // Get updated user
    const updatedResult = await docClient.send(new GetCommand({
      TableName: USERS_TABLE,
      Key: { userId },
    }));

    const user = updatedResult.Item as User;

    return success({
      userId: user.userId,
      email: user.email,
      displayName: user.displayName,
      plan: user.plan,
      createdAt: user.createdAt,
    });
  } catch (error) {
    console.error('Error updating user profile:', error);
    return serverError('Failed to update user profile');
  }
}
