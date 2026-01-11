import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient, GetCommand } from '../../shared/dynamodb';
import { success, unauthorized, serverError } from '../../shared/response';
import { getUserIdFromEvent, getTodayDate } from '../../shared/utils';
import { User, ScanUsage, GetScanUsageResponse, PLAN_LIMITS } from '../../shared/types';

const USERS_TABLE = process.env.USERS_TABLE!;
const SCAN_USAGE_TABLE = process.env.SCAN_USAGE_TABLE!;

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  console.log('GetScanUsage event:', JSON.stringify(event));

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
    const limit = PLAN_LIMITS[plan].scanPerDay;

    // Get today's scan usage
    const today = getTodayDate();
    const usageResult = await docClient.send(new GetCommand({
      TableName: SCAN_USAGE_TABLE,
      Key: { userId, date: today },
    }));

    const usage = usageResult.Item as ScanUsage | undefined;
    const count = usage?.count || 0;

    const response: GetScanUsageResponse = {
      count,
      limit,
    };

    return success(response);
  } catch (error) {
    console.error('Error getting scan usage:', error);
    return serverError('Failed to get scan usage');
  }
}
