import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient, GetCommand, UpdateCommand } from '../../shared/dynamodb';
import { success, forbidden, unauthorized, serverError } from '../../shared/response';
import { getUserIdFromEvent, getTodayDate, getTTL } from '../../shared/utils';
import { User, ScanUsage, PLAN_LIMITS } from '../../shared/types';

const USERS_TABLE = process.env.USERS_TABLE!;
const SCAN_USAGE_TABLE = process.env.SCAN_USAGE_TABLE!;

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Get user ID from JWT
    const userId = getUserIdFromEvent(event);
    if (!userId) {
      return unauthorized('Invalid token');
    }

    // Get user's plan
    const userResult = await docClient.send(new GetCommand({
      TableName: USERS_TABLE,
      Key: { userId },
    }));

    const user = userResult.Item as User | undefined;
    const plan = user?.plan || 'free';
    const maxBonus = PLAN_LIMITS[plan].maxScanBonusPerDay;

    // Premium users don't need bonus
    if (plan === 'premium') {
      return forbidden('Premium users have unlimited scans');
    }

    // Get today's scan usage
    const today = getTodayDate();
    const usageResult = await docClient.send(new GetCommand({
      TableName: SCAN_USAGE_TABLE,
      Key: { userId, date: today },
    }));

    const usage = usageResult.Item as ScanUsage | undefined;
    const currentBonusCount = usage?.bonusCount || 0;

    // Check if max bonus already reached
    if (currentBonusCount >= maxBonus) {
      return forbidden(JSON.stringify({
        code: 'MAX_BONUS_REACHED',
        message: 'Maximum bonus scans already granted for today',
        bonusCount: currentBonusCount,
        maxBonus,
      }));
    }

    // Grant bonus scan
    const ttl = getTTL(30); // Keep records for 30 days
    await docClient.send(new UpdateCommand({
      TableName: SCAN_USAGE_TABLE,
      Key: { userId, date: today },
      UpdateExpression: 'SET #bonusCount = if_not_exists(#bonusCount, :zero) + :one, #ttl = :ttl',
      ExpressionAttributeNames: {
        '#bonusCount': 'bonusCount',
        '#ttl': 'ttl',
      },
      ExpressionAttributeValues: {
        ':zero': 0,
        ':one': 1,
        ':ttl': ttl,
      },
    }));

    const newBonusCount = currentBonusCount + 1;

    return success({
      success: true,
      message: 'Bonus scan granted',
      bonusCount: newBonusCount,
      maxBonus,
      remainingBonus: maxBonus - newBonusCount,
    });
  } catch (error) {
    console.error('Grant bonus error:', error);
    return serverError('Failed to grant bonus scan');
  }
};
