/// API and AWS Configuration
class AppConfig {
  static const String apiBaseUrl = 'https://jz0t7oc637.execute-api.ap-northeast-1.amazonaws.com/v1';
  
  static const String cognitoUserPoolId = 'ap-northeast-1_d6DzHVtv1';
  static const String cognitoClientId = '10rd7jdcpo3m4hafjk3n80j1sc';
  static const String s3BucketName = 'write-diary-ai-images-085141726968-ap-northeast-1';
  static const String awsRegion = 'ap-northeast-1';
  
  // Plan limits
  static const int freePlanScanLimit = 1;
  static const int premiumPlanScanLimit = 999;
  
  // Correction modes
  static const List<String> correctionModes = ['beginner', 'intermediate', 'advanced'];
}
