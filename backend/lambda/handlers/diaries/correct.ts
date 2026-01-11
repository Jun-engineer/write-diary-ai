import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { docClient, GetCommand, UpdateCommand } from '../../shared/dynamodb';
import { success, badRequest, unauthorized, notFound, serverError } from '../../shared/response';
import { getUserIdFromEvent, parseBody, now } from '../../shared/utils';
import { 
  Diary, 
  CorrectDiaryRequest, 
  CorrectDiaryResponse, 
  Correction, 
  CorrectionMode 
} from '../../shared/types';

const DIARIES_TABLE = process.env.DIARIES_TABLE!;

// Initialize Bedrock client
const bedrockClient = new BedrockRuntimeClient({ region: process.env.AWS_REGION || 'us-east-1' });

// Claude 3.5 Haiku model ID
const CLAUDE_MODEL_ID = 'anthropic.claude-3-5-haiku-20241022-v1:0';

// AI correction prompts by mode
const CORRECTION_PROMPTS: Record<CorrectionMode, string> = {
  beginner: `You are a friendly English teacher helping a beginner student correct their diary entry.
Focus ONLY on:
- Basic grammar errors (verb tenses, subject-verb agreement)
- Spelling mistakes
- Missing articles (a, an, the)

Keep explanations simple and encouraging. Use easy vocabulary in your explanations.`,
  
  intermediate: `You are an English teacher helping an intermediate student improve their diary entry.
Focus on:
- All grammar and spelling errors
- Awkward phrasing that should sound more natural
- Word choice improvements
- Preposition usage

Provide clear explanations that help the student understand why the correction is needed.`,
  
  advanced: `You are an English teacher helping an advanced student polish their diary entry.
Provide comprehensive corrections including:
- Grammar and spelling (including subtle errors)
- Natural expressions and idioms to replace awkward phrasing
- Style improvements for more sophisticated writing
- Nuanced vocabulary suggestions
- Detailed explanations of why native speakers prefer certain expressions`,
};

export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  console.log('CorrectDiary event:', JSON.stringify(event));

  try {
    // Get user ID from JWT
    const userId = getUserIdFromEvent(event);
    if (!userId) {
      return unauthorized('Invalid token');
    }

    // Get diary ID from path parameters
    const diaryId = event.pathParameters?.diaryId;
    if (!diaryId) {
      return badRequest('Diary ID is required');
    }

    // Parse request body
    const body = parseBody<CorrectDiaryRequest>(event);
    if (!body) {
      return badRequest('Invalid request body');
    }

    const { mode } = body;

    // Validate mode
    if (!mode || !['beginner', 'intermediate', 'advanced'].includes(mode)) {
      return badRequest('Invalid mode. Use: beginner, intermediate, or advanced');
    }

    // Get diary from DynamoDB
    const result = await docClient.send(new GetCommand({
      TableName: DIARIES_TABLE,
      Key: { diaryId },
    }));

    const diary = result.Item as Diary | undefined;

    if (!diary) {
      return notFound('Diary not found');
    }

    // Verify ownership
    if (diary.userId !== userId) {
      return notFound('Diary not found');
    }

    // Call AI for correction
    const { correctedText, corrections } = await correctWithClaude(diary.originalText, mode);

    // Update diary with corrections
    await docClient.send(new UpdateCommand({
      TableName: DIARIES_TABLE,
      Key: { diaryId },
      UpdateExpression: 'SET correctedText = :correctedText, corrections = :corrections, updatedAt = :updatedAt',
      ExpressionAttributeValues: {
        ':correctedText': correctedText,
        ':corrections': corrections,
        ':updatedAt': now(),
      },
    }));

    const response: CorrectDiaryResponse = {
      correctedText,
      corrections,
    };

    return success(response);
  } catch (error) {
    console.error('Error correcting diary:', error);
    return serverError('Failed to correct diary');
  }
}

/**
 * Call Claude 3.5 Haiku via AWS Bedrock for text correction
 */
async function correctWithClaude(
  originalText: string, 
  mode: CorrectionMode
): Promise<{ correctedText: string; corrections: Correction[] }> {
  const systemPrompt = CORRECTION_PROMPTS[mode];
  
  const userPrompt = `Please correct the following English diary entry and provide a list of all corrections made.

IMPORTANT: You must respond with ONLY valid JSON in this exact format, no other text:
{
  "correctedText": "The full corrected diary text here",
  "corrections": [
    {
      "type": "grammar|spelling|style|vocabulary",
      "before": "the original incorrect phrase",
      "after": "the corrected phrase",
      "explanation": "Brief explanation of why this correction was made"
    }
  ]
}

If no corrections are needed, return:
{
  "correctedText": "The original text unchanged",
  "corrections": []
}

Diary entry to correct:
"""
${originalText}
"""`;

  try {
    const response = await bedrockClient.send(new InvokeModelCommand({
      modelId: CLAUDE_MODEL_ID,
      contentType: 'application/json',
      accept: 'application/json',
      body: JSON.stringify({
        anthropic_version: 'bedrock-2023-05-31',
        max_tokens: 4096,
        system: systemPrompt,
        messages: [
          {
            role: 'user',
            content: userPrompt,
          },
        ],
      }),
    }));

    // Parse the response
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));
    const aiContent = responseBody.content[0].text;
    
    console.log('Claude response:', aiContent);

    // Parse the JSON response from Claude
    const parsed = JSON.parse(aiContent);
    
    // Validate and return the corrections
    return {
      correctedText: parsed.correctedText || originalText,
      corrections: (parsed.corrections || []).map((c: any) => ({
        type: c.type || 'grammar',
        before: c.before || '',
        after: c.after || '',
        explanation: c.explanation || '',
      })),
    };
  } catch (error) {
    console.error('Error calling Claude:', error);
    
    // If AI fails, return original text with no corrections
    // This allows the app to gracefully degrade
    return {
      correctedText: originalText,
      corrections: [],
    };
  }
}
