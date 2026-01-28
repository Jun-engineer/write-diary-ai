import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { docClient, GetCommand, UpdateCommand } from '../../shared/dynamodb';
import { success, badRequest, unauthorized, notFound, forbiddenWithData, serverError } from '../../shared/response';
import { getUserIdFromEvent, parseBody, now, getTodayDate, getTTL } from '../../shared/utils';
import { 
  Diary, 
  CorrectDiaryRequest, 
  CorrectDiaryResponse, 
  Correction, 
  CorrectionMode,
  User,
  TargetLanguage,
  NativeLanguage,
  PLAN_LIMITS,
} from '../../shared/types';

const DIARIES_TABLE = process.env.DIARIES_TABLE!;
const USERS_TABLE = process.env.USERS_TABLE!;
const CORRECTION_USAGE_TABLE = process.env.CORRECTION_USAGE_TABLE!;

// Initialize Bedrock client - use us-east-1 where models are available
const bedrockClient = new BedrockRuntimeClient({ region: 'us-east-1' });

// Amazon Nova Lite model ID (available without approval)
const MODEL_ID = 'amazon.nova-lite-v1:0';

// Language display names for prompts
const LANGUAGE_NAMES: Record<TargetLanguage, { english: string; native: string }> = {
  english: { english: 'English', native: '英語' },
  spanish: { english: 'Spanish', native: 'スペイン語' },
  chinese: { english: 'Chinese', native: '中国語' },
  japanese: { english: 'Japanese', native: '日本語' },
  korean: { english: 'Korean', native: '韓国語' },
  french: { english: 'French', native: 'フランス語' },
  german: { english: 'German', native: 'ドイツ語' },
  italian: { english: 'Italian', native: 'イタリア語' },
};

// Native language names for explanation instructions
const NATIVE_LANGUAGE_INSTRUCTIONS: Record<NativeLanguage, string> = {
  english: 'Provide explanations in English.',
  japanese: '説明は日本語で行ってください。',
  spanish: 'Proporcione explicaciones en español.',
  chinese: '请用中文提供解释。',
  korean: '설명은 한국어로 해주세요.',
  french: 'Fournissez des explications en français.',
  german: 'Erklärungen auf Deutsch.',
  italian: 'Fornire spiegazioni in italiano.',
};

// Generate correction prompt based on mode, target language, and native language
function generateCorrectionPrompt(
  mode: CorrectionMode,
  targetLanguage: TargetLanguage,
  nativeLanguage: NativeLanguage
): string {
  const langName = LANGUAGE_NAMES[targetLanguage].english;
  const nativeInstruction = NATIVE_LANGUAGE_INSTRUCTIONS[nativeLanguage];
  
  const prompts: Record<CorrectionMode, string> = {
    beginner: `You are a kind ${langName} teacher correcting a beginner student's ${langName} diary.
Focus only on:
- Basic grammar errors (verb tense, subject-verb agreement)
- Spelling mistakes
- Missing articles or basic particles

${nativeInstruction}
Keep explanations simple and encouraging.`,
    
    intermediate: `You are a ${langName} teacher improving an intermediate student's ${langName} diary.
Focus on:
- All grammar and spelling errors
- Unnatural expressions that should sound more natural
- Vocabulary improvement suggestions
- Preposition/particle usage

${nativeInstruction}
Explain clearly why each correction is needed.`,
    
    advanced: `You are a ${langName} teacher refining an advanced student's ${langName} diary.
Provide comprehensive corrections including:
- Grammar and spelling (including subtle errors)
- Replace unnatural expressions with natural expressions or idioms
- Style improvements for more sophisticated writing
- Better vocabulary suggestions
- Detailed explanations of why native speakers prefer certain expressions

${nativeInstruction}`,
  };
  
  return prompts[mode];
}

// Generate user prompt for correction
function generateUserPrompt(
  originalText: string,
  targetLanguage: TargetLanguage,
  nativeLanguage: NativeLanguage
): string {
  const langName = LANGUAGE_NAMES[targetLanguage].english;
  
  // Use native language for JSON field descriptions
  const jsonDescriptions: Record<NativeLanguage, { correctedText: string; before: string; after: string; explanation: string; noCorrectionNeeded: string }> = {
    english: {
      correctedText: 'The complete corrected diary text',
      before: 'Original phrase before correction',
      after: 'Corrected phrase',
      explanation: 'Brief explanation of why this correction is needed',
      noCorrectionNeeded: 'If no corrections are needed, return:',
    },
    japanese: {
      correctedText: '添削後の完全な日記テキスト',
      before: '修正前の元のフレーズ',
      after: '修正後のフレーズ',
      explanation: 'この修正が必要な理由の簡潔な説明（日本語で）',
      noCorrectionNeeded: '修正が不要な場合は以下を返してください:',
    },
    spanish: {
      correctedText: 'El texto completo del diario corregido',
      before: 'Frase original antes de la corrección',
      after: 'Frase corregida',
      explanation: 'Breve explicación de por qué se necesita esta corrección (en español)',
      noCorrectionNeeded: 'Si no se necesitan correcciones, devuelva:',
    },
    chinese: {
      correctedText: '校正后的完整日记文本',
      before: '修正前的原始短语',
      after: '修正后的短语',
      explanation: '简要说明为什么需要此修正（用中文）',
      noCorrectionNeeded: '如果不需要修正，请返回：',
    },
    korean: {
      correctedText: '수정된 전체 일기 텍스트',
      before: '수정 전 원래 문구',
      after: '수정된 문구',
      explanation: '이 수정이 필요한 이유에 대한 간략한 설명 (한국어로)',
      noCorrectionNeeded: '수정이 필요 없는 경우 다음을 반환하세요:',
    },
    french: {
      correctedText: 'Le texte complet du journal corrigé',
      before: 'Phrase originale avant correction',
      after: 'Phrase corrigée',
      explanation: 'Brève explication de la raison de cette correction (en français)',
      noCorrectionNeeded: 'Si aucune correction n\'est nécessaire, retournez:',
    },
    german: {
      correctedText: 'Der vollständige korrigierte Tagebuchtext',
      before: 'Ursprünglicher Satz vor der Korrektur',
      after: 'Korrigierter Satz',
      explanation: 'Kurze Erklärung, warum diese Korrektur erforderlich ist (auf Deutsch)',
      noCorrectionNeeded: 'Wenn keine Korrekturen erforderlich sind, geben Sie zurück:',
    },
    italian: {
      correctedText: 'Il testo completo del diario corretto',
      before: 'Frase originale prima della correzione',
      after: 'Frase corretta',
      explanation: 'Breve spiegazione del perché è necessaria questa correzione (in italiano)',
      noCorrectionNeeded: 'Se non sono necessarie correzioni, restituisci:',
    },
  };
  
  const desc = jsonDescriptions[nativeLanguage];
  
  return `Correct the following ${langName} diary and list all corrections.

IMPORTANT: Reply ONLY with JSON in this format. Do not include any other text:
{
  "correctedText": "${desc.correctedText}",
  "corrections": [
    {
      "type": "grammar|spelling|style|vocabulary",
      "before": "${desc.before}",
      "after": "${desc.after}",
      "explanation": "${desc.explanation}"
    }
  ]
}

${desc.noCorrectionNeeded}
{
  "correctedText": "original text unchanged",
  "corrections": []
}

Diary to correct:
"""
${originalText}
"""`;
}

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

    // Get user to check plan
    const userResult = await docClient.send(new GetCommand({
      TableName: USERS_TABLE,
      Key: { userId },
    }));

    const user = userResult.Item as User | undefined;
    const plan = user?.plan || 'free';
    const limits = plan === 'premium' ? PLAN_LIMITS.premium : PLAN_LIMITS.free;

    // Check correction usage for FREE users
    if (plan !== 'premium') {
      const today = getTodayDate();

      const usageResult = await docClient.send(new GetCommand({
        TableName: CORRECTION_USAGE_TABLE,
        Key: { userId, date: today },
      }));

      const currentCount = (usageResult.Item?.count || 0) as number;
      const bonusCount = (usageResult.Item?.bonusCount || 0) as number;
      const totalLimit = limits.correctionPerDay + bonusCount;

      if (currentCount >= totalLimit) {
        const canWatchAd = bonusCount < limits.maxCorrectionBonusPerDay;
        return forbiddenWithData({
          code: 'CORRECTION_LIMIT_REACHED',
          message: 'Daily correction limit reached',
          count: currentCount,
          limit: limits.correctionPerDay,
          bonusCount: bonusCount,
          maxBonus: limits.maxCorrectionBonusPerDay,
          canWatchAd: canWatchAd,
        });
      }
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

    // Call AI for correction with user's language preferences
    const targetLanguage = user?.targetLanguage || 'english';
    const nativeLanguage = user?.nativeLanguage || 'japanese';
    const { correctedText, corrections } = await correctWithAI(
      diary.originalText, 
      mode, 
      targetLanguage, 
      nativeLanguage
    );

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

    // Increment correction usage count for FREE users
    if (plan !== 'premium') {
      const today = getTodayDate();

      await docClient.send(new UpdateCommand({
        TableName: CORRECTION_USAGE_TABLE,
        Key: { userId, date: today },
        UpdateExpression: 'SET #count = if_not_exists(#count, :zero) + :one, #ttl = :ttl',
        ExpressionAttributeNames: {
          '#count': 'count',
          '#ttl': 'ttl',
        },
        ExpressionAttributeValues: {
          ':zero': 0,
          ':one': 1,
          ':ttl': getTTL(30), // Keep records for 30 days
        },
      }));
    }

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
 * Supports multiple target languages and native languages for explanations
 * Includes retry logic for transient failures
 */
async function correctWithAI(
  originalText: string, 
  mode: CorrectionMode,
  targetLanguage: TargetLanguage,
  nativeLanguage: NativeLanguage
): Promise<{ correctedText: string; corrections: Correction[] }> {
  const systemPrompt = generateCorrectionPrompt(mode, targetLanguage, nativeLanguage);
  const userPrompt = generateUserPrompt(originalText, targetLanguage, nativeLanguage);

  const maxRetries = 3;
  let lastError: any = null;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      console.log(`AI correction attempt ${attempt}/${maxRetries}`);
      
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
            temperature: 0.3, // Lower temperature for more consistent output
          },
        }),
      }));

      // Parse the response (Nova format)
      const responseBody = JSON.parse(new TextDecoder().decode(response.body));
      const aiContent = responseBody.output?.message?.content?.[0]?.text;
      
      if (!aiContent) {
        console.error('Empty AI response content');
        throw new Error('Empty AI response');
      }
      
      console.log('Nova response:', aiContent);

      // Try to extract JSON from the response (AI might include extra text)
      let jsonStr = aiContent;
      
      // Try to find JSON object in the response
      const jsonMatch = aiContent.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        jsonStr = jsonMatch[0];
      }

      // Parse the JSON response
      const parsed = JSON.parse(jsonStr);
      
      // Validate required fields
      if (typeof parsed.correctedText !== 'string') {
        console.error('Invalid correctedText in response:', parsed);
        throw new Error('Invalid correctedText in AI response');
      }
      
      // Validate and return the corrections
      return {
        correctedText: parsed.correctedText,
        corrections: Array.isArray(parsed.corrections) 
          ? parsed.corrections.map((c: any) => ({
              type: ['grammar', 'spelling', 'style', 'vocabulary'].includes(c.type) ? c.type : 'grammar',
              before: String(c.before || ''),
              after: String(c.after || ''),
              explanation: String(c.explanation || ''),
            }))
          : [],
      };
    } catch (error: any) {
      lastError = error;
      console.error(`AI correction attempt ${attempt} failed:`, error.message || error);
      
      // If it's a rate limit or throttling error, wait before retry
      if (error.name === 'ThrottlingException' || error.name === 'ServiceUnavailableException') {
        const waitTime = Math.pow(2, attempt) * 1000; // Exponential backoff: 2s, 4s, 8s
        console.log(`Waiting ${waitTime}ms before retry...`);
        await new Promise(resolve => setTimeout(resolve, waitTime));
      } else if (attempt < maxRetries) {
        // Brief pause before retry for other errors
        await new Promise(resolve => setTimeout(resolve, 500));
      }
    }
  }

  // All retries failed - throw error instead of silently returning original text
  console.error('All AI correction attempts failed. Last error:', lastError);
  throw new Error(`AI correction failed after ${maxRetries} attempts: ${lastError?.message || 'Unknown error'}`);
}
