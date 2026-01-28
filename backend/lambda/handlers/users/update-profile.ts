import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient, GetCommand, UpdateCommand } from '../../shared/dynamodb';
import { success, badRequest, unauthorized, notFound, serverError } from '../../shared/response';
import { getUserIdFromEvent, parseBody, now } from '../../shared/utils';
import { User, TargetLanguage, NativeLanguage } from '../../shared/types';

const USERS_TABLE = process.env.USERS_TABLE!;

const VALID_TARGET_LANGUAGES: TargetLanguage[] = ['english', 'spanish', 'chinese', 'japanese', 'korean', 'french', 'german', 'italian'];
const VALID_NATIVE_LANGUAGES: NativeLanguage[] = ['english', 'japanese', 'spanish', 'chinese', 'korean', 'french', 'german', 'italian'];

interface UpdateProfileRequest {
  displayName?: string;
  targetLanguage?: TargetLanguage;
  nativeLanguage?: NativeLanguage;
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
    if (!body) {
      return badRequest('Request body is required');
    }

    // Check if user exists
    const result = await docClient.send(new GetCommand({
      TableName: USERS_TABLE,
      Key: { userId },
    }));

    if (!result.Item) {
      return notFound('User not found');
    }

    // Build update expression dynamically
    const updateExpressions: string[] = ['updatedAt = :updatedAt'];
    const expressionValues: Record<string, any> = { ':updatedAt': now() };

    // Validate and add displayName if provided
    if (body.displayName !== undefined) {
      const displayName = body.displayName.trim();
      if (displayName.length < 2 || displayName.length > 50) {
        return badRequest('Display name must be between 2 and 50 characters');
      }
      updateExpressions.push('displayName = :displayName');
      expressionValues[':displayName'] = displayName;
    }

    // Validate and add targetLanguage if provided
    if (body.targetLanguage !== undefined) {
      if (!VALID_TARGET_LANGUAGES.includes(body.targetLanguage)) {
        return badRequest(`Invalid target language. Valid options: ${VALID_TARGET_LANGUAGES.join(', ')}`);
      }
      updateExpressions.push('targetLanguage = :targetLanguage');
      expressionValues[':targetLanguage'] = body.targetLanguage;
    }

    // Validate and add nativeLanguage if provided
    if (body.nativeLanguage !== undefined) {
      if (!VALID_NATIVE_LANGUAGES.includes(body.nativeLanguage)) {
        return badRequest(`Invalid native language. Valid options: ${VALID_NATIVE_LANGUAGES.join(', ')}`);
      }
      updateExpressions.push('nativeLanguage = :nativeLanguage');
      expressionValues[':nativeLanguage'] = body.nativeLanguage;
      
      // If targetLanguage is not explicitly set in DB, initialize it to avoid confusion
      // This handles the case where existing users don't have targetLanguage set
      const existingUser = result.Item as User;
      if (!existingUser.targetLanguage && body.targetLanguage === undefined) {
        updateExpressions.push('targetLanguage = :targetLanguage');
        expressionValues[':targetLanguage'] = 'english';
      }
    }

    // Update user profile
    await docClient.send(new UpdateCommand({
      TableName: USERS_TABLE,
      Key: { userId },
      UpdateExpression: `SET ${updateExpressions.join(', ')}`,
      ExpressionAttributeValues: expressionValues,
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
      targetLanguage: user.targetLanguage || 'english',
      nativeLanguage: user.nativeLanguage || 'japanese',
      createdAt: user.createdAt,
    });
  } catch (error) {
    console.error('Error updating user profile:', error);
    return serverError('Failed to update user profile');
  }
}
