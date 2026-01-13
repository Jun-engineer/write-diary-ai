import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient, DeleteCommand, QueryCommand } from '../../shared/dynamodb';
import { success, unauthorized, serverError } from '../../shared/response';
import { getUserIdFromEvent } from '../../shared/utils';

const USERS_TABLE = process.env.USERS_TABLE!;
const DIARIES_TABLE = process.env.DIARIES_TABLE!;
const REVIEW_CARDS_TABLE = process.env.REVIEW_CARDS_TABLE!;
const SCAN_USAGE_TABLE = process.env.SCAN_USAGE_TABLE!;

/**
 * DELETE /users/me
 * Deletes the current user and all their data
 */
export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const userId = getUserIdFromEvent(event);
    if (!userId) {
      return unauthorized('Invalid token');
    }

    console.log(`Deleting user ${userId} and all associated data`);

    // Delete all user's diaries
    await deleteUserDiaries(userId);

    // Delete all user's review cards
    await deleteUserReviewCards(userId);

    // Delete scan usage records
    await deleteUserScanUsage(userId);

    // Delete the user record itself
    await docClient.send(new DeleteCommand({
      TableName: USERS_TABLE,
      Key: { userId },
    }));

    console.log(`Successfully deleted user ${userId}`);

    return success({ message: 'Account deleted successfully' });
  } catch (error) {
    console.error('Error deleting user:', error);
    return serverError('Failed to delete account');
  }
};

async function deleteUserDiaries(userId: string): Promise<void> {
  // Query all diaries for this user using the GSI
  const result = await docClient.send(new QueryCommand({
    TableName: DIARIES_TABLE,
    IndexName: 'userId-date-index',
    KeyConditionExpression: 'userId = :userId',
    ExpressionAttributeValues: {
      ':userId': userId,
    },
  }));

  const items = result.Items || [];
  console.log(`Deleting ${items.length} diaries for user ${userId}`);

  // Delete each diary using the diaryId (primary key)
  for (const item of items) {
    await docClient.send(new DeleteCommand({
      TableName: DIARIES_TABLE,
      Key: {
        diaryId: item.diaryId,
      },
    }));
  }
}

async function deleteUserReviewCards(userId: string): Promise<void> {
  // Query all review cards for this user using the GSI
  const result = await docClient.send(new QueryCommand({
    TableName: REVIEW_CARDS_TABLE,
    IndexName: 'userId-index',
    KeyConditionExpression: 'userId = :userId',
    ExpressionAttributeValues: {
      ':userId': userId,
    },
  }));

  const items = result.Items || [];
  console.log(`Deleting ${items.length} review cards for user ${userId}`);

  // Delete each review card using the cardId (primary key)
  for (const item of items) {
    await docClient.send(new DeleteCommand({
      TableName: REVIEW_CARDS_TABLE,
      Key: {
        cardId: item.cardId,
      },
    }));
  }
}

async function deleteUserScanUsage(userId: string): Promise<void> {
  // Query all scan usage records for this user
  const result = await docClient.send(new QueryCommand({
    TableName: SCAN_USAGE_TABLE,
    KeyConditionExpression: 'userId = :userId',
    ExpressionAttributeValues: {
      ':userId': userId,
    },
  }));

  const items = result.Items || [];
  console.log(`Deleting ${items.length} scan usage records for user ${userId}`);

  // Delete each scan usage record
  for (const item of items) {
    await docClient.send(new DeleteCommand({
      TableName: SCAN_USAGE_TABLE,
      Key: {
        userId,
        date: item.date,
      },
    }));
  }
}
