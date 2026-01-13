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

// Initialize Bedrock client - use us-east-1 where models are available
const bedrockClient = new BedrockRuntimeClient({ region: 'us-east-1' });

// Amazon Nova Lite model ID (available without approval)
const MODEL_ID = 'amazon.nova-lite-v1:0';

// AI correction prompts by mode (explanations in Japanese for Japanese users)
const CORRECTION_PROMPTS: Record<CorrectionMode, string> = {
  beginner: `あなたは初心者の生徒の英語日記を添削する親切な英語教師です。
以下の点のみに注目してください：
- 基本的な文法エラー（動詞の時制、主語と動詞の一致）
- スペルミス
- 冠詞の欠落（a, an, the）

説明は日本語で、シンプルで励ましになるようにしてください。`,
  
  intermediate: `あなたは中級者の生徒の英語日記を改善する英語教師です。
以下の点に注目してください：
- すべての文法・スペルエラー
- より自然に聞こえるべき不自然な表現
- 語彙の改善提案
- 前置詞の使い方

説明は日本語で、なぜその修正が必要かを明確に説明してください。`,
  
  advanced: `あなたは上級者の生徒の英語日記を洗練させる英語教師です。
以下を含む包括的な添削を行ってください：
- 文法・スペル（微妙なエラーも含む）
- 不自然な表現を自然な表現やイディオムに置き換え
- より洗練された文章にするためのスタイル改善
- より適切な語彙の提案
- ネイティブスピーカーが特定の表現を好む理由の詳細な説明

説明は日本語で行ってください。`,
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
 * Call Amazon Nova via AWS Bedrock for text correction
 */
async function correctWithClaude(
  originalText: string, 
  mode: CorrectionMode
): Promise<{ correctedText: string; corrections: Correction[] }> {
  const systemPrompt = CORRECTION_PROMPTS[mode];
  
  const userPrompt = `以下の英語日記を添削し、すべての修正点をリストアップしてください。

重要: 以下の形式のJSONのみで回答してください。他のテキストは含めないでください:
{
  "correctedText": "添削後の完全な日記テキスト",
  "corrections": [
    {
      "type": "grammar|spelling|style|vocabulary",
      "before": "修正前の元のフレーズ（英語）",
      "after": "修正後のフレーズ（英語）",
      "explanation": "この修正が必要な理由の簡潔な説明（日本語で）"
    }
  ]
}

修正が不要な場合は以下を返してください:
{
  "correctedText": "元のテキストをそのまま",
  "corrections": []
}

添削する日記:
"""
${originalText}
"""`;

  try {
    const response = await bedrockClient.send(new InvokeModelCommand({
      modelId: MODEL_ID,
      contentType: 'application/json',
      accept: 'application/json',
      body: JSON.stringify({
        schemaVersion: 'messages-v1',
        messages: [
          {
            role: 'user',
            content: [
              { text: systemPrompt + '\n\n' + userPrompt }
            ],
          },
        ],
        inferenceConfig: {
          maxTokens: 4096,
        },
      }),
    }));

    // Parse the response (Nova format)
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));
    const aiContent = responseBody.output.message.content[0].text;
    
    console.log('Nova response:', aiContent);

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
