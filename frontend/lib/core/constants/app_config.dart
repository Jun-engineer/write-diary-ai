/// API and AWS Configuration
class AppConfig {
  // TODO: Replace with actual values after CDK deployment
  static const String apiBaseUrl = 'https://YOUR_API_ID.execute-api.ap-northeast-1.amazonaws.com/v1';
  
  static const String cognitoUserPoolId = 'ap-northeast-1_XXXXXXXX';
  static const String cognitoClientId = 'XXXXXXXXXXXXXXXXXXXXXXXX';
  static const String awsRegion = 'ap-northeast-1';
  
  // Plan limits
  static const int freePlanScanLimit = 1;
  static const int premiumPlanScanLimit = 999;
  
  // Correction modes
  static const List<String> correctionModes = ['beginner', 'intermediate', 'advanced'];
}
