import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { docClient, GetCommand } from '../../shared/dynamodb';
import { success, badRequest, forbiddenWithData, unauthorized, serverError } from '../../shared/response';
import { getUserIdFromEvent, getTodayDate } from '../../shared/utils';
import { User, ScanUsage, PLAN_LIMITS } from '../../shared/types';

// Use us-east-1 where Nova models are available
const bedrockClient = new BedrockRuntimeClient({ region: 'us-east-1' });

const USERS_TABLE = process.env.USERS_TABLE!;
const SCAN_USAGE_TABLE = process.env.SCAN_USAGE_TABLE!;

interface ScanRequest {
  imageBase64: string; // Base64 encoded image
  mediaType?: string;  // image/jpeg, image/png, etc.
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Get user ID from JWT
    const userId = getUserIdFromEvent(event);
    if (!userId) {
      return unauthorized('Invalid token');
    }

    // Check scan limit before processing
    const scanCheck = await checkScanLimit(userId);
    if (!scanCheck.canScan) {
      // Return detailed error with scan status for the client
      return forbiddenWithData({
        code: 'SCAN_LIMIT_REACHED',
        message: 'Daily scan limit reached',
        currentCount: scanCheck.currentCount,
        limit: scanCheck.limit,
        bonusCount: scanCheck.bonusCount,
        maxBonus: scanCheck.maxBonus,
        canWatchAd: scanCheck.bonusCount < scanCheck.maxBonus,
      });
    }

    if (!event.body) {
      return badRequest('Request body is required');
    }

    const request: ScanRequest = JSON.parse(event.body);
    
    if (!request.imageBase64) {
      return badRequest('imageBase64 is required');
    }

    // Remove data URL prefix if present (e.g., "data:image/jpeg;base64,")
    let imageData = request.imageBase64;
    if (imageData.includes(',')) {
      imageData = imageData.split(',')[1];
    }

    // Detect media type
    const mediaType = request.mediaType || detectMediaType(imageData);

    // Call Claude Vision via Bedrock
    const extractedText = await recognizeHandwriting(imageData, mediaType);

    return success({
      text: extractedText,
      success: true,
    });
  } catch (error) {
    console.error('Scan error:', error);
    return serverError('Failed to process image');
  }
};

interface ScanCheckResult {
  canScan: boolean;
  currentCount: number;
  limit: number;
  bonusCount: number;
  maxBonus: number;
}

async function checkScanLimit(userId: string): Promise<ScanCheckResult> {
  // Get user's plan
  const userResult = await docClient.send(new GetCommand({
    TableName: USERS_TABLE,
    Key: { userId },
  }));

  const user = userResult.Item as User | undefined;
  const plan = user?.plan || 'free';
  const baseLimit = PLAN_LIMITS[plan].scanPerDay;
  const maxBonus = PLAN_LIMITS[plan].maxScanBonusPerDay;

  // Get today's scan usage
  const today = getTodayDate();
  const usageResult = await docClient.send(new GetCommand({
    TableName: SCAN_USAGE_TABLE,
    Key: { userId, date: today },
  }));

  const usage = usageResult.Item as ScanUsage | undefined;
  const currentCount = usage?.count || 0;
  const bonusCount = usage?.bonusCount || 0;
  
  // Total limit = base limit + bonus from ads
  const totalLimit = baseLimit + bonusCount;

  return {
    canScan: currentCount < totalLimit,
    currentCount,
    limit: baseLimit,
    bonusCount,
    maxBonus,
  };
}

function detectMediaType(base64Data: string): string {
  // Check magic bytes in base64
  if (base64Data.startsWith('/9j/')) {
    return 'image/jpeg';
  } else if (base64Data.startsWith('iVBORw')) {
    return 'image/png';
  } else if (base64Data.startsWith('R0lGOD')) {
    return 'image/gif';
  } else if (base64Data.startsWith('UklGR')) {
    return 'image/webp';
  }
  return 'image/jpeg'; // Default to JPEG
}

async function recognizeHandwriting(imageBase64: string, mediaType: string): Promise<string> {
  const prompt = `You are an expert at reading handwritten text. Please carefully read and transcribe all the handwritten text in this image.

Instructions:
- Transcribe the text exactly as written, preserving line breaks and paragraphs
- If you're unsure about a word, make your best guess based on context
- Do not add any commentary, explanations, or corrections
- If there are spelling or grammar mistakes in the handwriting, keep them as-is
- If no text is visible or readable, respond with: [No readable text found]
- Only output the transcribed text, nothing else

Transcribe the handwritten text:`;

  // Use Amazon Nova Lite for vision (available without approval)
  const requestBody = {
    schemaVersion: 'messages-v1',
    messages: [
      {
        role: 'user',
        content: [
          {
            image: {
              format: mediaType.split('/')[1] || 'jpeg',
              source: {
                bytes: imageBase64,
              },
            },
          },
          {
            text: prompt,
          },
        ],
      },
    ],
    inferenceConfig: {
      maxTokens: 4096,
    },
  };

  const command = new InvokeModelCommand({
    modelId: 'amazon.nova-lite-v1:0',
    contentType: 'application/json',
    accept: 'application/json',
    body: JSON.stringify(requestBody),
  });

  const response = await bedrockClient.send(command);
  const responseBody = JSON.parse(new TextDecoder().decode(response.body));

  if (responseBody.output?.message?.content && responseBody.output.message.content.length > 0) {
    const text = responseBody.output.message.content[0].text.trim();
    
    // Check if no text was found
    if (text === '[No readable text found]') {
      return '';
    }
    
    return text;
  }

  return '';
}
