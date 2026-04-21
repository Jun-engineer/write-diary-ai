import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand } from '@aws-sdk/lib-dynamodb';

const dynamoClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(dynamoClient);
const USERS_TABLE = process.env.USERS_TABLE!;
const WEBHOOK_SECRET = process.env.REVENUECAT_WEBHOOK_SECRET!;

// RevenueCat webhook event types that affect subscription status
type RevenueCatEventType =
  | 'INITIAL_PURCHASE'
  | 'RENEWAL'
  | 'PRODUCT_CHANGE'
  | 'CANCELLATION'
  | 'BILLING_ISSUE'
  | 'EXPIRATION'
  | 'REFUND'
  | 'UNCANCELLATION'
  | 'SUBSCRIBER_ALIAS';

interface RevenueCatEvent {
  type: RevenueCatEventType;
  app_user_id: string;
  original_app_user_id: string;
  product_id?: string;
  expiration_at_ms?: number;
  cancel_reason?: string;
  grace_period_expiration_at_ms?: number;
}

interface RevenueCatWebhookPayload {
  api_version: string;
  event: RevenueCatEvent;
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  // Verify RevenueCat webhook secret
  const authHeader = event.headers['Authorization'] || event.headers['authorization'] || '';
  if (WEBHOOK_SECRET && authHeader !== WEBHOOK_SECRET) {
    console.warn('Webhook auth failed — invalid secret');
    return { statusCode: 401, body: JSON.stringify({ message: 'Unauthorized' }) };
  }

  if (!event.body) {
    return { statusCode: 400, body: JSON.stringify({ message: 'Missing body' }) };
  }

  let payload: RevenueCatWebhookPayload;
  try {
    payload = JSON.parse(event.body);
  } catch {
    return { statusCode: 400, body: JSON.stringify({ message: 'Invalid JSON' }) };
  }

  const rc = payload.event;
  if (!rc || !rc.app_user_id) {
    return { statusCode: 400, body: JSON.stringify({ message: 'Missing event data' }) };
  }

  const userId = rc.original_app_user_id || rc.app_user_id;
  const now = Date.now();

  console.log(`RevenueCat webhook: type=${rc.type} userId=${userId}`);

  try {
    switch (rc.type) {
      case 'INITIAL_PURCHASE':
      case 'RENEWAL':
      case 'UNCANCELLATION':
        await updateUserSubscription(userId, {
          plan: 'premium',
          subscriptionStatus: 'active',
          subscriptionProductId: rc.product_id,
          subscriptionExpiresAt: rc.expiration_at_ms,
          updatedAt: now,
        });
        break;

      case 'PRODUCT_CHANGE':
        await updateUserSubscription(userId, {
          plan: 'premium',
          subscriptionStatus: 'active',
          subscriptionProductId: rc.product_id,
          subscriptionExpiresAt: rc.expiration_at_ms,
          updatedAt: now,
        });
        break;

      case 'CANCELLATION':
        // User cancelled — still active until expiry
        await updateUserSubscription(userId, {
          plan: 'premium',
          subscriptionStatus: 'canceled',
          subscriptionProductId: rc.product_id,
          subscriptionExpiresAt: rc.expiration_at_ms,
          updatedAt: now,
        });
        break;

      case 'BILLING_ISSUE':
        // Billing failed — may enter grace period
        await updateUserSubscription(userId, {
          plan: 'premium',
          subscriptionStatus: rc.grace_period_expiration_at_ms ? 'grace_period' : 'billing_issue',
          subscriptionProductId: rc.product_id,
          subscriptionExpiresAt: rc.grace_period_expiration_at_ms ?? rc.expiration_at_ms,
          updatedAt: now,
        });
        break;

      case 'EXPIRATION':
      case 'REFUND':
        await updateUserSubscription(userId, {
          plan: 'free',
          subscriptionStatus: 'expired',
          subscriptionProductId: rc.product_id,
          subscriptionExpiresAt: rc.expiration_at_ms,
          updatedAt: now,
        });
        break;

      default:
        console.log(`Unhandled RevenueCat event type: ${rc.type}`);
    }
  } catch (err) {
    console.error('Failed to update user subscription:', err);
    return { statusCode: 500, body: JSON.stringify({ message: 'Internal server error' }) };
  }

  return { statusCode: 200, body: JSON.stringify({ received: true }) };
};

async function updateUserSubscription(
  userId: string,
  fields: {
    plan: 'free' | 'premium';
    subscriptionStatus: string;
    subscriptionProductId?: string;
    subscriptionExpiresAt?: number;
    updatedAt: number;
  },
) {
  const updateExpressionParts = [
    '#plan = :plan',
    '#subscriptionStatus = :subscriptionStatus',
    '#updatedAt = :updatedAt',
  ];
  const expressionAttributeNames: Record<string, string> = {
    '#plan': 'plan',
    '#subscriptionStatus': 'subscriptionStatus',
    '#updatedAt': 'updatedAt',
  };
  const expressionAttributeValues: Record<string, unknown> = {
    ':plan': fields.plan,
    ':subscriptionStatus': fields.subscriptionStatus,
    ':updatedAt': fields.updatedAt,
  };

  if (fields.subscriptionProductId !== undefined) {
    updateExpressionParts.push('#subscriptionProductId = :subscriptionProductId');
    expressionAttributeNames['#subscriptionProductId'] = 'subscriptionProductId';
    expressionAttributeValues[':subscriptionProductId'] = fields.subscriptionProductId;
  }

  if (fields.subscriptionExpiresAt !== undefined) {
    updateExpressionParts.push('#subscriptionExpiresAt = :subscriptionExpiresAt');
    expressionAttributeNames['#subscriptionExpiresAt'] = 'subscriptionExpiresAt';
    expressionAttributeValues[':subscriptionExpiresAt'] = fields.subscriptionExpiresAt;
  }

  await docClient.send(
    new UpdateCommand({
      TableName: USERS_TABLE,
      Key: { userId },
      UpdateExpression: `SET ${updateExpressionParts.join(', ')}`,
      ExpressionAttributeNames: expressionAttributeNames,
      ExpressionAttributeValues: expressionAttributeValues,
    }),
  );
}
