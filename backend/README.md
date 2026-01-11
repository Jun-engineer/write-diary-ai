# Write Diary AI - Backend

AWS CDK infrastructure and Lambda functions for the Write Diary AI application.

## Architecture

- **API Gateway**: REST API with Cognito authorization
- **Lambda**: Node.js 18 TypeScript handlers
- **DynamoDB**: NoSQL database for users, diaries, review cards, scan usage
- **S3**: Storage for scanned diary images
- **Cognito**: User authentication and authorization

## Project Structure

```
backend/
├── bin/
│   └── app.ts              # CDK app entry point
├── lib/
│   └── write-diary-ai-stack.ts  # Main CDK stack
├── lambda/
│   ├── handlers/
│   │   ├── diaries/        # Diary CRUD + AI correction
│   │   ├── review-cards/   # Review card management
│   │   ├── scan-usage/     # Scan usage tracking
│   │   └── users/          # User management (Cognito triggers)
│   └── shared/
│       ├── types.ts        # TypeScript types
│       ├── dynamodb.ts     # DynamoDB client
│       ├── response.ts     # API response helpers
│       └── utils.ts        # Utility functions
├── package.json
├── tsconfig.json
└── cdk.json
```

## Prerequisites

- Node.js 18+
- AWS CLI configured with credentials
- AWS CDK CLI (`npm install -g aws-cdk`)

## Setup

1. Install dependencies:
   ```bash
   cd backend
   npm install
   cd lambda && npm install && cd ..
   ```

2. Bootstrap CDK (first time only):
   ```bash
   npm run bootstrap
   ```

3. Deploy:
   ```bash
   npm run deploy
   ```

## API Endpoints

After deployment, you'll get these endpoints:

| Method | Path | Description |
|--------|------|-------------|
| POST | /diaries | Create a new diary entry |
| GET | /diaries | List user's diaries |
| GET | /diaries/{diaryId} | Get a specific diary |
| POST | /diaries/{diaryId}/correct | Run AI correction |
| POST | /review-cards | Create review cards |
| GET | /review-cards | List review cards |
| GET | /scan-usage/today | Get today's scan usage |

All endpoints require a valid Cognito JWT in the `Authorization` header.

## Environment Variables

Lambda functions receive these environment variables:

- `USERS_TABLE`: DynamoDB Users table name
- `DIARIES_TABLE`: DynamoDB Diaries table name
- `REVIEW_CARDS_TABLE`: DynamoDB ReviewCards table name
- `SCAN_USAGE_TABLE`: DynamoDB ScanUsage table name
- `IMAGES_BUCKET`: S3 bucket for scanned images
- `USER_POOL_ID`: Cognito User Pool ID

## AI Integration

The `/diaries/{diaryId}/correct` endpoint is designed to integrate with an LLM API (OpenAI, Anthropic, etc.). 

To enable AI correction:

1. Add your API key to AWS Secrets Manager
2. Update the `correctWithAI` function in `lambda/handlers/diaries/correct.ts`
3. Redeploy

## Local Development

```bash
# Synthesize CloudFormation template
npm run synth

# Compare deployed stack with current state
npm run diff

# Watch for changes and rebuild
npm run watch
```

## Useful Commands

- `npm run build` - Compile TypeScript
- `npm run synth` - Generate CloudFormation template
- `npm run deploy` - Deploy stack to AWS
- `npm run diff` - Show changes between local and deployed
