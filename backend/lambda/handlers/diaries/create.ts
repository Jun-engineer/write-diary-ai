import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { docClient, PutCommand, GetCommand, UpdateCommand } from '../../shared/dynamodb';
import { success, created, badRequest, unauthorized, forbidden, serverError } from '../../shared/response';
import { getUserIdFromEvent, parseBody, getTodayDate, generateId, now, getTTL } from '../../shared/utils';
import { CreateDiaryRequest, CreateDiaryResponse, Diary, User, ScanUsage, PLAN_LIMITS } from '../../shared/types';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

const s3Client = new S3Client({});

const USERS_TABLE = process.env.USERS_TABLE!;
const DIARIES_TABLE = process.env.DIARIES_TABLE!;
const SCAN_USAGE_TABLE = process.env.SCAN_USAGE_TABLE!;
const IMAGES_BUCKET = process.env.IMAGES_BUCKET!;

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  console.log('CreateDiary event:', JSON.stringify(event));

  try {
    // Get user ID from JWT
    const userId = getUserIdFromEvent(event);
    if (!userId) {
      return unauthorized('Invalid token');
    }

    // Parse request body
    const body = parseBody<CreateDiaryRequest>(event);
    if (!body) {
      return badRequest('Invalid request body');
    }

    const { date, originalText, inputType, imageBase64 } = body;

    // Validate required fields
    if (!date || !originalText || !inputType) {
      return badRequest('Missing required fields: date, originalText, inputType');
    }

    // Validate date format
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      return badRequest('Invalid date format. Use YYYY-MM-DD');
    }

    // Validate inputType
    if (inputType !== 'manual' && inputType !== 'scan') {
      return badRequest('inputType must be "manual" or "scan"');
    }

    // If scan input, check daily limit
    if (inputType === 'scan') {
      const canScan = await checkScanLimit(userId);
      if (!canScan) {
        return forbidden('Daily scan limit reached. Upgrade to Premium for unlimited scans.');
      }
    }

    // Generate diary ID
    const diaryId = generateId();
    let imageKey: string | undefined;

    // Upload image to S3 if provided
    if (imageBase64 && inputType === 'scan') {
      imageKey = `scans/${userId}/${diaryId}.jpg`;
      const imageBuffer = Buffer.from(imageBase64, 'base64');
      
      await s3Client.send(new PutObjectCommand({
        Bucket: IMAGES_BUCKET,
        Key: imageKey,
        Body: imageBuffer,
        ContentType: 'image/jpeg',
      }));
    }

    // Create diary entry
    const diary: Diary = {
      diaryId,
      userId,
      date,
      originalText,
      inputType,
      imageKey,
      createdAt: now(),
    };

    await docClient.send(new PutCommand({
      TableName: DIARIES_TABLE,
      Item: diary,
    }));

    // Increment scan usage if scan input
    if (inputType === 'scan') {
      await incrementScanUsage(userId);
    }

    const response: CreateDiaryResponse = {
      diaryId,
      status: 'saved',
    };

    return created(response);
  } catch (error) {
    console.error('Error creating diary:', error);
    return serverError('Failed to create diary');
  }
}

async function checkScanLimit(userId: string): Promise<boolean> {
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
  const currentCount = usage?.count || 0;

  return currentCount < limit;
}

async function incrementScanUsage(userId: string): Promise<void> {
  const today = getTodayDate();
  const ttl = getTTL(30); // Keep records for 30 days

  await docClient.send(new UpdateCommand({
    TableName: SCAN_USAGE_TABLE,
    Key: { userId, date: today },
    UpdateExpression: 'SET #count = if_not_exists(#count, :zero) + :one, #ttl = :ttl',
    ExpressionAttributeNames: {
      '#count': 'count',
      '#ttl': 'ttl',
    },
    ExpressionAttributeValues: {
      ':zero': 0,
      ':one': 1,
      ':ttl': ttl,
    },
  }));
}
