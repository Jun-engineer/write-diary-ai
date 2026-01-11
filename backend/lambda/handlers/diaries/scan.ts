import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';
import { success, badRequest, serverError } from '../../shared/response';

const bedrockClient = new BedrockRuntimeClient({ region: process.env.AWS_REGION });

interface ScanRequest {
  imageBase64: string; // Base64 encoded image
  mediaType?: string;  // image/jpeg, image/png, etc.
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
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

  const requestBody = {
    anthropic_version: 'bedrock-2023-05-31',
    max_tokens: 4096,
    messages: [
      {
        role: 'user',
        content: [
          {
            type: 'image',
            source: {
              type: 'base64',
              media_type: mediaType,
              data: imageBase64,
            },
          },
          {
            type: 'text',
            text: prompt,
          },
        ],
      },
    ],
  };

  const command = new InvokeModelCommand({
    modelId: 'anthropic.claude-3-haiku-20240307-v1:0',
    contentType: 'application/json',
    accept: 'application/json',
    body: JSON.stringify(requestBody),
  });

  const response = await bedrockClient.send(command);
  const responseBody = JSON.parse(new TextDecoder().decode(response.body));

  if (responseBody.content && responseBody.content.length > 0) {
    const text = responseBody.content[0].text.trim();
    
    // Check if no text was found
    if (text === '[No readable text found]') {
      return '';
    }
    
    return text;
  }

  return '';
}
