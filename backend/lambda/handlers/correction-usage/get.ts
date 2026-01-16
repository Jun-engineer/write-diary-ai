import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient, GetCommand } from '../../shared/dynamodb';
import { success, unauthorized, serverError } from '../../shared/response';
import { getUserIdFromEvent, getTodayDate } from '../../shared/utils';
import { User, CorrectionUsage, PLAN_LIMITS } from '../../shared/types';

const USERS_TABLE = process.env.USERS_TABLE!;
const CORRECTION_USAGE_TABLE = process.env.CORRECTION_USAGE_TABLE!;

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  console.log('GetCorrectionUsage event:', JSON.stringify(event));

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
    const baseLimit = PLAN_LIMITS[plan].correctionPerDay;
    const maxBonus = PLAN_LIMITS[plan].maxCorrectionBonusPerDay;

    // Get today's correction usage
    const today = getTodayDate();
    const usageResult = await docClient.send(new GetCommand({
      TableName: CORRECTION_USAGE_TABLE,
      Key: { userId, date: today },
    }));

    const usage = usageResult.Item as CorrectionUsage | undefined;
    const count = usage?.count || 0;
    const bonusCount = usage?.bonusCount || 0;

    return success({
      count,
      limit: baseLimit,
      bonusCount,
      maxBonus,
    });
  } catch (error) {
    console.error('Error getting correction usage:', error);
    return serverError('Failed to get correction usage');
  }
}
