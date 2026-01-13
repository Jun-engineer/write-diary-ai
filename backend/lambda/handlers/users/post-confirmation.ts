import { PostConfirmationTriggerEvent, PostConfirmationTriggerHandler } from 'aws-lambda';
import { docClient, PutCommand } from '../../shared/dynamodb';
import { now } from '../../shared/utils';
import { User } from '../../shared/types';

const USERS_TABLE = process.env.USERS_TABLE!;

/**
 * Cognito Post-Confirmation trigger
 * Creates a new user record in DynamoDB after successful signup
 */
export const handler: PostConfirmationTriggerHandler = async (event: PostConfirmationTriggerEvent) => {
  console.log('PostConfirmation event:', JSON.stringify(event));

  try {
    // Only process signups, not forgot password confirmations
    if (event.triggerSource !== 'PostConfirmation_ConfirmSignUp') {
      return event;
    }

    const userId = event.request.userAttributes.sub;
    const email = event.request.userAttributes.email;
    // Get display name from Cognito 'name' attribute, or use email prefix as fallback
    const displayName = event.request.userAttributes.name || email.split('@')[0];

    // Create user record
    const user: User = {
      userId,
      email,
      displayName,
      plan: 'free', // All new users start on free plan
      createdAt: now(),
    };

    await docClient.send(new PutCommand({
      TableName: USERS_TABLE,
      Item: user,
      ConditionExpression: 'attribute_not_exists(userId)', // Don't overwrite existing users
    }));

    console.log(`Created user record for ${userId} with displayName: ${displayName}`);
  } catch (error: any) {
    // If user already exists, that's fine
    if (error.name === 'ConditionalCheckFailedException') {
      console.log('User already exists, skipping creation');
    } else {
      console.error('Error creating user:', error);
      // Don't throw - we don't want to block the signup
    }
  }

  return event;
};
