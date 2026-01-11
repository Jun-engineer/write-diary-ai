import * as cdk from 'aws-cdk-lib';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { NodejsFunction } from 'aws-cdk-lib/aws-lambda-nodejs';
import { Construct } from 'constructs';
import * as path from 'path';

export class WriteDiaryAiStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // ========================================
    // DynamoDB Tables
    // ========================================

    // Users Table
    const usersTable = new dynamodb.Table(this, 'UsersTable', {
      tableName: 'WriteDiaryAi-Users',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      pointInTimeRecovery: true,
    });

    // Diaries Table
    const diariesTable = new dynamodb.Table(this, 'DiariesTable', {
      tableName: 'WriteDiaryAi-Diaries',
      partitionKey: { name: 'diaryId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      pointInTimeRecovery: true,
    });

    // GSI for querying diaries by userId
    diariesTable.addGlobalSecondaryIndex({
      indexName: 'userId-date-index',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'date', type: dynamodb.AttributeType.STRING },
      projectionType: dynamodb.ProjectionType.ALL,
    });

    // Review Cards Table
    const reviewCardsTable = new dynamodb.Table(this, 'ReviewCardsTable', {
      tableName: 'WriteDiaryAi-ReviewCards',
      partitionKey: { name: 'cardId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      pointInTimeRecovery: true,
    });

    // GSI for querying review cards by userId
    reviewCardsTable.addGlobalSecondaryIndex({
      indexName: 'userId-index',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      projectionType: dynamodb.ProjectionType.ALL,
    });

    // Scan Usage Table
    const scanUsageTable = new dynamodb.Table(this, 'ScanUsageTable', {
      tableName: 'WriteDiaryAi-ScanUsage',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'date', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      timeToLiveAttribute: 'ttl', // Auto-cleanup old records
    });

    // ========================================
    // S3 Bucket for scanned images
    // ========================================

    const imagesBucket = new s3.Bucket(this, 'ImagesBucket', {
      bucketName: `write-diary-ai-images-${this.account}-${this.region}`,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      cors: [
        {
          allowedMethods: [s3.HttpMethods.GET, s3.HttpMethods.PUT],
          allowedOrigins: ['*'],
          allowedHeaders: ['*'],
          maxAge: 3000,
        },
      ],
      lifecycleRules: [
        {
          expiration: cdk.Duration.days(90), // Auto-delete images after 90 days
          prefix: 'scans/',
        },
      ],
    });

    // ========================================
    // Cognito User Pool
    // ========================================

    const userPool = new cognito.UserPool(this, 'UserPool', {
      userPoolName: 'WriteDiaryAi-UserPool',
      selfSignUpEnabled: true,
      signInAliases: {
        email: true,
      },
      autoVerify: {
        email: true,
      },
      standardAttributes: {
        email: {
          required: true,
          mutable: true,
        },
      },
      passwordPolicy: {
        minLength: 8,
        requireLowercase: true,
        requireUppercase: true,
        requireDigits: true,
        requireSymbols: false,
      },
      accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    const userPoolClient = new cognito.UserPoolClient(this, 'UserPoolClient', {
      userPool,
      userPoolClientName: 'WriteDiaryAi-MobileApp',
      authFlows: {
        userPassword: true,
        userSrp: true,
      },
      generateSecret: false, // Mobile apps don't use client secrets
      accessTokenValidity: cdk.Duration.hours(1),
      idTokenValidity: cdk.Duration.hours(1),
      refreshTokenValidity: cdk.Duration.days(30),
    });

    // ========================================
    // Lambda Functions
    // ========================================

    // Common Lambda environment variables (without userPoolId to avoid circular dependency)
    const lambdaEnvironment = {
      USERS_TABLE: usersTable.tableName,
      DIARIES_TABLE: diariesTable.tableName,
      REVIEW_CARDS_TABLE: reviewCardsTable.tableName,
      SCAN_USAGE_TABLE: scanUsageTable.tableName,
      IMAGES_BUCKET: imagesBucket.bucketName,
      NODE_OPTIONS: '--enable-source-maps',
    };

    // Common bundling config
    const bundlingConfig = {
      minify: true,
      sourceMap: true,
      externalModules: ['@aws-sdk/*'],
    };

    // Post-confirmation handler MUST be created BEFORE UserPool to avoid circular dependency
    const postConfirmationHandler = new NodejsFunction(this, 'PostConfirmationHandler', {
      runtime: lambda.Runtime.NODEJS_18_X,
      timeout: cdk.Duration.seconds(30),
      memorySize: 256,
      functionName: 'WriteDiaryAi-PostConfirmation',
      entry: path.join(__dirname, '../lambda/handlers/users/post-confirmation.ts'),
      handler: 'handler',
      environment: {
        USERS_TABLE: usersTable.tableName,
        NODE_OPTIONS: '--enable-source-maps',
      },
      bundling: bundlingConfig,
    });

    // Grant permissions to post-confirmation handler
    usersTable.grantReadWriteData(postConfirmationHandler);

    // Add Cognito trigger BEFORE creating the UserPoolClient
    userPool.addTrigger(cognito.UserPoolOperation.POST_CONFIRMATION, postConfirmationHandler);

    // Common Lambda props (for API handlers)
    const commonLambdaProps = {
      runtime: lambda.Runtime.NODEJS_18_X,
      timeout: cdk.Duration.seconds(30),
      memorySize: 256,
      environment: lambdaEnvironment,
      bundling: bundlingConfig,
    };

    // Diary Handlers
    const createDiaryHandler = new NodejsFunction(this, 'CreateDiaryHandler', {
      ...commonLambdaProps,
      functionName: 'WriteDiaryAi-CreateDiary',
      entry: path.join(__dirname, '../lambda/handlers/diaries/create.ts'),
      handler: 'handler',
    });

    const getDiariesHandler = new NodejsFunction(this, 'GetDiariesHandler', {
      ...commonLambdaProps,
      functionName: 'WriteDiaryAi-GetDiaries',
      entry: path.join(__dirname, '../lambda/handlers/diaries/list.ts'),
      handler: 'handler',
    });

    const getDiaryHandler = new NodejsFunction(this, 'GetDiaryHandler', {
      ...commonLambdaProps,
      functionName: 'WriteDiaryAi-GetDiary',
      entry: path.join(__dirname, '../lambda/handlers/diaries/get.ts'),
      handler: 'handler',
    });

    const correctDiaryHandler = new NodejsFunction(this, 'CorrectDiaryHandler', {
      ...commonLambdaProps,
      functionName: 'WriteDiaryAi-CorrectDiary',
      entry: path.join(__dirname, '../lambda/handlers/diaries/correct.ts'),
      handler: 'handler',
      timeout: cdk.Duration.seconds(60), // AI correction may take longer
      memorySize: 512,
    });

    // Review Card Handlers
    const createReviewCardsHandler = new NodejsFunction(this, 'CreateReviewCardsHandler', {
      ...commonLambdaProps,
      functionName: 'WriteDiaryAi-CreateReviewCards',
      entry: path.join(__dirname, '../lambda/handlers/review-cards/create.ts'),
      handler: 'handler',
    });

    const getReviewCardsHandler = new NodejsFunction(this, 'GetReviewCardsHandler', {
      ...commonLambdaProps,
      functionName: 'WriteDiaryAi-GetReviewCards',
      entry: path.join(__dirname, '../lambda/handlers/review-cards/list.ts'),
      handler: 'handler',
    });

    // Scan Usage Handler
    const getScanUsageHandler = new NodejsFunction(this, 'GetScanUsageHandler', {
      ...commonLambdaProps,
      functionName: 'WriteDiaryAi-GetScanUsage',
      entry: path.join(__dirname, '../lambda/handlers/scan-usage/get.ts'),
      handler: 'handler',
    });

    // Grant DynamoDB permissions
    usersTable.grantReadData(createDiaryHandler);
    usersTable.grantReadData(correctDiaryHandler);

    diariesTable.grantReadWriteData(createDiaryHandler);
    diariesTable.grantReadData(getDiariesHandler);
    diariesTable.grantReadData(getDiaryHandler);
    diariesTable.grantReadWriteData(correctDiaryHandler);

    // Grant Bedrock permissions for AI correction (Claude 3.5 Haiku)
    correctDiaryHandler.addToRolePolicy(new cdk.aws_iam.PolicyStatement({
      actions: ['bedrock:InvokeModel'],
      resources: ['arn:aws:bedrock:*::foundation-model/anthropic.claude-3-5-haiku-*'],
    }));

    reviewCardsTable.grantReadWriteData(createReviewCardsHandler);
    reviewCardsTable.grantReadData(getReviewCardsHandler);
    diariesTable.grantReadData(createReviewCardsHandler); // Need to read diary for context

    scanUsageTable.grantReadWriteData(createDiaryHandler); // Increment scan count
    scanUsageTable.grantReadData(getScanUsageHandler);
    usersTable.grantReadData(getScanUsageHandler); // Check user plan

    // Grant S3 permissions for image upload
    imagesBucket.grantReadWrite(createDiaryHandler);

    // ========================================
    // API Gateway
    // ========================================

    const api = new apigateway.RestApi(this, 'WriteDiaryAiApi', {
      restApiName: 'WriteDiaryAi-API',
      description: 'API for Write Diary AI application',
      deployOptions: {
        stageName: 'v1',
        throttlingRateLimit: 100,
        throttlingBurstLimit: 200,
      },
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization', 'X-Amz-Date', 'X-Api-Key'],
      },
    });

    // Cognito Authorizer
    const authorizer = new apigateway.CognitoUserPoolsAuthorizer(this, 'CognitoAuthorizer', {
      cognitoUserPools: [userPool],
      authorizerName: 'CognitoAuthorizer',
    });

    const authorizationOptions: apigateway.MethodOptions = {
      authorizer,
      authorizationType: apigateway.AuthorizationType.COGNITO,
    };

    // /diaries endpoints
    const diaries = api.root.addResource('diaries');
    diaries.addMethod('POST', new apigateway.LambdaIntegration(createDiaryHandler), authorizationOptions);
    diaries.addMethod('GET', new apigateway.LambdaIntegration(getDiariesHandler), authorizationOptions);

    const diary = diaries.addResource('{diaryId}');
    diary.addMethod('GET', new apigateway.LambdaIntegration(getDiaryHandler), authorizationOptions);

    const correct = diary.addResource('correct');
    correct.addMethod('POST', new apigateway.LambdaIntegration(correctDiaryHandler), authorizationOptions);

    // /review-cards endpoints
    const reviewCards = api.root.addResource('review-cards');
    reviewCards.addMethod('POST', new apigateway.LambdaIntegration(createReviewCardsHandler), authorizationOptions);
    reviewCards.addMethod('GET', new apigateway.LambdaIntegration(getReviewCardsHandler), authorizationOptions);

    // /scan-usage endpoints
    const scanUsage = api.root.addResource('scan-usage');
    const scanUsageToday = scanUsage.addResource('today');
    scanUsageToday.addMethod('GET', new apigateway.LambdaIntegration(getScanUsageHandler), authorizationOptions);

    // ========================================
    // Outputs
    // ========================================

    new cdk.CfnOutput(this, 'ApiEndpoint', {
      value: api.url,
      description: 'API Gateway endpoint URL',
      exportName: 'WriteDiaryAi-ApiEndpoint',
    });

    new cdk.CfnOutput(this, 'UserPoolId', {
      value: userPool.userPoolId,
      description: 'Cognito User Pool ID',
      exportName: 'WriteDiaryAi-UserPoolId',
    });

    new cdk.CfnOutput(this, 'UserPoolClientId', {
      value: userPoolClient.userPoolClientId,
      description: 'Cognito User Pool Client ID',
      exportName: 'WriteDiaryAi-UserPoolClientId',
    });

    new cdk.CfnOutput(this, 'ImagesBucketName', {
      value: imagesBucket.bucketName,
      description: 'S3 Bucket for scanned images',
      exportName: 'WriteDiaryAi-ImagesBucket',
    });

    new cdk.CfnOutput(this, 'Region', {
      value: this.region,
      description: 'AWS Region',
      exportName: 'WriteDiaryAi-Region',
    });
  }
}
