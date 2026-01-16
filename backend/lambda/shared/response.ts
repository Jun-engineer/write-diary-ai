import { APIGatewayProxyResult } from 'aws-lambda';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
};

export function success<T>(body: T): APIGatewayProxyResult {
  return {
    statusCode: 200,
    headers: corsHeaders,
    body: JSON.stringify(body),
  };
}

export function created<T>(body: T): APIGatewayProxyResult {
  return {
    statusCode: 201,
    headers: corsHeaders,
    body: JSON.stringify(body),
  };
}

export function badRequest(message: string): APIGatewayProxyResult {
  return {
    statusCode: 400,
    headers: corsHeaders,
    body: JSON.stringify({ error: message }),
  };
}

export function unauthorized(message: string = 'Unauthorized'): APIGatewayProxyResult {
  return {
    statusCode: 401,
    headers: corsHeaders,
    body: JSON.stringify({ error: message }),
  };
}

export function forbidden(message: string = 'Forbidden'): APIGatewayProxyResult {
  return {
    statusCode: 403,
    headers: corsHeaders,
    body: JSON.stringify({ error: message }),
  };
}

export function forbiddenWithData<T>(data: T): APIGatewayProxyResult {
  return {
    statusCode: 403,
    headers: corsHeaders,
    body: JSON.stringify(data),
  };
}

export function notFound(message: string = 'Not found'): APIGatewayProxyResult {
  return {
    statusCode: 404,
    headers: corsHeaders,
    body: JSON.stringify({ error: message }),
  };
}

export function serverError(message: string = 'Internal server error'): APIGatewayProxyResult {
  return {
    statusCode: 500,
    headers: corsHeaders,
    body: JSON.stringify({ error: message }),
  };
}

export function tooManyRequests(message: string = 'Rate limit exceeded'): APIGatewayProxyResult {
  return {
    statusCode: 429,
    headers: corsHeaders,
    body: JSON.stringify({ error: message }),
  };
}
