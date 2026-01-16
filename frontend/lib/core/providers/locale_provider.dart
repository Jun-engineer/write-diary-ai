import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported locales
enum AppLocale {
  japanese('ja', '日本語'),
  english('en', 'English');

  const AppLocale(this.code, this.displayName);
  final String code;
  final String displayName;

  static AppLocale fromCode(String code) {
    return AppLocale.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLocale.japanese, // Default to Japanese
    );
  }
}

/// Locale provider
final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<AppLocale> {
  LocaleNotifier() : super(AppLocale.japanese) {
    _loadLocale();
  }

  static const _key = 'app_locale';

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      state = AppLocale.fromCode(code);
    }
  }

  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.code);
  }
}

/// Localized strings
class AppStrings {
  final AppLocale locale;

  AppStrings(this.locale);

  // Common
  String get cancel => locale == AppLocale.japanese ? 'キャンセル' : 'Cancel';
  String get save => locale == AppLocale.japanese ? '保存' : 'Save';
  String get delete => locale == AppLocale.japanese ? '削除' : 'Delete';
  String get edit => locale == AppLocale.japanese ? '編集' : 'Edit';
  String get close => locale == AppLocale.japanese ? '閉じる' : 'Close';
  String get retry => locale == AppLocale.japanese ? '再試行' : 'Retry';
  String get comingSoon => locale == AppLocale.japanese ? '近日公開' : 'Coming soon!';

  // Settings
  String get settings => locale == AppLocale.japanese ? '設定' : 'Settings';
  String get account => locale == AppLocale.japanese ? 'アカウント' : 'Account';
  String get correctionSettings => locale == AppLocale.japanese ? '添削設定' : 'Correction Settings';
  String get defaultCorrectionMode => locale == AppLocale.japanese ? 'デフォルトの添削モード' : 'Default Correction Mode';
  String get todaysUsage => locale == AppLocale.japanese ? '今日の使用量' : "Today's Usage";
  String get scansUsed => locale == AppLocale.japanese ? 'スキャン使用回数' : 'Scans Used';
  String get correctionsUsed => locale == AppLocale.japanese ? 'AI添削使用回数' : 'AI Corrections Used';
  String get app => locale == AppLocale.japanese ? 'アプリ' : 'App';
  String get darkMode => locale == AppLocale.japanese ? 'ダークモード' : 'Dark Mode';
  String get followSystem => locale == AppLocale.japanese ? 'システム設定に従う' : 'Follow system';
  String get light => locale == AppLocale.japanese ? 'ライト' : 'Light';
  String get dark => locale == AppLocale.japanese ? 'ダーク' : 'Dark';
  String get system => locale == AppLocale.japanese ? 'システム' : 'System';
  String get language => locale == AppLocale.japanese ? '言語' : 'Language';
  String get about => locale == AppLocale.japanese ? 'アプリについて' : 'About';
  String get version => locale == AppLocale.japanese ? 'バージョン' : 'Version';
  String get termsOfService => locale == AppLocale.japanese ? '利用規約' : 'Terms of Service';
  String get privacyPolicy => locale == AppLocale.japanese ? 'プライバシーポリシー' : 'Privacy Policy';
  String get logOut => locale == AppLocale.japanese ? 'ログアウト' : 'Log Out';
  String get deleteAccount => locale == AppLocale.japanese ? 'アカウント削除' : 'Delete Account';
  String get displayName => locale == AppLocale.japanese ? '表示名' : 'Display Name';
  String get editDisplayName => locale == AppLocale.japanese ? '表示名を編集' : 'Edit Display Name';
  String get enterDisplayName => locale == AppLocale.japanese ? '表示名を入力' : 'Enter your display name';
  String get upgrade => locale == AppLocale.japanese ? 'アップグレード' : 'Upgrade';
  
  // Correction modes
  String get beginner => locale == AppLocale.japanese ? '初級' : 'Beginner';
  String get intermediate => locale == AppLocale.japanese ? '中級' : 'Intermediate';
  String get advanced => locale == AppLocale.japanese ? '上級' : 'Advanced';

  // Usage info
  String get freePlanInfo => locale == AppLocale.japanese 
      ? '無料プランでは1日1回のスキャンと3回のAI添削が可能です。広告を見ると追加で利用できます。プレミアムなら無制限！'
      : 'Free plan: 1 scan + 3 AI corrections/day. Watch ads for bonus uses. Premium = unlimited!';

  // Dialogs
  String get logOutConfirm => locale == AppLocale.japanese ? 'ログアウトしますか？' : 'Are you sure you want to log out?';
  String get deleteAccountTitle => locale == AppLocale.japanese ? 'アカウント削除' : 'Delete Account';
  String get deleteAccountConfirm => locale == AppLocale.japanese 
      ? 'アカウントを削除しますか？この操作は取り消せません。すべての日記とデータが完全に削除されます。'
      : 'Are you sure you want to delete your account? This action cannot be undone. All your diaries and data will be permanently deleted.';

  // Success messages
  String get displayNameUpdated => locale == AppLocale.japanese ? '表示名を更新しました' : 'Display name updated';
  String get accountDeleted => locale == AppLocale.japanese ? 'アカウントを削除しました' : 'Account deleted successfully';
  
  // Error messages
  String get updateFailed => locale == AppLocale.japanese ? '更新に失敗しました' : 'Failed to update';
  String get deleteFailed => locale == AppLocale.japanese ? 'アカウントの削除に失敗しました' : 'Failed to delete account';
  String get loadingError => locale == AppLocale.japanese ? '読み込みエラー' : 'Error loading';
  String get tapToRetry => locale == AppLocale.japanese ? 'タップして再試行' : 'Tap to retry';
  
  // Loading states
  String get loading => locale == AppLocale.japanese ? '読み込み中...' : 'Loading...';
  String get deleting => locale == AppLocale.japanese ? '削除中...' : 'Deleting...';
  
  // Theme dialog
  String get selectTheme => locale == AppLocale.japanese ? 'テーマを選択' : 'Select Theme';
  String get lightMode => locale == AppLocale.japanese ? 'ライトモード' : 'Light Mode';
  String get darkModeOption => locale == AppLocale.japanese ? 'ダークモード' : 'Dark Mode';
  String get systemDefault => locale == AppLocale.japanese ? 'システム設定に従う' : 'Follow System';
  
  // Language dialog
  String get selectLanguage => locale == AppLocale.japanese ? '言語を選択' : 'Select Language';
  
  // Correction mode dialog
  String get selectCorrectionMode => locale == AppLocale.japanese ? '添削モードを選択' : 'Select Correction Mode';
  
  // Plan
  String get freePlan => locale == AppLocale.japanese ? '無料プラン' : 'Free Plan';
  String get plan => locale == AppLocale.japanese ? 'プラン' : 'Plan';
  String get noLimit => locale == AppLocale.japanese ? '無制限' : 'NO LIMIT';
  
  // Diary Detail Screen
  String get originalDiary => locale == AppLocale.japanese ? '元の日記' : 'Original Diary';
  String get aiCorrection => locale == AppLocale.japanese ? 'AI添削' : 'AI Correction';
  String get correcting => locale == AppLocale.japanese ? '添削中...' : 'Correcting...';
  String get reCorrect => locale == AppLocale.japanese ? '再添削する' : 'Re-correct';
  String get runAiCorrection => locale == AppLocale.japanese ? 'AI添削を実行' : 'Run AI Correction';
  String get corrected => locale == AppLocale.japanese ? '添削後' : 'Corrected';
  String corrections(int count) => locale == AppLocale.japanese ? '修正点 ($count件)' : 'Corrections ($count)';
  String get addToReviewCards => locale == AppLocale.japanese ? '復習カードに追加' : 'Add to Review Cards';
  String addToCards(int count) => locale == AppLocale.japanese ? '$count件をカードに追加' : 'Add $count to Cards';
  String get creating => locale == AppLocale.japanese ? '作成中...' : 'Creating...';
  String get selectCorrectionsHint => locale == AppLocale.japanese ? '復習カードに追加する修正を選択してください' : 'Select corrections to add to review cards';
  String get correctionComplete => locale == AppLocale.japanese ? '添削完了！' : 'Correction complete!';
  String cardsCreated(int count) => locale == AppLocale.japanese ? '$count件のカードを作成しました' : 'Created $count cards';
  String get noSelectionsError => locale == AppLocale.japanese ? '追加する修正を選択してください' : 'Please select corrections to add';
  String get diaryDeleted => locale == AppLocale.japanese ? '日記を削除しました' : 'Diary deleted';
  String get deleteFailed2 => locale == AppLocale.japanese ? '削除に失敗しました' : 'Failed to delete';
  String get correctionFailed => locale == AppLocale.japanese ? '添削に失敗しました' : 'Correction failed';
  String get cardCreationFailed => locale == AppLocale.japanese ? 'カードの作成に失敗しました' : 'Failed to create cards';
  String get deleteDiaryTitle => locale == AppLocale.japanese ? '日記を削除' : 'Delete Diary';
  String get deleteDiaryConfirm => locale == AppLocale.japanese ? 'この日記を削除してもよろしいですか？' : 'Are you sure you want to delete this diary?';
  
  // Correction mode descriptions
  String get beginnerDesc => locale == AppLocale.japanese ? '基本的な文法、スペル、冠詞の欠落に注目します。' : 'Focuses on basic grammar, spelling, and missing articles.';
  String get intermediateDesc => locale == AppLocale.japanese ? '語彙の改善や自然な言い回しも含めて添削します。' : 'Includes vocabulary improvements and natural expressions.';
  String get advancedDesc => locale == AppLocale.japanese ? 'スタイルやイディオムを含む包括的な添削を行います。' : 'Comprehensive correction including style and idioms.';
}

/// Provider for localized strings
final stringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(locale);
});
