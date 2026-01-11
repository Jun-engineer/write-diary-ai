import { APIGatewayProxyEvent } from 'aws-lambda';

/**
 * Extract user ID from Cognito JWT claims
 */
export function getUserIdFromEvent(event: APIGatewayProxyEvent): string | null {
  const claims = event.requestContext.authorizer?.claims;
  if (!claims) {
    return null;
  }
  // 'sub' is the unique user ID from Cognito
  return claims.sub || claims['cognito:username'] || null;
}

/**
 * Parse JSON body safely
 */
export function parseBody<T>(event: APIGatewayProxyEvent): T | null {
  if (!event.body) {
    return null;
  }
  try {
    return JSON.parse(event.body) as T;
  } catch {
    return null;
  }
}

/**
 * Get today's date in YYYY-MM-DD format (UTC)
 */
export function getTodayDate(): string {
  return new Date().toISOString().split('T')[0];
}

/**
 * Generate a UUID v4
 */
export function generateId(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/**
 * Get current timestamp in milliseconds
 */
export function now(): number {
  return Date.now();
}

/**
 * Calculate TTL (time to live) for DynamoDB
 * @param days Number of days from now
 */
export function getTTL(days: number): number {
  return Math.floor(Date.now() / 1000) + days * 24 * 60 * 60;
}
