import 'dart:ui' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported locales - matches nativeLanguage options
enum AppLocale {
  japanese('japanese', '日本語'),
  english('english', 'English'),
  spanish('spanish', 'Español'),
  chinese('chinese', '中文'),
  korean('korean', '한국어'),
  french('french', 'Français'),
  german('german', 'Deutsch'),
  italian('italian', 'Italiano');

  const AppLocale(this.code, this.displayName);
  final String code;
  final String displayName;

  static AppLocale fromCode(String code) {
    return AppLocale.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLocale.japanese, // Default to Japanese
    );
  }
  
  /// Check if this locale is Japanese (for conditional logic)
  bool get isJapanese => this == AppLocale.japanese;

  /// Convert to Flutter Locale for MaterialApp
  Locale toLocale() {
    switch (this) {
      case AppLocale.japanese: return const Locale('ja');
      case AppLocale.english: return const Locale('en');
      case AppLocale.spanish: return const Locale('es');
      case AppLocale.chinese: return const Locale('zh');
      case AppLocale.korean: return const Locale('ko');
      case AppLocale.french: return const Locale('fr');
      case AppLocale.german: return const Locale('de');
      case AppLocale.italian: return const Locale('it');
    }
  }

  /// Get intl locale code for DateFormat
  String get intlLocale {
    switch (this) {
      case AppLocale.japanese: return 'ja';
      case AppLocale.english: return 'en';
      case AppLocale.spanish: return 'es';
      case AppLocale.chinese: return 'zh_CN';
      case AppLocale.korean: return 'ko';
      case AppLocale.french: return 'fr';
      case AppLocale.german: return 'de';
      case AppLocale.italian: return 'it';
    }
  }
}

/// Locale provider
final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>((ref) {
  return LocaleNotifier();
});

/// Whether language selection has been completed (first launch)
final languageSelectedProvider = StateProvider<bool>((ref) => false);

/// Target language selected during onboarding (before login)
final onboardingTargetLanguageProvider = StateProvider<AppLocale>((ref) => AppLocale.english);

class LocaleNotifier extends StateNotifier<AppLocale> {
  LocaleNotifier() : super(AppLocale.japanese) {
    _loadLocale();
  }

  static const _key = 'app_locale';
  static const _languageSelectedKey = 'language_selected';
  static const _onboardingTargetKey = 'onboarding_target_language';
  bool _languageSelected = false;

  bool get languageSelected => _languageSelected;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    _languageSelected = prefs.getBool(_languageSelectedKey) ?? false;
    if (code != null) {
      state = AppLocale.fromCode(code);
    }
  }

  Future<bool> isLanguageSelected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_languageSelectedKey) ?? false;
  }

  /// Get the target language stored during onboarding
  static Future<String?> getOnboardingTargetLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('onboarding_target_language');
  }

  /// Get the native language stored during onboarding
  static Future<String?> getOnboardingNativeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('onboarding_native_language');
  }

  /// Clear onboarding languages after syncing to backend
  static Future<void> clearOnboardingLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_target_language');
    await prefs.remove('onboarding_native_language');
  }

  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.code);
  }

  Future<void> setOnboardingTargetLanguage(AppLocale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_onboardingTargetKey, locale.code);
  }

  Future<void> setOnboardingNativeLanguage(AppLocale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboarding_native_language', locale.code);
  }

  Future<void> completeLanguageSelection() async {
    _languageSelected = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_languageSelectedKey, true);
  }
}

/// Localized strings - supports 8 languages
class AppStrings {
  final AppLocale locale;

  AppStrings(this.locale);

  /// Helper to get string by locale
  String _t(Map<AppLocale, String> translations) {
    return translations[locale] ?? translations[AppLocale.english] ?? '';
  }

  // Common
  String get cancel => _t({
    AppLocale.japanese: 'キャンセル',
    AppLocale.english: 'Cancel',
    AppLocale.spanish: 'Cancelar',
    AppLocale.chinese: '取消',
    AppLocale.korean: '취소',
    AppLocale.french: 'Annuler',
    AppLocale.german: 'Abbrechen',
    AppLocale.italian: 'Annulla',
  });
  
  String get save => _t({
    AppLocale.japanese: '保存',
    AppLocale.english: 'Save',
    AppLocale.spanish: 'Guardar',
    AppLocale.chinese: '保存',
    AppLocale.korean: '저장',
    AppLocale.french: 'Sauvegarder',
    AppLocale.german: 'Speichern',
    AppLocale.italian: 'Salva',
  });
  
  String get delete => _t({
    AppLocale.japanese: '削除',
    AppLocale.english: 'Delete',
    AppLocale.spanish: 'Eliminar',
    AppLocale.chinese: '删除',
    AppLocale.korean: '삭제',
    AppLocale.french: 'Supprimer',
    AppLocale.german: 'Löschen',
    AppLocale.italian: 'Elimina',
  });
  
  String get edit => _t({
    AppLocale.japanese: '編集',
    AppLocale.english: 'Edit',
    AppLocale.spanish: 'Editar',
    AppLocale.chinese: '编辑',
    AppLocale.korean: '편집',
    AppLocale.french: 'Modifier',
    AppLocale.german: 'Bearbeiten',
    AppLocale.italian: 'Modifica',
  });
  
  String get close => _t({
    AppLocale.japanese: '閉じる',
    AppLocale.english: 'Close',
    AppLocale.spanish: 'Cerrar',
    AppLocale.chinese: '关闭',
    AppLocale.korean: '닫기',
    AppLocale.french: 'Fermer',
    AppLocale.german: 'Schließen',
    AppLocale.italian: 'Chiudi',
  });
  
  String get retry => _t({
    AppLocale.japanese: '再試行',
    AppLocale.english: 'Retry',
    AppLocale.spanish: 'Reintentar',
    AppLocale.chinese: '重试',
    AppLocale.korean: '재시도',
    AppLocale.french: 'Réessayer',
    AppLocale.german: 'Wiederholen',
    AppLocale.italian: 'Riprova',
  });
  
  String get comingSoon => _t({
    AppLocale.japanese: '近日公開',
    AppLocale.english: 'Coming soon!',
    AppLocale.spanish: '¡Próximamente!',
    AppLocale.chinese: '即将推出！',
    AppLocale.korean: '곧 출시!',
    AppLocale.french: 'Bientôt disponible !',
    AppLocale.german: 'Demnächst verfügbar!',
    AppLocale.italian: 'Prossimamente!',
  });

  // Settings
  String get settings => _t({
    AppLocale.japanese: '設定',
    AppLocale.english: 'Settings',
    AppLocale.spanish: 'Configuración',
    AppLocale.chinese: '设置',
    AppLocale.korean: '설정',
    AppLocale.french: 'Paramètres',
    AppLocale.german: 'Einstellungen',
    AppLocale.italian: 'Impostazioni',
  });
  
  String get account => _t({
    AppLocale.japanese: 'アカウント',
    AppLocale.english: 'Account',
    AppLocale.spanish: 'Cuenta',
    AppLocale.chinese: '账户',
    AppLocale.korean: '계정',
    AppLocale.french: 'Compte',
    AppLocale.german: 'Konto',
    AppLocale.italian: 'Account',
  });
  
  String get correctionSettings => _t({
    AppLocale.japanese: '添削設定',
    AppLocale.english: 'Correction Settings',
    AppLocale.spanish: 'Configuración de corrección',
    AppLocale.chinese: '批改设置',
    AppLocale.korean: '첨삭 설정',
    AppLocale.french: 'Paramètres de correction',
    AppLocale.german: 'Korrektur-Einstellungen',
    AppLocale.italian: 'Impostazioni correzione',
  });
  
  String get defaultCorrectionMode => _t({
    AppLocale.japanese: 'デフォルトの添削モード',
    AppLocale.english: 'Default Correction Mode',
    AppLocale.spanish: 'Modo de corrección predeterminado',
    AppLocale.chinese: '默认批改模式',
    AppLocale.korean: '기본 첨삭 모드',
    AppLocale.french: 'Mode de correction par défaut',
    AppLocale.german: 'Standard-Korrekturmodus',
    AppLocale.italian: 'Modalità correzione predefinita',
  });
  
  String get todaysUsage => _t({
    AppLocale.japanese: '今日の使用量',
    AppLocale.english: "Today's Usage",
    AppLocale.spanish: 'Uso de hoy',
    AppLocale.chinese: '今日使用量',
    AppLocale.korean: '오늘 사용량',
    AppLocale.french: "Utilisation d'aujourd'hui",
    AppLocale.german: 'Heutige Nutzung',
    AppLocale.italian: 'Utilizzo di oggi',
  });
  
  String get scansUsed => _t({
    AppLocale.japanese: 'スキャン使用回数',
    AppLocale.english: 'Scans Used',
    AppLocale.spanish: 'Escaneos usados',
    AppLocale.chinese: '扫描使用次数',
    AppLocale.korean: '스캔 사용 횟수',
    AppLocale.french: 'Scans utilisés',
    AppLocale.german: 'Verwendete Scans',
    AppLocale.italian: 'Scansioni usate',
  });
  
  String get correctionsUsed => _t({
    AppLocale.japanese: 'AI添削使用回数',
    AppLocale.english: 'AI Corrections Used',
    AppLocale.spanish: 'Correcciones IA usadas',
    AppLocale.chinese: 'AI批改使用次数',
    AppLocale.korean: 'AI 첨삭 사용 횟수',
    AppLocale.french: 'Corrections IA utilisées',
    AppLocale.german: 'KI-Korrekturen verwendet',
    AppLocale.italian: 'Correzioni IA usate',
  });
  
  String get app => _t({
    AppLocale.japanese: 'アプリ',
    AppLocale.english: 'App',
    AppLocale.spanish: 'Aplicación',
    AppLocale.chinese: '应用',
    AppLocale.korean: '앱',
    AppLocale.french: 'Application',
    AppLocale.german: 'App',
    AppLocale.italian: 'App',
  });
  
  String get darkMode => _t({
    AppLocale.japanese: 'ダークモード',
    AppLocale.english: 'Dark Mode',
    AppLocale.spanish: 'Modo oscuro',
    AppLocale.chinese: '深色模式',
    AppLocale.korean: '다크 모드',
    AppLocale.french: 'Mode sombre',
    AppLocale.german: 'Dunkelmodus',
    AppLocale.italian: 'Modalità scura',
  });
  
  String get followSystem => _t({
    AppLocale.japanese: 'システム設定に従う',
    AppLocale.english: 'Follow system',
    AppLocale.spanish: 'Seguir sistema',
    AppLocale.chinese: '跟随系统',
    AppLocale.korean: '시스템 설정 따르기',
    AppLocale.french: 'Suivre le système',
    AppLocale.german: 'System folgen',
    AppLocale.italian: 'Segui sistema',
  });
  
  String get light => _t({
    AppLocale.japanese: 'ライト',
    AppLocale.english: 'Light',
    AppLocale.spanish: 'Claro',
    AppLocale.chinese: '浅色',
    AppLocale.korean: '라이트',
    AppLocale.french: 'Clair',
    AppLocale.german: 'Hell',
    AppLocale.italian: 'Chiaro',
  });
  
  String get dark => _t({
    AppLocale.japanese: 'ダーク',
    AppLocale.english: 'Dark',
    AppLocale.spanish: 'Oscuro',
    AppLocale.chinese: '深色',
    AppLocale.korean: '다크',
    AppLocale.french: 'Sombre',
    AppLocale.german: 'Dunkel',
    AppLocale.italian: 'Scuro',
  });
  
  String get system => _t({
    AppLocale.japanese: 'システム',
    AppLocale.english: 'System',
    AppLocale.spanish: 'Sistema',
    AppLocale.chinese: '系统',
    AppLocale.korean: '시스템',
    AppLocale.french: 'Système',
    AppLocale.german: 'System',
    AppLocale.italian: 'Sistema',
  });
  
  String get language => _t({
    AppLocale.japanese: '言語',
    AppLocale.english: 'Language',
    AppLocale.spanish: 'Idioma',
    AppLocale.chinese: '语言',
    AppLocale.korean: '언어',
    AppLocale.french: 'Langue',
    AppLocale.german: 'Sprache',
    AppLocale.italian: 'Lingua',
  });
  
  String get about => _t({
    AppLocale.japanese: 'アプリについて',
    AppLocale.english: 'About',
    AppLocale.spanish: 'Acerca de',
    AppLocale.chinese: '关于',
    AppLocale.korean: '정보',
    AppLocale.french: 'À propos',
    AppLocale.german: 'Über',
    AppLocale.italian: 'Info',
  });
  
  String get version => _t({
    AppLocale.japanese: 'バージョン',
    AppLocale.english: 'Version',
    AppLocale.spanish: 'Versión',
    AppLocale.chinese: '版本',
    AppLocale.korean: '버전',
    AppLocale.french: 'Version',
    AppLocale.german: 'Version',
    AppLocale.italian: 'Versione',
  });
  
  String get termsOfService => _t({
    AppLocale.japanese: '利用規約',
    AppLocale.english: 'Terms of Service',
    AppLocale.spanish: 'Términos de servicio',
    AppLocale.chinese: '服务条款',
    AppLocale.korean: '서비스 약관',
    AppLocale.french: "Conditions d'utilisation",
    AppLocale.german: 'Nutzungsbedingungen',
    AppLocale.italian: 'Termini di servizio',
  });
  
  String get privacyPolicy => _t({
    AppLocale.japanese: 'プライバシーポリシー',
    AppLocale.english: 'Privacy Policy',
    AppLocale.spanish: 'Política de privacidad',
    AppLocale.chinese: '隐私政策',
    AppLocale.korean: '개인정보 처리방침',
    AppLocale.french: 'Politique de confidentialité',
    AppLocale.german: 'Datenschutzrichtlinie',
    AppLocale.italian: 'Informativa sulla privacy',
  });
  
  String get logOut => _t({
    AppLocale.japanese: 'ログアウト',
    AppLocale.english: 'Log Out',
    AppLocale.spanish: 'Cerrar sesión',
    AppLocale.chinese: '退出登录',
    AppLocale.korean: '로그아웃',
    AppLocale.french: 'Déconnexion',
    AppLocale.german: 'Abmelden',
    AppLocale.italian: 'Esci',
  });
  
  String get deleteAccount => _t({
    AppLocale.japanese: 'アカウント削除',
    AppLocale.english: 'Delete Account',
    AppLocale.spanish: 'Eliminar cuenta',
    AppLocale.chinese: '删除账户',
    AppLocale.korean: '계정 삭제',
    AppLocale.french: 'Supprimer le compte',
    AppLocale.german: 'Konto löschen',
    AppLocale.italian: 'Elimina account',
  });
  
  String get displayName => _t({
    AppLocale.japanese: '表示名',
    AppLocale.english: 'Display Name',
    AppLocale.spanish: 'Nombre visible',
    AppLocale.chinese: '显示名称',
    AppLocale.korean: '표시 이름',
    AppLocale.french: "Nom d'affichage",
    AppLocale.german: 'Anzeigename',
    AppLocale.italian: 'Nome visualizzato',
  });
  
  String get editDisplayName => _t({
    AppLocale.japanese: '表示名を編集',
    AppLocale.english: 'Edit Display Name',
    AppLocale.spanish: 'Editar nombre visible',
    AppLocale.chinese: '编辑显示名称',
    AppLocale.korean: '표시 이름 편집',
    AppLocale.french: "Modifier le nom d'affichage",
    AppLocale.german: 'Anzeigename bearbeiten',
    AppLocale.italian: 'Modifica nome visualizzato',
  });
  
  String get enterDisplayName => _t({
    AppLocale.japanese: '表示名を入力',
    AppLocale.english: 'Enter your display name',
    AppLocale.spanish: 'Ingrese su nombre visible',
    AppLocale.chinese: '输入您的显示名称',
    AppLocale.korean: '표시 이름을 입력하세요',
    AppLocale.french: "Entrez votre nom d'affichage",
    AppLocale.german: 'Geben Sie Ihren Anzeigenamen ein',
    AppLocale.italian: 'Inserisci il nome visualizzato',
  });
  
  String get upgrade => _t({
    AppLocale.japanese: 'アップグレード',
    AppLocale.english: 'Upgrade',
    AppLocale.spanish: 'Actualizar',
    AppLocale.chinese: '升级',
    AppLocale.korean: '업그레이드',
    AppLocale.french: 'Mettre à niveau',
    AppLocale.german: 'Upgraden',
    AppLocale.italian: 'Aggiorna',
  });
  
  // Correction modes
  String get beginner => _t({
    AppLocale.japanese: '初級',
    AppLocale.english: 'Beginner',
    AppLocale.spanish: 'Principiante',
    AppLocale.chinese: '初级',
    AppLocale.korean: '초급',
    AppLocale.french: 'Débutant',
    AppLocale.german: 'Anfänger',
    AppLocale.italian: 'Principiante',
  });
  
  String get intermediate => _t({
    AppLocale.japanese: '中級',
    AppLocale.english: 'Intermediate',
    AppLocale.spanish: 'Intermedio',
    AppLocale.chinese: '中级',
    AppLocale.korean: '중급',
    AppLocale.french: 'Intermédiaire',
    AppLocale.german: 'Mittelstufe',
    AppLocale.italian: 'Intermedio',
  });
  
  String get advanced => _t({
    AppLocale.japanese: '上級',
    AppLocale.english: 'Advanced',
    AppLocale.spanish: 'Avanzado',
    AppLocale.chinese: '高级',
    AppLocale.korean: '고급',
    AppLocale.french: 'Avancé',
    AppLocale.german: 'Fortgeschritten',
    AppLocale.italian: 'Avanzato',
  });

  // Usage info
  String get freePlanInfo => _t({
    AppLocale.japanese: '無料プランでは1日1回のスキャンと3回のAI添削が可能です。広告を見ると追加で利用できます。プレミアムなら無制限！',
    AppLocale.english: 'Free plan: 1 scan + 3 AI corrections/day. Watch ads for bonus uses. Premium = unlimited!',
    AppLocale.spanish: 'Plan gratis: 1 escaneo + 3 correcciones IA/día. Ver anuncios para usos extra. ¡Premium = ilimitado!',
    AppLocale.chinese: '免费计划：每天1次扫描+3次AI批改。看广告获得额外使用次数。高级版=无限制！',
    AppLocale.korean: '무료 플랜: 하루 1회 스캔 + 3회 AI 첨삭. 광고 시청으로 추가 사용 가능. 프리미엄 = 무제한!',
    AppLocale.french: 'Plan gratuit : 1 scan + 3 corrections IA/jour. Regardez des pubs pour des bonus. Premium = illimité !',
    AppLocale.german: 'Gratis-Plan: 1 Scan + 3 KI-Korrekturen/Tag. Werbung für Bonus ansehen. Premium = unbegrenzt!',
    AppLocale.italian: 'Piano gratuito: 1 scansione + 3 correzioni IA/giorno. Guarda annunci per usi bonus. Premium = illimitato!',
  });

  // Dialogs
  String get logOutConfirm => _t({
    AppLocale.japanese: 'ログアウトしますか？',
    AppLocale.english: 'Are you sure you want to log out?',
    AppLocale.spanish: '¿Seguro que quieres cerrar sesión?',
    AppLocale.chinese: '确定要退出登录吗？',
    AppLocale.korean: '로그아웃하시겠습니까?',
    AppLocale.french: 'Voulez-vous vraiment vous déconnecter ?',
    AppLocale.german: 'Möchten Sie sich wirklich abmelden?',
    AppLocale.italian: 'Sei sicuro di voler uscire?',
  });
  
  String get deleteAccountTitle => _t({
    AppLocale.japanese: 'アカウント削除',
    AppLocale.english: 'Delete Account',
    AppLocale.spanish: 'Eliminar cuenta',
    AppLocale.chinese: '删除账户',
    AppLocale.korean: '계정 삭제',
    AppLocale.french: 'Supprimer le compte',
    AppLocale.german: 'Konto löschen',
    AppLocale.italian: 'Elimina account',
  });
  
  String get deleteAccountConfirm => _t({
    AppLocale.japanese: 'アカウントを削除しますか？この操作は取り消せません。すべての日記とデータが完全に削除されます。',
    AppLocale.english: 'Are you sure you want to delete your account? This action cannot be undone. All your diaries and data will be permanently deleted.',
    AppLocale.spanish: '¿Seguro que quieres eliminar tu cuenta? Esta acción no se puede deshacer. Todos tus diarios y datos se eliminarán permanentemente.',
    AppLocale.chinese: '确定要删除账户吗？此操作无法撤销。您的所有日记和数据将被永久删除。',
    AppLocale.korean: '계정을 삭제하시겠습니까? 이 작업은 취소할 수 없습니다. 모든 일기와 데이터가 영구적으로 삭제됩니다.',
    AppLocale.french: 'Voulez-vous vraiment supprimer votre compte ? Cette action est irréversible. Tous vos journaux et données seront définitivement supprimés.',
    AppLocale.german: 'Möchten Sie Ihr Konto wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden. Alle Ihre Tagebücher und Daten werden dauerhaft gelöscht.',
    AppLocale.italian: 'Sei sicuro di voler eliminare il tuo account? Questa azione non può essere annullata. Tutti i tuoi diari e dati verranno eliminati permanentemente.',
  });

  // Success messages
  String get displayNameUpdated => _t({
    AppLocale.japanese: '表示名を更新しました',
    AppLocale.english: 'Display name updated',
    AppLocale.spanish: 'Nombre visible actualizado',
    AppLocale.chinese: '显示名称已更新',
    AppLocale.korean: '표시 이름이 업데이트되었습니다',
    AppLocale.french: "Nom d'affichage mis à jour",
    AppLocale.german: 'Anzeigename aktualisiert',
    AppLocale.italian: 'Nome visualizzato aggiornato',
  });
  
  String get accountDeleted => _t({
    AppLocale.japanese: 'アカウントを削除しました',
    AppLocale.english: 'Account deleted successfully',
    AppLocale.spanish: 'Cuenta eliminada exitosamente',
    AppLocale.chinese: '账户已成功删除',
    AppLocale.korean: '계정이 성공적으로 삭제되었습니다',
    AppLocale.french: 'Compte supprimé avec succès',
    AppLocale.german: 'Konto erfolgreich gelöscht',
    AppLocale.italian: 'Account eliminato con successo',
  });
  
  // Error messages
  String get updateFailed => _t({
    AppLocale.japanese: '更新に失敗しました',
    AppLocale.english: 'Failed to update',
    AppLocale.spanish: 'Error al actualizar',
    AppLocale.chinese: '更新失败',
    AppLocale.korean: '업데이트 실패',
    AppLocale.french: 'Échec de la mise à jour',
    AppLocale.german: 'Aktualisierung fehlgeschlagen',
    AppLocale.italian: 'Aggiornamento fallito',
  });
  
  String get deleteFailed => _t({
    AppLocale.japanese: 'アカウントの削除に失敗しました',
    AppLocale.english: 'Failed to delete account',
    AppLocale.spanish: 'Error al eliminar cuenta',
    AppLocale.chinese: '删除账户失败',
    AppLocale.korean: '계정 삭제 실패',
    AppLocale.french: 'Échec de la suppression du compte',
    AppLocale.german: 'Konto konnte nicht gelöscht werden',
    AppLocale.italian: 'Eliminazione account fallita',
  });
  
  String get loadingError => _t({
    AppLocale.japanese: '読み込みエラー',
    AppLocale.english: 'Error loading',
    AppLocale.spanish: 'Error de carga',
    AppLocale.chinese: '加载错误',
    AppLocale.korean: '로딩 오류',
    AppLocale.french: 'Erreur de chargement',
    AppLocale.german: 'Ladefehler',
    AppLocale.italian: 'Errore di caricamento',
  });
  
  String get tapToRetry => _t({
    AppLocale.japanese: 'タップして再試行',
    AppLocale.english: 'Tap to retry',
    AppLocale.spanish: 'Toca para reintentar',
    AppLocale.chinese: '点击重试',
    AppLocale.korean: '탭하여 재시도',
    AppLocale.french: 'Appuyez pour réessayer',
    AppLocale.german: 'Zum Wiederholen tippen',
    AppLocale.italian: 'Tocca per riprovare',
  });
  
  // Loading states
  String get loading => _t({
    AppLocale.japanese: '読み込み中...',
    AppLocale.english: 'Loading...',
    AppLocale.spanish: 'Cargando...',
    AppLocale.chinese: '加载中...',
    AppLocale.korean: '로딩 중...',
    AppLocale.french: 'Chargement...',
    AppLocale.german: 'Laden...',
    AppLocale.italian: 'Caricamento...',
  });
  
  String get deleting => _t({
    AppLocale.japanese: '削除中...',
    AppLocale.english: 'Deleting...',
    AppLocale.spanish: 'Eliminando...',
    AppLocale.chinese: '删除中...',
    AppLocale.korean: '삭제 중...',
    AppLocale.french: 'Suppression...',
    AppLocale.german: 'Löschen...',
    AppLocale.italian: 'Eliminazione...',
  });
  
  // Theme dialog
  String get selectTheme => _t({
    AppLocale.japanese: 'テーマを選択',
    AppLocale.english: 'Select Theme',
    AppLocale.spanish: 'Seleccionar tema',
    AppLocale.chinese: '选择主题',
    AppLocale.korean: '테마 선택',
    AppLocale.french: 'Sélectionner le thème',
    AppLocale.german: 'Design auswählen',
    AppLocale.italian: 'Seleziona tema',
  });
  
  String get lightMode => _t({
    AppLocale.japanese: 'ライトモード',
    AppLocale.english: 'Light Mode',
    AppLocale.spanish: 'Modo claro',
    AppLocale.chinese: '浅色模式',
    AppLocale.korean: '라이트 모드',
    AppLocale.french: 'Mode clair',
    AppLocale.german: 'Hellmodus',
    AppLocale.italian: 'Modalità chiara',
  });
  
  String get darkModeOption => _t({
    AppLocale.japanese: 'ダークモード',
    AppLocale.english: 'Dark Mode',
    AppLocale.spanish: 'Modo oscuro',
    AppLocale.chinese: '深色模式',
    AppLocale.korean: '다크 모드',
    AppLocale.french: 'Mode sombre',
    AppLocale.german: 'Dunkelmodus',
    AppLocale.italian: 'Modalità scura',
  });
  
  String get systemDefault => _t({
    AppLocale.japanese: 'システム設定に従う',
    AppLocale.english: 'Follow System',
    AppLocale.spanish: 'Seguir sistema',
    AppLocale.chinese: '跟随系统',
    AppLocale.korean: '시스템 설정 따르기',
    AppLocale.french: 'Suivre le système',
    AppLocale.german: 'System folgen',
    AppLocale.italian: 'Segui sistema',
  });
  
  // Language dialog
  String get selectLanguage => _t({
    AppLocale.japanese: '言語を選択',
    AppLocale.english: 'Select Language',
    AppLocale.spanish: 'Seleccionar idioma',
    AppLocale.chinese: '选择语言',
    AppLocale.korean: '언어 선택',
    AppLocale.french: 'Sélectionner la langue',
    AppLocale.german: 'Sprache auswählen',
    AppLocale.italian: 'Seleziona lingua',
  });
  
  // Correction mode dialog
  String get selectCorrectionMode => _t({
    AppLocale.japanese: '添削モードを選択',
    AppLocale.english: 'Select Correction Mode',
    AppLocale.spanish: 'Seleccionar modo de corrección',
    AppLocale.chinese: '选择批改模式',
    AppLocale.korean: '첨삭 모드 선택',
    AppLocale.french: 'Sélectionner le mode de correction',
    AppLocale.german: 'Korrekturmodus auswählen',
    AppLocale.italian: 'Seleziona modalità correzione',
  });
  
  // Plan
  String get freePlan => _t({
    AppLocale.japanese: '無料プラン',
    AppLocale.english: 'Free Plan',
    AppLocale.spanish: 'Plan gratis',
    AppLocale.chinese: '免费计划',
    AppLocale.korean: '무료 플랜',
    AppLocale.french: 'Plan gratuit',
    AppLocale.german: 'Gratis-Plan',
    AppLocale.italian: 'Piano gratuito',
  });
  
  String get plan => _t({
    AppLocale.japanese: 'プラン',
    AppLocale.english: 'Plan',
    AppLocale.spanish: 'Plan',
    AppLocale.chinese: '计划',
    AppLocale.korean: '플랜',
    AppLocale.french: 'Plan',
    AppLocale.german: 'Plan',
    AppLocale.italian: 'Piano',
  });
  
  String get noLimit => _t({
    AppLocale.japanese: '無制限',
    AppLocale.english: 'NO LIMIT',
    AppLocale.spanish: 'SIN LÍMITE',
    AppLocale.chinese: '无限制',
    AppLocale.korean: '무제한',
    AppLocale.french: 'ILLIMITÉ',
    AppLocale.german: 'UNBEGRENZT',
    AppLocale.italian: 'ILLIMITATO',
  });

  // Premium Plan
  String get premiumPlan => _t({
    AppLocale.japanese: 'プレミアムプラン',
    AppLocale.english: 'Premium Plan',
    AppLocale.spanish: 'Plan Premium',
    AppLocale.chinese: '高级计划',
    AppLocale.korean: '프리미엄 플랜',
    AppLocale.french: 'Plan Premium',
    AppLocale.german: 'Premium-Plan',
    AppLocale.italian: 'Piano Premium',
  });

  String get premiumLabel => _t({
    AppLocale.japanese: 'プレミアム',
    AppLocale.english: 'Premium',
    AppLocale.spanish: 'Premium',
    AppLocale.chinese: '高级',
    AppLocale.korean: '프리미엄',
    AppLocale.french: 'Premium',
    AppLocale.german: 'Premium',
    AppLocale.italian: 'Premium',
  });

  String get premiumBenefits => _t({
    AppLocale.japanese: 'プレミアム特典',
    AppLocale.english: 'Premium Benefits',
    AppLocale.spanish: 'Beneficios Premium',
    AppLocale.chinese: '高级特权',
    AppLocale.korean: '프리미엄 혜택',
    AppLocale.french: 'Avantages Premium',
    AppLocale.german: 'Premium-Vorteile',
    AppLocale.italian: 'Vantaggi Premium',
  });

  String get unlimitedCorrections => _t({
    AppLocale.japanese: '無制限のAI添削',
    AppLocale.english: 'Unlimited AI Corrections',
    AppLocale.spanish: 'Correcciones IA ilimitadas',
    AppLocale.chinese: '无限AI批改',
    AppLocale.korean: '무제한 AI 첨삭',
    AppLocale.french: 'Corrections IA illimitées',
    AppLocale.german: 'Unbegrenzte KI-Korrekturen',
    AppLocale.italian: 'Correzioni IA illimitate',
  });

  String get unlimitedCorrectionsDesc => _t({
    AppLocale.japanese: '1日の添削回数制限なし',
    AppLocale.english: 'No daily correction limit',
    AppLocale.spanish: 'Sin límite diario de correcciones',
    AppLocale.chinese: '每日批改无数量限制',
    AppLocale.korean: '일일 첨삭 횟수 제한 없음',
    AppLocale.french: 'Pas de limite de corrections quotidiennes',
    AppLocale.german: 'Kein tägliches Korrekturlimit',
    AppLocale.italian: 'Nessun limite giornaliero di correzioni',
  });

  String get unlimitedScans => _t({
    AppLocale.japanese: '無制限のスキャン',
    AppLocale.english: 'Unlimited Scans',
    AppLocale.spanish: 'Escaneos ilimitados',
    AppLocale.chinese: '无限扫描',
    AppLocale.korean: '무제한 스캔',
    AppLocale.french: 'Scans illimités',
    AppLocale.german: 'Unbegrenzte Scans',
    AppLocale.italian: 'Scansioni illimitate',
  });

  String get unlimitedScansDesc => _t({
    AppLocale.japanese: '1日のスキャン回数制限なし',
    AppLocale.english: 'No daily scan limit',
    AppLocale.spanish: 'Sin límite diario de escaneos',
    AppLocale.chinese: '每日扫描无数量限制',
    AppLocale.korean: '일일 스캔 횟수 제한 없음',
    AppLocale.french: 'Pas de limite de scans quotidiens',
    AppLocale.german: 'Kein tägliches Scanlimit',
    AppLocale.italian: 'Nessun limite giornaliero di scansioni',
  });

  String get noAds => _t({
    AppLocale.japanese: '広告なし',
    AppLocale.english: 'No Ads',
    AppLocale.spanish: 'Sin anuncios',
    AppLocale.chinese: '无广告',
    AppLocale.korean: '광고 없음',
    AppLocale.french: 'Sans publicité',
    AppLocale.german: 'Keine Werbung',
    AppLocale.italian: 'Senza pubblicità',
  });

  String get noAdsDesc => _t({
    AppLocale.japanese: '広告表示なしの快適な体験',
    AppLocale.english: 'Enjoy an ad-free experience',
    AppLocale.spanish: 'Disfruta de una experiencia sin anuncios',
    AppLocale.chinese: '享受无广告体验',
    AppLocale.korean: '광고 없는 쾌적한 경험',
    AppLocale.french: "Profitez d'une expérience sans publicité",
    AppLocale.german: 'Genießen Sie ein werbefreies Erlebnis',
    AppLocale.italian: "Goditi un'esperienza senza pubblicità",
  });

  String get subscribePremium => _t({
    AppLocale.japanese: 'プレミアムに登録',
    AppLocale.english: 'Subscribe to Premium',
    AppLocale.spanish: 'Suscribirse a Premium',
    AppLocale.chinese: '订阅高级版',
    AppLocale.korean: '프리미엄 구독',
    AppLocale.french: "S'abonner à Premium",
    AppLocale.german: 'Premium abonnieren',
    AppLocale.italian: 'Abbonati a Premium',
  });

  String get restorePurchases => _t({
    AppLocale.japanese: '購入を復元',
    AppLocale.english: 'Restore Purchases',
    AppLocale.spanish: 'Restaurar compras',
    AppLocale.chinese: '恢复购买',
    AppLocale.korean: '구매 복원',
    AppLocale.french: 'Restaurer les achats',
    AppLocale.german: 'Käufe wiederherstellen',
    AppLocale.italian: 'Ripristina acquisti',
  });

  String get restoreCompleted => _t({
    AppLocale.japanese: '購入の復元が完了しました',
    AppLocale.english: 'Purchases restored successfully',
    AppLocale.spanish: 'Compras restauradas con éxito',
    AppLocale.chinese: '购买恢复成功',
    AppLocale.korean: '구매 복원이 완료되었습니다',
    AppLocale.french: 'Achats restaurés avec succès',
    AppLocale.german: 'Käufe erfolgreich wiederhergestellt',
    AppLocale.italian: 'Acquisti ripristinati con successo',
  });

  String get alreadyPremium => _t({
    AppLocale.japanese: 'プレミアム会員です',
    AppLocale.english: "You're a Premium member",
    AppLocale.spanish: 'Eres miembro Premium',
    AppLocale.chinese: '您是高级会员',
    AppLocale.korean: '프리미엄 회원입니다',
    AppLocale.french: 'Vous êtes membre Premium',
    AppLocale.german: 'Sie sind Premium-Mitglied',
    AppLocale.italian: 'Sei un membro Premium',
  });

  String get planComparison => _t({
    AppLocale.japanese: 'プラン比較',
    AppLocale.english: 'Plan Comparison',
    AppLocale.spanish: 'Comparación de planes',
    AppLocale.chinese: '计划对比',
    AppLocale.korean: '플랜 비교',
    AppLocale.french: 'Comparaison des plans',
    AppLocale.german: 'Planvergleich',
    AppLocale.italian: 'Confronto piani',
  });

  String get correctionsLabel => _t({
    AppLocale.japanese: 'AI添削',
    AppLocale.english: 'Corrections',
    AppLocale.spanish: 'Correcciones',
    AppLocale.chinese: '批改',
    AppLocale.korean: '첨삭',
    AppLocale.french: 'Corrections',
    AppLocale.german: 'Korrekturen',
    AppLocale.italian: 'Correzioni',
  });

  String get scans => _t({
    AppLocale.japanese: 'スキャン',
    AppLocale.english: 'Scans',
    AppLocale.spanish: 'Escaneos',
    AppLocale.chinese: '扫描',
    AppLocale.korean: '스캔',
    AppLocale.french: 'Scans',
    AppLocale.german: 'Scans',
    AppLocale.italian: 'Scansioni',
  });

  String get ads => _t({
    AppLocale.japanese: '広告',
    AppLocale.english: 'Ads',
    AppLocale.spanish: 'Anuncios',
    AppLocale.chinese: '广告',
    AppLocale.korean: '광고',
    AppLocale.french: 'Publicités',
    AppLocale.german: 'Werbung',
    AppLocale.italian: 'Pubblicità',
  });

  String get yes => _t({
    AppLocale.japanese: 'あり',
    AppLocale.english: 'Yes',
    AppLocale.spanish: 'Sí',
    AppLocale.chinese: '有',
    AppLocale.korean: '있음',
    AppLocale.french: 'Oui',
    AppLocale.german: 'Ja',
    AppLocale.italian: 'Sì',
  });

  String get no => _t({
    AppLocale.japanese: 'なし',
    AppLocale.english: 'No',
    AppLocale.spanish: 'No',
    AppLocale.chinese: '无',
    AppLocale.korean: '없음',
    AppLocale.french: 'Non',
    AppLocale.german: 'Nein',
    AppLocale.italian: 'No',
  });

  String get month => _t({
    AppLocale.japanese: '月',
    AppLocale.english: 'month',
    AppLocale.spanish: 'mes',
    AppLocale.chinese: '月',
    AppLocale.korean: '월',
    AppLocale.french: 'mois',
    AppLocale.german: 'Monat',
    AppLocale.italian: 'mese',
  });

  String get day => _t({
    AppLocale.japanese: '日',
    AppLocale.english: 'day',
    AppLocale.spanish: 'día',
    AppLocale.chinese: '天',
    AppLocale.korean: '일',
    AppLocale.french: 'jour',
    AppLocale.german: 'Tag',
    AppLocale.italian: 'giorno',
  });

  String get subscriptionTerms => _t({
    AppLocale.japanese: 'サブスクリプションは自動更新されます。次の請求日の24時間前までにキャンセルしない限り、自動的に更新されます。設定アプリからいつでもキャンセルできます。',
    AppLocale.english: 'Subscription auto-renews. Cancel at least 24 hours before the next billing date. You can cancel anytime in Settings.',
    AppLocale.spanish: 'La suscripción se renueva automáticamente. Cancela al menos 24 horas antes de la próxima fecha de facturación. Puedes cancelar en cualquier momento en Configuración.',
    AppLocale.chinese: '订阅自动续订。请在下一个计费日期前至少24小时取消。您可以随时在设置中取消。',
    AppLocale.korean: '구독은 자동 갱신됩니다. 다음 결제일 24시간 전에 취소하세요. 설정에서 언제든지 취소할 수 있습니다.',
    AppLocale.french: "L'abonnement se renouvelle automatiquement. Annulez au moins 24 heures avant la prochaine date de facturation. Vous pouvez annuler à tout moment dans les Réglages.",
    AppLocale.german: 'Das Abo verlängert sich automatisch. Kündigen Sie mindestens 24 Stunden vor dem nächsten Abrechnungsdatum. Sie können jederzeit in den Einstellungen kündigen.',
    AppLocale.italian: "L'abbonamento si rinnova automaticamente. Annulla almeno 24 ore prima della prossima data di fatturazione. Puoi annullare in qualsiasi momento nelle Impostazioni.",
  });

  String get choosePlan => _t({
    AppLocale.japanese: 'プランを選択',
    AppLocale.english: 'Choose Your Plan',
    AppLocale.spanish: 'Elige tu plan',
    AppLocale.chinese: '选择您的计划',
    AppLocale.korean: '플랜 선택',
    AppLocale.french: 'Choisissez votre plan',
    AppLocale.german: 'Wählen Sie Ihren Plan',
    AppLocale.italian: 'Scegli il tuo piano',
  });

  String get yearlyPlan => _t({
    AppLocale.japanese: '年間プラン',
    AppLocale.english: 'Yearly',
    AppLocale.spanish: 'Anual',
    AppLocale.chinese: '年度计划',
    AppLocale.korean: '연간 플랜',
    AppLocale.french: 'Annuel',
    AppLocale.german: 'Jährlich',
    AppLocale.italian: 'Annuale',
  });

  String get monthlyPlan => _t({
    AppLocale.japanese: '月額プラン',
    AppLocale.english: 'Monthly',
    AppLocale.spanish: 'Mensual',
    AppLocale.chinese: '月度计划',
    AppLocale.korean: '월간 플랜',
    AppLocale.french: 'Mensuel',
    AppLocale.german: 'Monatlich',
    AppLocale.italian: 'Mensile',
  });

  String get save50 => _t({
    AppLocale.japanese: '50%お得',
    AppLocale.english: 'Save 50%',
    AppLocale.spanish: 'Ahorra 50%',
    AppLocale.chinese: '节省50%',
    AppLocale.korean: '50% 할인',
    AppLocale.french: '-50%',
    AppLocale.german: '50% sparen',
    AppLocale.italian: 'Risparmia 50%',
  });
  
  // Diary Detail Screen
  String get originalDiary => _t({
    AppLocale.japanese: '元の日記',
    AppLocale.english: 'Original Diary',
    AppLocale.spanish: 'Diario original',
    AppLocale.chinese: '原始日记',
    AppLocale.korean: '원본 일기',
    AppLocale.french: 'Journal original',
    AppLocale.german: 'Originaltagebuch',
    AppLocale.italian: 'Diario originale',
  });
  
  String get aiCorrection => _t({
    AppLocale.japanese: 'AI添削',
    AppLocale.english: 'AI Correction',
    AppLocale.spanish: 'Corrección IA',
    AppLocale.chinese: 'AI批改',
    AppLocale.korean: 'AI 첨삭',
    AppLocale.french: 'Correction IA',
    AppLocale.german: 'KI-Korrektur',
    AppLocale.italian: 'Correzione IA',
  });
  
  String get correcting => _t({
    AppLocale.japanese: '添削中...',
    AppLocale.english: 'Correcting...',
    AppLocale.spanish: 'Corrigiendo...',
    AppLocale.chinese: '批改中...',
    AppLocale.korean: '첨삭 중...',
    AppLocale.french: 'Correction en cours...',
    AppLocale.german: 'Korrigieren...',
    AppLocale.italian: 'Correzione in corso...',
  });
  
  String get reCorrect => _t({
    AppLocale.japanese: '再添削する',
    AppLocale.english: 'Re-correct',
    AppLocale.spanish: 'Re-corregir',
    AppLocale.chinese: '重新批改',
    AppLocale.korean: '다시 첨삭',
    AppLocale.french: 'Re-corriger',
    AppLocale.german: 'Erneut korrigieren',
    AppLocale.italian: 'Ri-correggi',
  });
  
  String get runAiCorrection => _t({
    AppLocale.japanese: 'AI添削を実行',
    AppLocale.english: 'Run AI Correction',
    AppLocale.spanish: 'Ejecutar corrección IA',
    AppLocale.chinese: '运行AI批改',
    AppLocale.korean: 'AI 첨삭 실행',
    AppLocale.french: 'Exécuter la correction IA',
    AppLocale.german: 'KI-Korrektur ausführen',
    AppLocale.italian: 'Esegui correzione IA',
  });
  
  String get corrected => _t({
    AppLocale.japanese: '添削後',
    AppLocale.english: 'Corrected',
    AppLocale.spanish: 'Corregido',
    AppLocale.chinese: '批改后',
    AppLocale.korean: '첨삭 후',
    AppLocale.french: 'Corrigé',
    AppLocale.german: 'Korrigiert',
    AppLocale.italian: 'Corretto',
  });
  
  String corrections(int count) => _t({
    AppLocale.japanese: '修正点 ($count件)',
    AppLocale.english: 'Corrections ($count)',
    AppLocale.spanish: 'Correcciones ($count)',
    AppLocale.chinese: '修正 ($count处)',
    AppLocale.korean: '수정사항 ($count개)',
    AppLocale.french: 'Corrections ($count)',
    AppLocale.german: 'Korrekturen ($count)',
    AppLocale.italian: 'Correzioni ($count)',
  });
  
  String get addToReviewCards => _t({
    AppLocale.japanese: '復習カードに追加',
    AppLocale.english: 'Add to Review Cards',
    AppLocale.spanish: 'Agregar a tarjetas de repaso',
    AppLocale.chinese: '添加到复习卡',
    AppLocale.korean: '복습 카드에 추가',
    AppLocale.french: 'Ajouter aux cartes de révision',
    AppLocale.german: 'Zu Lernkarten hinzufügen',
    AppLocale.italian: 'Aggiungi alle schede di ripasso',
  });
  
  String addToCards(int count) => _t({
    AppLocale.japanese: '$count件をカードに追加',
    AppLocale.english: 'Add $count to Cards',
    AppLocale.spanish: 'Agregar $count a tarjetas',
    AppLocale.chinese: '添加$count张到卡片',
    AppLocale.korean: '$count개를 카드에 추가',
    AppLocale.french: 'Ajouter $count aux cartes',
    AppLocale.german: '$count zu Karten hinzufügen',
    AppLocale.italian: 'Aggiungi $count alle schede',
  });
  
  String get creating => _t({
    AppLocale.japanese: '作成中...',
    AppLocale.english: 'Creating...',
    AppLocale.spanish: 'Creando...',
    AppLocale.chinese: '创建中...',
    AppLocale.korean: '생성 중...',
    AppLocale.french: 'Création...',
    AppLocale.german: 'Erstellen...',
    AppLocale.italian: 'Creazione...',
  });
  
  String get selectCorrectionsHint => _t({
    AppLocale.japanese: '復習カードに追加する修正を選択してください',
    AppLocale.english: 'Select corrections to add to review cards',
    AppLocale.spanish: 'Selecciona correcciones para agregar a las tarjetas de repaso',
    AppLocale.chinese: '选择要添加到复习卡的修正',
    AppLocale.korean: '복습 카드에 추가할 수정사항을 선택하세요',
    AppLocale.french: 'Sélectionnez les corrections à ajouter aux cartes de révision',
    AppLocale.german: 'Wählen Sie Korrekturen für Lernkarten aus',
    AppLocale.italian: 'Seleziona correzioni da aggiungere alle schede di ripasso',
  });
  
  String get correctionComplete => _t({
    AppLocale.japanese: '添削完了！',
    AppLocale.english: 'Correction complete!',
    AppLocale.spanish: '¡Corrección completada!',
    AppLocale.chinese: '批改完成！',
    AppLocale.korean: '첨삭 완료!',
    AppLocale.french: 'Correction terminée !',
    AppLocale.german: 'Korrektur abgeschlossen!',
    AppLocale.italian: 'Correzione completata!',
  });
  
  String cardsCreated(int count) => _t({
    AppLocale.japanese: '$count件のカードを作成しました',
    AppLocale.english: 'Created $count cards',
    AppLocale.spanish: 'Se crearon $count tarjetas',
    AppLocale.chinese: '已创建$count张卡片',
    AppLocale.korean: '$count개의 카드가 생성되었습니다',
    AppLocale.french: '$count cartes créées',
    AppLocale.german: '$count Karten erstellt',
    AppLocale.italian: 'Create $count schede',
  });
  
  String get noSelectionsError => _t({
    AppLocale.japanese: '追加する修正を選択してください',
    AppLocale.english: 'Please select corrections to add',
    AppLocale.spanish: 'Por favor selecciona correcciones para agregar',
    AppLocale.chinese: '请选择要添加的修正',
    AppLocale.korean: '추가할 수정사항을 선택하세요',
    AppLocale.french: 'Veuillez sélectionner des corrections à ajouter',
    AppLocale.german: 'Bitte wählen Sie Korrekturen zum Hinzufügen aus',
    AppLocale.italian: 'Seleziona le correzioni da aggiungere',
  });
  
  String get diaryDeleted => _t({
    AppLocale.japanese: '日記を削除しました',
    AppLocale.english: 'Diary deleted',
    AppLocale.spanish: 'Diario eliminado',
    AppLocale.chinese: '日记已删除',
    AppLocale.korean: '일기가 삭제되었습니다',
    AppLocale.french: 'Journal supprimé',
    AppLocale.german: 'Tagebuch gelöscht',
    AppLocale.italian: 'Diario eliminato',
  });
  
  String get deleteFailed2 => _t({
    AppLocale.japanese: '削除に失敗しました',
    AppLocale.english: 'Failed to delete',
    AppLocale.spanish: 'Error al eliminar',
    AppLocale.chinese: '删除失败',
    AppLocale.korean: '삭제 실패',
    AppLocale.french: 'Échec de la suppression',
    AppLocale.german: 'Löschen fehlgeschlagen',
    AppLocale.italian: 'Eliminazione fallita',
  });
  
  String get correctionFailed => _t({
    AppLocale.japanese: '添削に失敗しました',
    AppLocale.english: 'Correction failed',
    AppLocale.spanish: 'Error en la corrección',
    AppLocale.chinese: '批改失败',
    AppLocale.korean: '첨삭 실패',
    AppLocale.french: 'Échec de la correction',
    AppLocale.german: 'Korrektur fehlgeschlagen',
    AppLocale.italian: 'Correzione fallita',
  });
  
  String get cardCreationFailed => _t({
    AppLocale.japanese: 'カードの作成に失敗しました',
    AppLocale.english: 'Failed to create cards',
    AppLocale.spanish: 'Error al crear tarjetas',
    AppLocale.chinese: '创建卡片失败',
    AppLocale.korean: '카드 생성 실패',
    AppLocale.french: 'Échec de la création des cartes',
    AppLocale.german: 'Kartenerstellung fehlgeschlagen',
    AppLocale.italian: 'Creazione schede fallita',
  });
  
  String get deleteDiaryTitle => _t({
    AppLocale.japanese: '日記を削除',
    AppLocale.english: 'Delete Diary',
    AppLocale.spanish: 'Eliminar diario',
    AppLocale.chinese: '删除日记',
    AppLocale.korean: '일기 삭제',
    AppLocale.french: 'Supprimer le journal',
    AppLocale.german: 'Tagebuch löschen',
    AppLocale.italian: 'Elimina diario',
  });
  
  String get deleteDiaryConfirm => _t({
    AppLocale.japanese: 'この日記を削除してもよろしいですか？',
    AppLocale.english: 'Are you sure you want to delete this diary?',
    AppLocale.spanish: '¿Seguro que quieres eliminar este diario?',
    AppLocale.chinese: '确定要删除这篇日记吗？',
    AppLocale.korean: '이 일기를 삭제하시겠습니까?',
    AppLocale.french: 'Voulez-vous vraiment supprimer ce journal ?',
    AppLocale.german: 'Möchten Sie dieses Tagebuch wirklich löschen?',
    AppLocale.italian: 'Sei sicuro di voler eliminare questo diario?',
  });
  
  // Correction mode descriptions
  String get beginnerDesc => _t({
    AppLocale.japanese: '基本的な文法、スペル、冠詞の欠落に注目します。',
    AppLocale.english: 'Focuses on basic grammar, spelling, and missing articles.',
    AppLocale.spanish: 'Se enfoca en gramática básica, ortografía y artículos faltantes.',
    AppLocale.chinese: '专注于基本语法、拼写和遗漏的冠词。',
    AppLocale.korean: '기본 문법, 철자, 누락된 관사에 집중합니다.',
    AppLocale.french: 'Se concentre sur la grammaire de base, l\'orthographe et les articles manquants.',
    AppLocale.german: 'Konzentriert sich auf grundlegende Grammatik, Rechtschreibung und fehlende Artikel.',
    AppLocale.italian: 'Si concentra su grammatica base, ortografia e articoli mancanti.',
  });
  
  String get intermediateDesc => _t({
    AppLocale.japanese: '語彙の改善や自然な言い回しも含めて添削します。',
    AppLocale.english: 'Includes vocabulary improvements and natural expressions.',
    AppLocale.spanish: 'Incluye mejoras de vocabulario y expresiones naturales.',
    AppLocale.chinese: '包括词汇改进和自然表达。',
    AppLocale.korean: '어휘 개선과 자연스러운 표현을 포함합니다.',
    AppLocale.french: 'Inclut des améliorations de vocabulaire et des expressions naturelles.',
    AppLocale.german: 'Enthält Vokabelverbesserungen und natürliche Ausdrücke.',
    AppLocale.italian: 'Include miglioramenti del vocabolario ed espressioni naturali.',
  });
  
  String get advancedDesc => _t({
    AppLocale.japanese: 'スタイルやイディオムを含む包括的な添削を行います。',
    AppLocale.english: 'Comprehensive correction including style and idioms.',
    AppLocale.spanish: 'Corrección integral incluyendo estilo y modismos.',
    AppLocale.chinese: '包括风格和习语的全面批改。',
    AppLocale.korean: '스타일과 관용구를 포함한 포괄적인 첨삭을 합니다.',
    AppLocale.french: 'Correction complète incluant le style et les expressions idiomatiques.',
    AppLocale.german: 'Umfassende Korrektur einschließlich Stil und Redewendungen.',
    AppLocale.italian: 'Correzione completa che include stile e modi di dire.',
  });

  // Learning language settings
  String get learningLanguageSettings => _t({
    AppLocale.japanese: '学習言語設定',
    AppLocale.english: 'Learning Language',
    AppLocale.spanish: 'Idioma de aprendizaje',
    AppLocale.chinese: '学习语言设置',
    AppLocale.korean: '학습 언어 설정',
    AppLocale.french: "Langue d'apprentissage",
    AppLocale.german: 'Lernsprache',
    AppLocale.italian: 'Lingua di apprendimento',
  });
  
  String get targetLanguage => _t({
    AppLocale.japanese: '学習中の言語',
    AppLocale.english: 'Language You Are Learning',
    AppLocale.spanish: 'Idioma que estás aprendiendo',
    AppLocale.chinese: '正在学习的语言',
    AppLocale.korean: '학습 중인 언어',
    AppLocale.french: 'Langue que vous apprenez',
    AppLocale.german: 'Sprache, die Sie lernen',
    AppLocale.italian: 'Lingua che stai imparando',
  });
  
  String get nativeLanguage => _t({
    AppLocale.japanese: 'あなたの母国語',
    AppLocale.english: 'Your Native Language',
    AppLocale.spanish: 'Tu idioma nativo',
    AppLocale.chinese: '您的母语',
    AppLocale.korean: '모국어',
    AppLocale.french: 'Votre langue maternelle',
    AppLocale.german: 'Ihre Muttersprache',
    AppLocale.italian: 'La tua lingua madre',
  });
  
  String get selectTargetLanguage => _t({
    AppLocale.japanese: '学習中の言語を選択',
    AppLocale.english: 'Select Target Language',
    AppLocale.spanish: 'Seleccionar idioma objetivo',
    AppLocale.chinese: '选择目标语言',
    AppLocale.korean: '목표 언어 선택',
    AppLocale.french: 'Sélectionner la langue cible',
    AppLocale.german: 'Zielsprache auswählen',
    AppLocale.italian: 'Seleziona lingua di destinazione',
  });
  
  String get selectNativeLanguage => _t({
    AppLocale.japanese: '母国語を選択',
    AppLocale.english: 'Select Native Language',
    AppLocale.spanish: 'Seleccionar idioma nativo',
    AppLocale.chinese: '选择母语',
    AppLocale.korean: '모국어 선택',
    AppLocale.french: 'Sélectionner la langue maternelle',
    AppLocale.german: 'Muttersprache auswählen',
    AppLocale.italian: 'Seleziona lingua madre',
  });
  
  String get languageSettingsUpdated => _t({
    AppLocale.japanese: '言語設定を更新しました',
    AppLocale.english: 'Language settings updated',
    AppLocale.spanish: 'Configuración de idioma actualizada',
    AppLocale.chinese: '语言设置已更新',
    AppLocale.korean: '언어 설정이 업데이트되었습니다',
    AppLocale.french: 'Paramètres de langue mis à jour',
    AppLocale.german: 'Spracheinstellungen aktualisiert',
    AppLocale.italian: 'Impostazioni lingua aggiornate',
  });
  
  String get targetLanguageDesc => _t({
    AppLocale.japanese: 'AI添削はこの言語で日記を添削します',
    AppLocale.english: 'AI will correct your diary in this language',
    AppLocale.spanish: 'La IA corregirá tu diario en este idioma',
    AppLocale.chinese: 'AI将用此语言批改您的日记',
    AppLocale.korean: 'AI가 이 언어로 일기를 첨삭합니다',
    AppLocale.french: "L'IA corrigera votre journal dans cette langue",
    AppLocale.german: 'KI korrigiert Ihr Tagebuch in dieser Sprache',
    AppLocale.italian: "L'IA correggerà il tuo diario in questa lingua",
  });
  
  String get nativeLanguageDesc => _t({
    AppLocale.japanese: 'AI添削の説明文がこの言語で表示されます',
    AppLocale.english: 'AI explanations will be shown in this language',
    AppLocale.spanish: 'Las explicaciones de la IA se mostrarán en este idioma',
    AppLocale.chinese: 'AI说明将以此语言显示',
    AppLocale.korean: 'AI 설명이 이 언어로 표시됩니다',
    AppLocale.french: 'Les explications de l\'IA seront affichées dans cette langue',
    AppLocale.german: 'KI-Erklärungen werden in dieser Sprache angezeigt',
    AppLocale.italian: 'Le spiegazioni dell\'IA verranno mostrate in questa lingua',
  });
  
  // Language names
  String getLanguageName(String code) {
    final names = {
      'english': _t({
        AppLocale.japanese: '英語',
        AppLocale.english: 'English',
        AppLocale.spanish: 'Inglés',
        AppLocale.chinese: '英语',
        AppLocale.korean: '영어',
        AppLocale.french: 'Anglais',
        AppLocale.german: 'Englisch',
        AppLocale.italian: 'Inglese',
      }),
      'spanish': _t({
        AppLocale.japanese: 'スペイン語',
        AppLocale.english: 'Spanish',
        AppLocale.spanish: 'Español',
        AppLocale.chinese: '西班牙语',
        AppLocale.korean: '스페인어',
        AppLocale.french: 'Espagnol',
        AppLocale.german: 'Spanisch',
        AppLocale.italian: 'Spagnolo',
      }),
      'chinese': _t({
        AppLocale.japanese: '中国語',
        AppLocale.english: 'Chinese',
        AppLocale.spanish: 'Chino',
        AppLocale.chinese: '中文',
        AppLocale.korean: '중국어',
        AppLocale.french: 'Chinois',
        AppLocale.german: 'Chinesisch',
        AppLocale.italian: 'Cinese',
      }),
      'japanese': _t({
        AppLocale.japanese: '日本語',
        AppLocale.english: 'Japanese',
        AppLocale.spanish: 'Japonés',
        AppLocale.chinese: '日语',
        AppLocale.korean: '일본어',
        AppLocale.french: 'Japonais',
        AppLocale.german: 'Japanisch',
        AppLocale.italian: 'Giapponese',
      }),
      'korean': _t({
        AppLocale.japanese: '韓国語',
        AppLocale.english: 'Korean',
        AppLocale.spanish: 'Coreano',
        AppLocale.chinese: '韩语',
        AppLocale.korean: '한국어',
        AppLocale.french: 'Coréen',
        AppLocale.german: 'Koreanisch',
        AppLocale.italian: 'Coreano',
      }),
      'french': _t({
        AppLocale.japanese: 'フランス語',
        AppLocale.english: 'French',
        AppLocale.spanish: 'Francés',
        AppLocale.chinese: '法语',
        AppLocale.korean: '프랑스어',
        AppLocale.french: 'Français',
        AppLocale.german: 'Französisch',
        AppLocale.italian: 'Francese',
      }),
      'german': _t({
        AppLocale.japanese: 'ドイツ語',
        AppLocale.english: 'German',
        AppLocale.spanish: 'Alemán',
        AppLocale.chinese: '德语',
        AppLocale.korean: '독일어',
        AppLocale.french: 'Allemand',
        AppLocale.german: 'Deutsch',
        AppLocale.italian: 'Tedesco',
      }),
      'italian': _t({
        AppLocale.japanese: 'イタリア語',
        AppLocale.english: 'Italian',
        AppLocale.spanish: 'Italiano',
        AppLocale.chinese: '意大利语',
        AppLocale.korean: '이탈리아어',
        AppLocale.french: 'Italien',
        AppLocale.german: 'Italienisch',
        AppLocale.italian: 'Italiano',
      }),
    };
    return names[code] ?? code;
  }

  // ==================== Navigation / Page Titles ====================
  
  String get diary => _t({
    AppLocale.japanese: '日記',
    AppLocale.english: 'Diary',
    AppLocale.spanish: 'Diario',
    AppLocale.chinese: '日记',
    AppLocale.korean: '일기',
    AppLocale.french: 'Journal',
    AppLocale.german: 'Tagebuch',
    AppLocale.italian: 'Diario',
  });
  
  String get review => _t({
    AppLocale.japanese: '復習',
    AppLocale.english: 'Review',
    AppLocale.spanish: 'Repaso',
    AppLocale.chinese: '复习',
    AppLocale.korean: '복습',
    AppLocale.french: 'Révision',
    AppLocale.german: 'Überprüfung',
    AppLocale.italian: 'Ripasso',
  });

  // ==================== Diary List Screen ====================
  
  String get myDiaries => _t({
    AppLocale.japanese: 'マイ日記',
    AppLocale.english: 'My Diaries',
    AppLocale.spanish: 'Mis diarios',
    AppLocale.chinese: '我的日记',
    AppLocale.korean: '내 일기',
    AppLocale.french: 'Mes journaux',
    AppLocale.german: 'Meine Tagebücher',
    AppLocale.italian: 'I miei diari',
  });
  
  String get write => _t({
    AppLocale.japanese: '書く',
    AppLocale.english: 'Write',
    AppLocale.spanish: 'Escribir',
    AppLocale.chinese: '写作',
    AppLocale.korean: '쓰기',
    AppLocale.french: 'Écrire',
    AppLocale.german: 'Schreiben',
    AppLocale.italian: 'Scrivi',
  });
  
  String get handwritten => _t({
    AppLocale.japanese: '手書き',
    AppLocale.english: 'Handwritten',
    AppLocale.spanish: 'Escrito a mano',
    AppLocale.chinese: '手写',
    AppLocale.korean: '손글씨',
    AppLocale.french: 'Manuscrit',
    AppLocale.german: 'Handschriftlich',
    AppLocale.italian: 'Scritto a mano',
  });
  
  String get corrected2 => _t({
    AppLocale.japanese: '添削済み',
    AppLocale.english: 'Corrected',
    AppLocale.spanish: 'Corregido',
    AppLocale.chinese: '已批改',
    AppLocale.korean: '첨삭완료',
    AppLocale.french: 'Corrigé',
    AppLocale.german: 'Korrigiert',
    AppLocale.italian: 'Corretto',
  });
  
  String get noDiariesYet => _t({
    AppLocale.japanese: 'まだ日記がありません',
    AppLocale.english: 'No diaries yet',
    AppLocale.spanish: 'Aún no hay diarios',
    AppLocale.chinese: '还没有日记',
    AppLocale.korean: '아직 일기가 없습니다',
    AppLocale.french: 'Pas encore de journaux',
    AppLocale.german: 'Noch keine Tagebücher',
    AppLocale.italian: 'Ancora nessun diario',
  });
  
  String get startWritingFirst => _t({
    AppLocale.japanese: '最初の日記を書いてみましょう！',
    AppLocale.english: 'Start writing your first diary entry!',
    AppLocale.spanish: '¡Empieza a escribir tu primera entrada!',
    AppLocale.chinese: '开始写你的第一篇日记吧！',
    AppLocale.korean: '첫 번째 일기를 써보세요!',
    AppLocale.french: 'Commencez à écrire votre premier journal !',
    AppLocale.german: 'Schreiben Sie Ihren ersten Tagebucheintrag!',
    AppLocale.italian: 'Inizia a scrivere il tuo primo diario!',
  });
  
  String get failedToLoadDiaries => _t({
    AppLocale.japanese: '日記の読み込みに失敗しました',
    AppLocale.english: 'Failed to load diaries',
    AppLocale.spanish: 'Error al cargar los diarios',
    AppLocale.chinese: '加载日记失败',
    AppLocale.korean: '일기 로딩 실패',
    AppLocale.french: 'Échec du chargement des journaux',
    AppLocale.german: 'Tagebücher konnten nicht geladen werden',
    AppLocale.italian: 'Caricamento diari fallito',
  });
  
  String get selectDateToView => _t({
    AppLocale.japanese: '日記を見る日付を選択',
    AppLocale.english: 'Select a date to view diaries',
    AppLocale.spanish: 'Selecciona una fecha para ver los diarios',
    AppLocale.chinese: '选择日期查看日记',
    AppLocale.korean: '일기를 볼 날짜를 선택하세요',
    AppLocale.french: 'Sélectionnez une date pour voir les journaux',
    AppLocale.german: 'Wählen Sie ein Datum zum Anzeigen',
    AppLocale.italian: 'Seleziona una data per vedere i diari',
  });
  
  String noDiaryForDate(String date) => _t({
    AppLocale.japanese: '$dateの日記はありません',
    AppLocale.english: 'No diary entry for $date',
    AppLocale.spanish: 'No hay entrada de diario para $date',
    AppLocale.chinese: '$date没有日记',
    AppLocale.korean: '$date에 일기가 없습니다',
    AppLocale.french: 'Pas de journal pour $date',
    AppLocale.german: 'Kein Tagebucheintrag für $date',
    AppLocale.italian: 'Nessun diario per $date',
  });

  // Scan limit dialogs
  String get dailyScanLimitReached => _t({
    AppLocale.japanese: '今日のスキャン回数に達しました',
    AppLocale.english: 'Daily Scan Limit Reached',
    AppLocale.spanish: 'Límite diario de escaneo alcanzado',
    AppLocale.chinese: '已达到每日扫描限制',
    AppLocale.korean: '일일 스캔 한도 도달',
    AppLocale.french: 'Limite de scan quotidien atteinte',
    AppLocale.german: 'Tägliches Scan-Limit erreicht',
    AppLocale.italian: 'Limite scansioni giornaliere raggiunto',
  });
  
  String get usedAllScansToday => _t({
    AppLocale.japanese: 'ボーナススキャンを含め、今日のスキャン回数を使い切りました。\n\n明日また無料でスキャンできます。プレミアムなら無制限！',
    AppLocale.english: 'You\'ve used all your scans for today, including bonus scans.\n\nCome back tomorrow for more free scans, or upgrade to Premium for unlimited scanning!',
    AppLocale.spanish: 'Has usado todos tus escaneos de hoy, incluyendo los bonus.\n\n¡Vuelve mañana para más escaneos gratis, o actualiza a Premium para escaneos ilimitados!',
    AppLocale.chinese: '您今天的扫描次数（包括奖励扫描）已用完。\n\n明天再来免费扫描，或升级到高级版享受无限扫描！',
    AppLocale.korean: '보너스 스캔을 포함한 오늘의 스캔을 모두 사용했습니다.\n\n내일 다시 무료 스캔을 이용하거나 프리미엄으로 업그레이드하여 무제한 스캔을 이용하세요!',
    AppLocale.french: 'Vous avez utilisé tous vos scans d\'aujourd\'hui, y compris les bonus.\n\nRevenez demain pour plus de scans gratuits, ou passez à Premium pour des scans illimités !',
    AppLocale.german: 'Sie haben alle Ihre Scans für heute verbraucht, einschließlich Bonus-Scans.\n\nKommen Sie morgen für weitere kostenlose Scans wieder, oder upgraden Sie auf Premium für unbegrenztes Scannen!',
    AppLocale.italian: 'Hai usato tutte le scansioni di oggi, inclusi i bonus.\n\nTorna domani per altre scansioni gratuite, o passa a Premium per scansioni illimitate!',
  });
  
  String usedFreeScanWatchAd(int remaining) => _t({
    AppLocale.japanese: '今日の無料スキャンを使い切りました。\n\n短い広告を見て1回のボーナススキャンを獲得！\n（今日残り$remaining回のボーナス）',
    AppLocale.english: 'You\'ve used your free scan for today.\n\nWatch a short ad to get 1 bonus scan!\n($remaining bonus scans remaining today)',
    AppLocale.spanish: 'Has usado tu escaneo gratis de hoy.\n\n¡Ve un anuncio corto para obtener 1 escaneo bonus!\n($remaining escaneos bonus restantes hoy)',
    AppLocale.chinese: '您今天的免费扫描已用完。\n\n观看短视频广告获得1次奖励扫描！\n（今天还剩$remaining次奖励扫描）',
    AppLocale.korean: '오늘의 무료 스캔을 사용했습니다.\n\n짧은 광고를 보고 1회 보너스 스캔을 받으세요!\n(오늘 남은 보너스 $remaining회)',
    AppLocale.french: 'Vous avez utilisé votre scan gratuit d\'aujourd\'hui.\n\nRegardez une courte pub pour obtenir 1 scan bonus !\n($remaining scans bonus restants aujourd\'hui)',
    AppLocale.german: 'Sie haben Ihren kostenlosen Scan für heute verbraucht.\n\nSehen Sie sich eine kurze Werbung an, um 1 Bonus-Scan zu erhalten!\n($remaining Bonus-Scans heute verbleibend)',
    AppLocale.italian: 'Hai usato la scansione gratuita di oggi.\n\nGuarda un breve annuncio per ottenere 1 scansione bonus!\n($remaining scansioni bonus rimanenti oggi)',
  });
  
  String get watchAd => _t({
    AppLocale.japanese: '広告を見る',
    AppLocale.english: 'Watch Ad',
    AppLocale.spanish: 'Ver anuncio',
    AppLocale.chinese: '观看广告',
    AppLocale.korean: '광고 보기',
    AppLocale.french: 'Regarder la pub',
    AppLocale.german: 'Werbung ansehen',
    AppLocale.italian: 'Guarda annuncio',
  });
  
  String get loadingAd => _t({
    AppLocale.japanese: '広告を読み込み中...',
    AppLocale.english: 'Loading ad...',
    AppLocale.spanish: 'Cargando anuncio...',
    AppLocale.chinese: '加载广告中...',
    AppLocale.korean: '광고 로딩 중...',
    AppLocale.french: 'Chargement de la pub...',
    AppLocale.german: 'Werbung wird geladen...',
    AppLocale.italian: 'Caricamento annuncio...',
  });
  
  String get adNotAvailable => _t({
    AppLocale.japanese: '広告を利用できません。しばらくしてから再試行してください。',
    AppLocale.english: 'Ad not available. Please try again in a moment.',
    AppLocale.spanish: 'Anuncio no disponible. Inténtalo de nuevo en un momento.',
    AppLocale.chinese: '广告不可用。请稍后重试。',
    AppLocale.korean: '광고를 사용할 수 없습니다. 잠시 후 다시 시도해주세요.',
    AppLocale.french: 'Pub non disponible. Veuillez réessayer dans un instant.',
    AppLocale.german: 'Werbung nicht verfügbar. Bitte versuchen Sie es gleich noch einmal.',
    AppLocale.italian: 'Annuncio non disponibile. Riprova tra un momento.',
  });
  
  String get bonusScanGranted => _t({
    AppLocale.japanese: 'ボーナススキャンを獲得しました！',
    AppLocale.english: 'Bonus scan granted!',
    AppLocale.spanish: '¡Escaneo bonus otorgado!',
    AppLocale.chinese: '已获得奖励扫描！',
    AppLocale.korean: '보너스 스캔이 지급되었습니다!',
    AppLocale.french: 'Scan bonus accordé !',
    AppLocale.german: 'Bonus-Scan gewährt!',
    AppLocale.italian: 'Scansione bonus ottenuta!',
  });
  
  String get pleaseWatchCompleteAd => _t({
    AppLocale.japanese: 'ボーナスを獲得するには広告を最後までご覧ください。',
    AppLocale.english: 'Please watch the complete ad to earn the bonus scan.',
    AppLocale.spanish: 'Por favor, ve el anuncio completo para obtener el escaneo bonus.',
    AppLocale.chinese: '请观看完整广告以获得奖励扫描。',
    AppLocale.korean: '보너스 스캔을 받으려면 광고를 끝까지 시청해주세요.',
    AppLocale.french: 'Veuillez regarder la pub complète pour gagner le scan bonus.',
    AppLocale.german: 'Bitte sehen Sie sich die komplette Werbung an, um den Bonus-Scan zu erhalten.',
    AppLocale.italian: 'Per favore guarda l\'intero annuncio per ottenere la scansione bonus.',
  });

  // ==================== Diary Editor Screen ====================
  
  String get newDiary => _t({
    AppLocale.japanese: '新しい日記',
    AppLocale.english: 'New Diary',
    AppLocale.spanish: 'Nuevo diario',
    AppLocale.chinese: '新日记',
    AppLocale.korean: '새 일기',
    AppLocale.french: 'Nouveau journal',
    AppLocale.german: 'Neues Tagebuch',
    AppLocale.italian: 'Nuovo diario',
  });
  
  String get scannedDiary => _t({
    AppLocale.japanese: 'スキャンした日記',
    AppLocale.english: 'Scanned Diary',
    AppLocale.spanish: 'Diario escaneado',
    AppLocale.chinese: '扫描的日记',
    AppLocale.korean: '스캔한 일기',
    AppLocale.french: 'Journal scanné',
    AppLocale.german: 'Gescanntes Tagebuch',
    AppLocale.italian: 'Diario scansionato',
  });
  
  String get scannedFromHandwriting => _t({
    AppLocale.japanese: '手書きからスキャン - 必要に応じて確認・編集してください',
    AppLocale.english: 'Scanned from handwriting - Please review and edit if needed',
    AppLocale.spanish: 'Escaneado de escritura a mano - Por favor revisa y edita si es necesario',
    AppLocale.chinese: '从手写扫描 - 如需要请检查并编辑',
    AppLocale.korean: '손글씨에서 스캔됨 - 필요시 확인 및 수정해주세요',
    AppLocale.french: 'Scanné depuis l\'écriture manuscrite - Veuillez vérifier et modifier si nécessaire',
    AppLocale.german: 'Von Handschrift gescannt - Bitte überprüfen und bei Bedarf bearbeiten',
    AppLocale.italian: 'Scansionato da scrittura a mano - Si prega di rivedere e modificare se necessario',
  });
  
  // Dynamic hint text based on target language
  String writeAboutYourDayIn(String languageName) => _t({
    AppLocale.japanese: '$languageNameで今日のことを書いてみましょう...',
    AppLocale.english: 'Write about your day in $languageName...',
    AppLocale.spanish: 'Escribe sobre tu día en $languageName...',
    AppLocale.chinese: '用${languageName}写下今天的事情...',
    AppLocale.korean: '${languageName}로 오늘 하루를 써보세요...',
    AppLocale.french: 'Écrivez sur votre journée en $languageName...',
    AppLocale.german: 'Schreiben Sie über Ihren Tag auf $languageName...',
    AppLocale.italian: 'Scrivi della tua giornata in $languageName...',
  });
  
  String get pleaseWriteSomething => _t({
    AppLocale.japanese: '何か書いてください',
    AppLocale.english: 'Please write something first',
    AppLocale.spanish: 'Por favor escribe algo primero',
    AppLocale.chinese: '请先写点什么',
    AppLocale.korean: '먼저 무언가를 써주세요',
    AppLocale.french: 'Veuillez d\'abord écrire quelque chose',
    AppLocale.german: 'Bitte schreiben Sie zuerst etwas',
    AppLocale.italian: 'Per favore scrivi prima qualcosa',
  });
  
  String get diarySavedSuccess => _t({
    AppLocale.japanese: '日記を保存しました！',
    AppLocale.english: 'Diary saved successfully!',
    AppLocale.spanish: '¡Diario guardado exitosamente!',
    AppLocale.chinese: '日记保存成功！',
    AppLocale.korean: '일기가 성공적으로 저장되었습니다!',
    AppLocale.french: 'Journal enregistré avec succès !',
    AppLocale.german: 'Tagebuch erfolgreich gespeichert!',
    AppLocale.italian: 'Diario salvato con successo!',
  });
  
  String words(int count) => _t({
    AppLocale.japanese: '$count語',
    AppLocale.english: '$count words',
    AppLocale.spanish: '$count palabras',
    AppLocale.chinese: '$count字',
    AppLocale.korean: '$count단어',
    AppLocale.french: '$count mots',
    AppLocale.german: '$count Wörter',
    AppLocale.italian: '$count parole',
  });

  // ==================== Camera / Scan Screen ====================
  
  String get scanHandwriting => _t({
    AppLocale.japanese: '手書きをスキャン',
    AppLocale.english: 'Scan Handwriting',
    AppLocale.spanish: 'Escanear escritura',
    AppLocale.chinese: '扫描手写',
    AppLocale.korean: '손글씨 스캔',
    AppLocale.french: 'Scanner l\'écriture',
    AppLocale.german: 'Handschrift scannen',
    AppLocale.italian: 'Scansiona scrittura',
  });
  
  String get ensureGoodLighting => _t({
    AppLocale.japanese: '最良の結果を得るために十分な照明を確保してください',
    AppLocale.english: 'Ensure good lighting for best results',
    AppLocale.spanish: 'Asegura buena iluminación para mejores resultados',
    AppLocale.chinese: '确保光线充足以获得最佳效果',
    AppLocale.korean: '최상의 결과를 위해 충분한 조명을 확보하세요',
    AppLocale.french: 'Assurez un bon éclairage pour de meilleurs résultats',
    AppLocale.german: 'Sorgen Sie für gute Beleuchtung für beste Ergebnisse',
    AppLocale.italian: 'Assicura una buona illuminazione per risultati migliori',
  });
  
  String get bonusScanGrantedRetrying => _t({
    AppLocale.japanese: 'ボーナススキャンを獲得！再試行中...',
    AppLocale.english: 'Bonus scan granted! Retrying...',
    AppLocale.spanish: '¡Escaneo bonus otorgado! Reintentando...',
    AppLocale.chinese: '已获得奖励扫描！正在重试...',
    AppLocale.korean: '보너스 스캔 지급! 재시도 중...',
    AppLocale.french: 'Scan bonus accordé ! Nouvelle tentative...',
    AppLocale.german: 'Bonus-Scan gewährt! Wird erneut versucht...',
    AppLocale.italian: 'Scansione bonus ottenuta! Nuovo tentativo...',
  });

  // ==================== Review Screen ====================
  
  String get reviewCards => _t({
    AppLocale.japanese: '復習カード',
    AppLocale.english: 'Review Cards',
    AppLocale.spanish: 'Tarjetas de repaso',
    AppLocale.chinese: '复习卡',
    AppLocale.korean: '복습 카드',
    AppLocale.french: 'Cartes de révision',
    AppLocale.german: 'Lernkarten',
    AppLocale.italian: 'Schede di ripasso',
  });
  
  String get deleteCard => _t({
    AppLocale.japanese: 'カードを削除',
    AppLocale.english: 'Delete Card',
    AppLocale.spanish: 'Eliminar tarjeta',
    AppLocale.chinese: '删除卡片',
    AppLocale.korean: '카드 삭제',
    AppLocale.french: 'Supprimer la carte',
    AppLocale.german: 'Karte löschen',
    AppLocale.italian: 'Elimina scheda',
  });
  
  String get deleteCardConfirm => _t({
    AppLocale.japanese: 'この復習カードを削除してもよろしいですか？',
    AppLocale.english: 'Are you sure you want to delete this review card?',
    AppLocale.spanish: '¿Seguro que quieres eliminar esta tarjeta de repaso?',
    AppLocale.chinese: '确定要删除这张复习卡吗？',
    AppLocale.korean: '이 복습 카드를 삭제하시겠습니까?',
    AppLocale.french: 'Voulez-vous vraiment supprimer cette carte de révision ?',
    AppLocale.german: 'Möchten Sie diese Lernkarte wirklich löschen?',
    AppLocale.italian: 'Sei sicuro di voler eliminare questa scheda di ripasso?',
  });
  
  String get cardDeleted => _t({
    AppLocale.japanese: 'カードを削除しました',
    AppLocale.english: 'Card deleted',
    AppLocale.spanish: 'Tarjeta eliminada',
    AppLocale.chinese: '卡片已删除',
    AppLocale.korean: '카드가 삭제되었습니다',
    AppLocale.french: 'Carte supprimée',
    AppLocale.german: 'Karte gelöscht',
    AppLocale.italian: 'Scheda eliminata',
  });
  
  String get failedToLoadCards => _t({
    AppLocale.japanese: 'カードの読み込みに失敗しました',
    AppLocale.english: 'Failed to load cards',
    AppLocale.spanish: 'Error al cargar las tarjetas',
    AppLocale.chinese: '加载卡片失败',
    AppLocale.korean: '카드 로딩 실패',
    AppLocale.french: 'Échec du chargement des cartes',
    AppLocale.german: 'Karten konnten nicht geladen werden',
    AppLocale.italian: 'Caricamento schede fallito',
  });
  
  String get noReviewCardsYet => _t({
    AppLocale.japanese: '復習カードがまだありません',
    AppLocale.english: 'No review cards yet',
    AppLocale.spanish: 'Aún no hay tarjetas de repaso',
    AppLocale.chinese: '还没有复习卡',
    AppLocale.korean: '아직 복습 카드가 없습니다',
    AppLocale.french: 'Pas encore de cartes de révision',
    AppLocale.german: 'Noch keine Lernkarten',
    AppLocale.italian: 'Ancora nessuna scheda di ripasso',
  });
  
  String get createCardsFromCorrections => _t({
    AppLocale.japanese: '日記の添削からカードを作成しましょう！',
    AppLocale.english: 'Create cards from diary corrections!',
    AppLocale.spanish: '¡Crea tarjetas de las correcciones del diario!',
    AppLocale.chinese: '从日记批改中创建卡片吧！',
    AppLocale.korean: '일기 첨삭에서 카드를 만들어보세요!',
    AppLocale.french: 'Créez des cartes à partir des corrections du journal !',
    AppLocale.german: 'Erstellen Sie Karten aus Tagebuchkorrekturen!',
    AppLocale.italian: 'Crea schede dalle correzioni del diario!',
  });
  
  String get whatsWrongWithThis => _t({
    AppLocale.japanese: 'どこが間違っている？',
    AppLocale.english: 'What\'s wrong with this?',
    AppLocale.spanish: '¿Qué está mal aquí?',
    AppLocale.chinese: '这里有什么问题？',
    AppLocale.korean: '무엇이 잘못되었나요?',
    AppLocale.french: 'Qu\'est-ce qui ne va pas ?',
    AppLocale.german: 'Was ist hier falsch?',
    AppLocale.italian: 'Cosa c\'è di sbagliato?',
  });
  
  String get tapToSeeAnswer => _t({
    AppLocale.japanese: 'タップして答えを見る',
    AppLocale.english: 'Tap to see answer',
    AppLocale.spanish: 'Toca para ver la respuesta',
    AppLocale.chinese: '点击查看答案',
    AppLocale.korean: '탭하여 답 보기',
    AppLocale.french: 'Appuyez pour voir la réponse',
    AppLocale.german: 'Tippen Sie, um die Antwort zu sehen',
    AppLocale.italian: 'Tocca per vedere la risposta',
  });
  
  String get correctExpression => _t({
    AppLocale.japanese: '正しい表現:',
    AppLocale.english: 'Correct expression:',
    AppLocale.spanish: 'Expresión correcta:',
    AppLocale.chinese: '正确表达：',
    AppLocale.korean: '올바른 표현:',
    AppLocale.french: 'Expression correcte :',
    AppLocale.german: 'Korrekter Ausdruck:',
    AppLocale.italian: 'Espressione corretta:',
  });
  
  String contextLabel(String context) => _t({
    AppLocale.japanese: '文脈: $context',
    AppLocale.english: 'Context: $context',
    AppLocale.spanish: 'Contexto: $context',
    AppLocale.chinese: '上下文：$context',
    AppLocale.korean: '문맥: $context',
    AppLocale.french: 'Contexte : $context',
    AppLocale.german: 'Kontext: $context',
    AppLocale.italian: 'Contesto: $context',
  });
  
  String get tapToHide => _t({
    AppLocale.japanese: 'タップして隠す',
    AppLocale.english: 'Tap to hide',
    AppLocale.spanish: 'Toca para ocultar',
    AppLocale.chinese: '点击隐藏',
    AppLocale.korean: '탭하여 숨기기',
    AppLocale.french: 'Appuyez pour masquer',
    AppLocale.german: 'Tippen zum Ausblenden',
    AppLocale.italian: 'Tocca per nascondere',
  });

  // Error tags (grammar, style, etc.)
  String get grammar => _t({
    AppLocale.japanese: '文法',
    AppLocale.english: 'grammar',
    AppLocale.spanish: 'gramática',
    AppLocale.chinese: '语法',
    AppLocale.korean: '문법',
    AppLocale.french: 'grammaire',
    AppLocale.german: 'Grammatik',
    AppLocale.italian: 'grammatica',
  });
  
  String get style => _t({
    AppLocale.japanese: 'スタイル',
    AppLocale.english: 'style',
    AppLocale.spanish: 'estilo',
    AppLocale.chinese: '风格',
    AppLocale.korean: '스타일',
    AppLocale.french: 'style',
    AppLocale.german: 'Stil',
    AppLocale.italian: 'stile',
  });
  
  String get vocabulary => _t({
    AppLocale.japanese: '語彙',
    AppLocale.english: 'vocabulary',
    AppLocale.spanish: 'vocabulario',
    AppLocale.chinese: '词汇',
    AppLocale.korean: '어휘',
    AppLocale.french: 'vocabulaire',
    AppLocale.german: 'Wortschatz',
    AppLocale.italian: 'vocabolario',
  });
  
  String get spelling => _t({
    AppLocale.japanese: 'スペル',
    AppLocale.english: 'spelling',
    AppLocale.spanish: 'ortografía',
    AppLocale.chinese: '拼写',
    AppLocale.korean: '철자',
    AppLocale.french: 'orthographe',
    AppLocale.german: 'Rechtschreibung',
    AppLocale.italian: 'ortografia',
  });

  String get ok => _t({
    AppLocale.japanese: 'OK',
    AppLocale.english: 'OK',
    AppLocale.spanish: 'OK',
    AppLocale.chinese: '好的',
    AppLocale.korean: '확인',
    AppLocale.french: 'OK',
    AppLocale.german: 'OK',
    AppLocale.italian: 'OK',
  });

  // Diary Edit Screen
  String get diaryUpdatedCorrectionCleared => _t({
    AppLocale.japanese: '日記を更新しました！添削はクリアされました。',
    AppLocale.english: 'Diary updated! Corrections have been cleared.',
    AppLocale.spanish: '¡Diario actualizado! Las correcciones se han borrado.',
    AppLocale.chinese: '日记已更新！批改已清除。',
    AppLocale.korean: '일기가 업데이트되었습니다! 첨삭이 초기화되었습니다.',
    AppLocale.french: 'Journal mis à jour ! Les corrections ont été effacées.',
    AppLocale.german: 'Tagebuch aktualisiert! Korrekturen wurden gelöscht.',
    AppLocale.italian: 'Diario aggiornato! Le correzioni sono state cancellate.',
  });

  String get discardChangesTitle => _t({
    AppLocale.japanese: '変更を破棄しますか？',
    AppLocale.english: 'Discard changes?',
    AppLocale.spanish: '¿Descartar cambios?',
    AppLocale.chinese: '放弃更改？',
    AppLocale.korean: '변경 사항을 삭제하시겠습니까?',
    AppLocale.french: 'Abandonner les modifications ?',
    AppLocale.german: 'Änderungen verwerfen?',
    AppLocale.italian: 'Annullare le modifiche?',
  });

  String get unsavedChangesMessage => _t({
    AppLocale.japanese: '保存されていない変更があります。本当に破棄しますか？',
    AppLocale.english: 'You have unsaved changes. Are you sure you want to discard them?',
    AppLocale.spanish: 'Tienes cambios sin guardar. ¿Estás seguro de que deseas descartarlos?',
    AppLocale.chinese: '您有未保存的更改。确定要放弃吗？',
    AppLocale.korean: '저장되지 않은 변경 사항이 있습니다. 정말 삭제하시겠습니까?',
    AppLocale.french: 'Vous avez des modifications non enregistrées. Voulez-vous les abandonner ?',
    AppLocale.german: 'Sie haben ungespeicherte Änderungen. Möchten Sie sie wirklich verwerfen?',
    AppLocale.italian: 'Hai modifiche non salvate. Sei sicuro di volerle annullare?',
  });

  String get discard => _t({
    AppLocale.japanese: '破棄',
    AppLocale.english: 'Discard',
    AppLocale.spanish: 'Descartar',
    AppLocale.chinese: '放弃',
    AppLocale.korean: '삭제',
    AppLocale.french: 'Abandonner',
    AppLocale.german: 'Verwerfen',
    AppLocale.italian: 'Annulla',
  });

  String get editDiary => _t({
    AppLocale.japanese: '日記を編集',
    AppLocale.english: 'Edit Diary',
    AppLocale.spanish: 'Editar diario',
    AppLocale.chinese: '编辑日记',
    AppLocale.korean: '일기 편집',
    AppLocale.french: 'Modifier le journal',
    AppLocale.german: 'Tagebuch bearbeiten',
    AppLocale.italian: 'Modifica diario',
  });

  String get saving => _t({
    AppLocale.japanese: '保存中...',
    AppLocale.english: 'Saving...',
    AppLocale.spanish: 'Guardando...',
    AppLocale.chinese: '保存中...',
    AppLocale.korean: '저장 중...',
    AppLocale.french: 'Enregistrement...',
    AppLocale.german: 'Speichern...',
    AppLocale.italian: 'Salvataggio...',
  });

  String get writeEnglishDiaryHint => _t({
    AppLocale.japanese: '英語で日記を書いてください...',
    AppLocale.english: 'Write your diary in English...',
    AppLocale.spanish: 'Escribe tu diario en inglés...',
    AppLocale.chinese: '请用英语写日记...',
    AppLocale.korean: '영어로 일기를 써주세요...',
    AppLocale.french: 'Écrivez votre journal en anglais...',
    AppLocale.german: 'Schreiben Sie Ihr Tagebuch auf Englisch...',
    AppLocale.italian: 'Scrivi il tuo diario in inglese...',
  });

  String get editingNoteWarning => _t({
    AppLocale.japanese: '注意: 保存すると添削がクリアされます。',
    AppLocale.english: 'Note: Saving will clear corrections.',
    AppLocale.spanish: 'Nota: Guardar borrará las correcciones.',
    AppLocale.chinese: '注意：保存将清除批改。',
    AppLocale.korean: '주의: 저장하면 첨삭이 초기화됩니다.',
    AppLocale.french: 'Note : Enregistrer effacera les corrections.',
    AppLocale.german: 'Hinweis: Speichern löscht die Korrekturen.',
    AppLocale.italian: 'Nota: Il salvataggio cancellerà le correzioni.',
  });

  // Forgot Password
  String get forgotPassword => _t({
    AppLocale.japanese: 'パスワードを忘れた場合',
    AppLocale.english: 'Forgot Password?',
    AppLocale.spanish: '¿Olvidaste tu contraseña?',
    AppLocale.chinese: '忘记密码？',
    AppLocale.korean: '비밀번호를 잊으셨나요?',
    AppLocale.french: 'Mot de passe oublié ?',
    AppLocale.german: 'Passwort vergessen?',
    AppLocale.italian: 'Password dimenticata?',
  });

  String get resetPassword => _t({
    AppLocale.japanese: 'パスワードリセット',
    AppLocale.english: 'Reset Password',
    AppLocale.spanish: 'Restablecer contraseña',
    AppLocale.chinese: '重置密码',
    AppLocale.korean: '비밀번호 재설정',
    AppLocale.french: 'Réinitialiser le mot de passe',
    AppLocale.german: 'Passwort zurücksetzen',
    AppLocale.italian: 'Reimposta password',
  });

  String get resetPasswordInstructions => _t({
    AppLocale.japanese: '登録したメールアドレスを入力してください。パスワードリセット用の確認コードを送信します。',
    AppLocale.english: 'Enter your registered email address. We will send a verification code to reset your password.',
    AppLocale.spanish: 'Introduce tu correo electrónico registrado. Enviaremos un código de verificación para restablecer tu contraseña.',
    AppLocale.chinese: '请输入您注册的电子邮件地址。我们将发送验证码以重置您的密码。',
    AppLocale.korean: '등록된 이메일 주소를 입력하세요. 비밀번호 재설정을 위한 인증 코드를 보내드립니다.',
    AppLocale.french: 'Entrez votre adresse e-mail enregistrée. Nous enverrons un code de vérification pour réinitialiser votre mot de passe.',
    AppLocale.german: 'Geben Sie Ihre registrierte E-Mail-Adresse ein. Wir senden Ihnen einen Bestätigungscode zum Zurücksetzen Ihres Passworts.',
    AppLocale.italian: 'Inserisci il tuo indirizzo email registrato. Invieremo un codice di verifica per reimpostare la password.',
  });

  String get sendResetCode => _t({
    AppLocale.japanese: '確認コードを送信',
    AppLocale.english: 'Send Reset Code',
    AppLocale.spanish: 'Enviar código',
    AppLocale.chinese: '发送验证码',
    AppLocale.korean: '인증 코드 보내기',
    AppLocale.french: 'Envoyer le code',
    AppLocale.german: 'Code senden',
    AppLocale.italian: 'Invia codice',
  });

  String get resetCodeSent => _t({
    AppLocale.japanese: '確認コードを送信しました。メールをご確認ください。',
    AppLocale.english: 'Reset code sent. Please check your email.',
    AppLocale.spanish: 'Código enviado. Revisa tu correo electrónico.',
    AppLocale.chinese: '验证码已发送。请检查您的电子邮件。',
    AppLocale.korean: '인증 코드가 전송되었습니다. 이메일을 확인하세요.',
    AppLocale.french: 'Code envoyé. Veuillez vérifier votre e-mail.',
    AppLocale.german: 'Code gesendet. Bitte überprüfen Sie Ihre E-Mail.',
    AppLocale.italian: 'Codice inviato. Controlla la tua email.',
  });

  String get newPassword => _t({
    AppLocale.japanese: '新しいパスワード',
    AppLocale.english: 'New Password',
    AppLocale.spanish: 'Nueva contraseña',
    AppLocale.chinese: '新密码',
    AppLocale.korean: '새 비밀번호',
    AppLocale.french: 'Nouveau mot de passe',
    AppLocale.german: 'Neues Passwort',
    AppLocale.italian: 'Nuova password',
  });

  String get confirmNewPassword => _t({
    AppLocale.japanese: '新しいパスワードを確認',
    AppLocale.english: 'Confirm New Password',
    AppLocale.spanish: 'Confirmar nueva contraseña',
    AppLocale.chinese: '确认新密码',
    AppLocale.korean: '새 비밀번호 확인',
    AppLocale.french: 'Confirmer le nouveau mot de passe',
    AppLocale.german: 'Neues Passwort bestätigen',
    AppLocale.italian: 'Conferma nuova password',
  });

  String get passwordResetSuccess => _t({
    AppLocale.japanese: 'パスワードがリセットされました。新しいパスワードでログインしてください。',
    AppLocale.english: 'Password reset successful. Please log in with your new password.',
    AppLocale.spanish: 'Contraseña restablecida. Inicia sesión con tu nueva contraseña.',
    AppLocale.chinese: '密码重置成功。请使用新密码登录。',
    AppLocale.korean: '비밀번호가 재설정되었습니다. 새 비밀번호로 로그인하세요.',
    AppLocale.french: 'Mot de passe réinitialisé. Veuillez vous connecter avec votre nouveau mot de passe.',
    AppLocale.german: 'Passwort zurückgesetzt. Bitte melden Sie sich mit Ihrem neuen Passwort an.',
    AppLocale.italian: 'Password reimpostata. Accedi con la nuova password.',
  });

  String get passwordsDoNotMatch => _t({
    AppLocale.japanese: 'パスワードが一致しません',
    AppLocale.english: 'Passwords do not match',
    AppLocale.spanish: 'Las contraseñas no coinciden',
    AppLocale.chinese: '密码不匹配',
    AppLocale.korean: '비밀번호가 일치하지 않습니다',
    AppLocale.french: 'Les mots de passe ne correspondent pas',
    AppLocale.german: 'Passwörter stimmen nicht überein',
    AppLocale.italian: 'Le password non corrispondono',
  });

  String get verificationCode => _t({
    AppLocale.japanese: '確認コード',
    AppLocale.english: 'Verification Code',
    AppLocale.spanish: 'Código de verificación',
    AppLocale.chinese: '验证码',
    AppLocale.korean: '인증 코드',
    AppLocale.french: 'Code de vérification',
    AppLocale.german: 'Bestätigungscode',
    AppLocale.italian: 'Codice di verifica',
  });

  // --- Auth form strings ---

  String get email => _t({
    AppLocale.japanese: 'メールアドレス',
    AppLocale.english: 'Email',
    AppLocale.spanish: 'Correo electrónico',
    AppLocale.chinese: '邮箱',
    AppLocale.korean: '이메일',
    AppLocale.french: 'E-mail',
    AppLocale.german: 'E-Mail',
    AppLocale.italian: 'Email',
  });

  String get password => _t({
    AppLocale.japanese: 'パスワード',
    AppLocale.english: 'Password',
    AppLocale.spanish: 'Contraseña',
    AppLocale.chinese: '密码',
    AppLocale.korean: '비밀번호',
    AppLocale.french: 'Mot de passe',
    AppLocale.german: 'Passwort',
    AppLocale.italian: 'Password',
  });

  String get confirmPassword => _t({
    AppLocale.japanese: 'パスワードを確認',
    AppLocale.english: 'Confirm Password',
    AppLocale.spanish: 'Confirmar contraseña',
    AppLocale.chinese: '确认密码',
    AppLocale.korean: '비밀번호 확인',
    AppLocale.french: 'Confirmer le mot de passe',
    AppLocale.german: 'Passwort bestätigen',
    AppLocale.italian: 'Conferma password',
  });

  String get emailRequired => _t({
    AppLocale.japanese: 'メールアドレスを入力してください',
    AppLocale.english: 'Please enter your email',
    AppLocale.spanish: 'Por favor, introduce tu correo electrónico',
    AppLocale.chinese: '请输入您的邮箱',
    AppLocale.korean: '이메일을 입력해주세요',
    AppLocale.french: 'Veuillez saisir votre e-mail',
    AppLocale.german: 'Bitte geben Sie Ihre E-Mail ein',
    AppLocale.italian: 'Inserisci la tua email',
  });

  String get emailInvalid => _t({
    AppLocale.japanese: '有効なメールアドレスを入力してください',
    AppLocale.english: 'Please enter a valid email',
    AppLocale.spanish: 'Introduce un correo electrónico válido',
    AppLocale.chinese: '请输入有效的邮箱',
    AppLocale.korean: '유효한 이메일을 입력해주세요',
    AppLocale.french: 'Veuillez saisir un e-mail valide',
    AppLocale.german: 'Bitte geben Sie eine gültige E-Mail ein',
    AppLocale.italian: 'Inserisci un indirizzo email valido',
  });

  String get passwordRequired => _t({
    AppLocale.japanese: 'パスワードを入力してください',
    AppLocale.english: 'Please enter a password',
    AppLocale.spanish: 'Por favor, introduce una contraseña',
    AppLocale.chinese: '请输入密码',
    AppLocale.korean: '비밀번호를 입력해주세요',
    AppLocale.french: 'Veuillez saisir un mot de passe',
    AppLocale.german: 'Bitte geben Sie ein Passwort ein',
    AppLocale.italian: 'Inserisci una password',
  });

  String get passwordTooShort => _t({
    AppLocale.japanese: 'パスワードは8文字以上で入力してください',
    AppLocale.english: 'Password must be at least 8 characters',
    AppLocale.spanish: 'La contraseña debe tener al menos 8 caracteres',
    AppLocale.chinese: '密码至少需要8个字符',
    AppLocale.korean: '비밀번호는 8자 이상이어야 합니다',
    AppLocale.french: 'Le mot de passe doit contenir au moins 8 caractères',
    AppLocale.german: 'Das Passwort muss mindestens 8 Zeichen lang sein',
    AppLocale.italian: 'La password deve contenere almeno 8 caratteri',
  });

  String get passwordNeedsUppercase => _t({
    AppLocale.japanese: 'パスワードには大文字を含めてください',
    AppLocale.english: 'Password must contain an uppercase letter',
    AppLocale.spanish: 'La contraseña debe contener una letra mayúscula',
    AppLocale.chinese: '密码必须包含大写字母',
    AppLocale.korean: '비밀번호에 대문자를 포함해야 합니다',
    AppLocale.french: 'Le mot de passe doit contenir une majuscule',
    AppLocale.german: 'Das Passwort muss einen Großbuchstaben enthalten',
    AppLocale.italian: 'La password deve contenere una lettera maiuscola',
  });

  String get passwordNeedsLowercase => _t({
    AppLocale.japanese: 'パスワードには小文字を含めてください',
    AppLocale.english: 'Password must contain a lowercase letter',
    AppLocale.spanish: 'La contraseña debe contener una letra minúscula',
    AppLocale.chinese: '密码必须包含小写字母',
    AppLocale.korean: '비밀번호에 소문자를 포함해야 합니다',
    AppLocale.french: 'Le mot de passe doit contenir une minuscule',
    AppLocale.german: 'Das Passwort muss einen Kleinbuchstaben enthalten',
    AppLocale.italian: 'La password deve contenere una lettera minuscola',
  });

  String get passwordNeedsNumber => _t({
    AppLocale.japanese: 'パスワードには数字を含めてください',
    AppLocale.english: 'Password must contain a number',
    AppLocale.spanish: 'La contraseña debe contener un número',
    AppLocale.chinese: '密码必须包含数字',
    AppLocale.korean: '비밀번호에 숫자를 포함해야 합니다',
    AppLocale.french: 'Le mot de passe doit contenir un chiffre',
    AppLocale.german: 'Das Passwort muss eine Zahl enthalten',
    AppLocale.italian: 'La password deve contenere un numero',
  });

  String get passwordHelper => _t({
    AppLocale.japanese: '大文字・小文字・数字を含む8文字以上',
    AppLocale.english: 'At least 8 characters with uppercase, lowercase, and number',
    AppLocale.spanish: 'Al menos 8 caracteres con mayúscula, minúscula y número',
    AppLocale.chinese: '至少8个字符，包含大小写字母和数字',
    AppLocale.korean: '대문자, 소문자, 숫자를 포함한 8자 이상',
    AppLocale.french: 'Au moins 8 caractères avec majuscule, minuscule et chiffre',
    AppLocale.german: 'Mindestens 8 Zeichen mit Groß-, Kleinbuchstaben und Zahl',
    AppLocale.italian: 'Almeno 8 caratteri con maiuscola, minuscola e numero',
  });

  String get displayNameRequired => _t({
    AppLocale.japanese: '表示名を入力してください',
    AppLocale.english: 'Please enter a display name',
    AppLocale.spanish: 'Por favor, introduce un nombre visible',
    AppLocale.chinese: '请输入显示名称',
    AppLocale.korean: '표시 이름을 입력해주세요',
    AppLocale.french: "Veuillez saisir un nom d'affichage",
    AppLocale.german: 'Bitte geben Sie einen Anzeigenamen ein',
    AppLocale.italian: 'Inserisci un nome visualizzato',
  });

  String get displayNameTooShort => _t({
    AppLocale.japanese: '表示名は2文字以上で入力してください',
    AppLocale.english: 'Display name must be at least 2 characters',
    AppLocale.spanish: 'El nombre visible debe tener al menos 2 caracteres',
    AppLocale.chinese: '显示名称至少需要2个字符',
    AppLocale.korean: '표시 이름은 2자 이상이어야 합니다',
    AppLocale.french: "Le nom d'affichage doit contenir au moins 2 caractères",
    AppLocale.german: 'Anzeigename muss mindestens 2 Zeichen lang sein',
    AppLocale.italian: 'Il nome visualizzato deve contenere almeno 2 caratteri',
  });

  String get displayNameTooLong => _t({
    AppLocale.japanese: '表示名は50文字以内で入力してください',
    AppLocale.english: 'Display name must be less than 50 characters',
    AppLocale.spanish: 'El nombre visible debe tener menos de 50 caracteres',
    AppLocale.chinese: '显示名称不能超过50个字符',
    AppLocale.korean: '표시 이름은 50자 이내여야 합니다',
    AppLocale.french: "Le nom d'affichage doit contenir moins de 50 caractères",
    AppLocale.german: 'Anzeigename muss weniger als 50 Zeichen lang sein',
    AppLocale.italian: 'Il nome visualizzato deve avere meno di 50 caratteri',
  });

  String get displayNameHint => _t({
    AppLocale.japanese: 'あなたの呼び名は？',
    AppLocale.english: 'How should we call you?',
    AppLocale.spanish: '¿Cómo deberíamos llamarte?',
    AppLocale.chinese: '我们应该如何称呼您？',
    AppLocale.korean: '어떻게 불러드릴까요?',
    AppLocale.french: 'Comment devrions-nous vous appeler ?',
    AppLocale.german: 'Wie sollen wir Sie nennen?',
    AppLocale.italian: 'Come dovremmo chiamarti?',
  });

  String get createAccount => _t({
    AppLocale.japanese: 'アカウントを作成',
    AppLocale.english: 'Create Account',
    AppLocale.spanish: 'Crear cuenta',
    AppLocale.chinese: '创建账户',
    AppLocale.korean: '계정 만들기',
    AppLocale.french: 'Créer un compte',
    AppLocale.german: 'Konto erstellen',
    AppLocale.italian: 'Crea account',
  });

  String get startLearningJourney => _t({
    AppLocale.japanese: '学習の旅を始めましょう',
    AppLocale.english: 'Start your learning journey',
    AppLocale.spanish: 'Comienza tu viaje de aprendizaje',
    AppLocale.chinese: '开启您的学习之旅',
    AppLocale.korean: '학습 여정을 시작하세요',
    AppLocale.french: 'Commencez votre parcours d\'apprentissage',
    AppLocale.german: 'Beginnen Sie Ihre Lernreise',
    AppLocale.italian: 'Inizia il tuo percorso di apprendimento',
  });

  String get termsAgreement => _t({
    AppLocale.japanese: 'サインアップすることで、利用規約とプライバシーポリシーに同意したことになります',
    AppLocale.english: 'By signing up, you agree to our Terms of Service and Privacy Policy',
    AppLocale.spanish: 'Al registrarte, aceptas nuestros Términos de servicio y Política de privacidad',
    AppLocale.chinese: '注册即表示您同意我们的服务条款和隐私政策',
    AppLocale.korean: '가입하시면 서비스 약관 및 개인정보 처리방침에 동의하는 것으로 간주됩니다',
    AppLocale.french: 'En vous inscrivant, vous acceptez nos conditions d\'utilisation et notre politique de confidentialité',
    AppLocale.german: 'Mit der Anmeldung stimmen Sie unseren Nutzungsbedingungen und der Datenschutzerklärung zu',
    AppLocale.italian: 'Registrandoti, accetti i nostri Termini di servizio e l\'Informativa sulla privacy',
  });

  String get alreadyHaveAccount => _t({
    AppLocale.japanese: 'すでにアカウントをお持ちですか？ ',
    AppLocale.english: 'Already have an account? ',
    AppLocale.spanish: '¿Ya tienes una cuenta? ',
    AppLocale.chinese: '已有账户？ ',
    AppLocale.korean: '이미 계정이 있으신가요? ',
    AppLocale.french: 'Vous avez déjà un compte ? ',
    AppLocale.german: 'Sie haben bereits ein Konto? ',
    AppLocale.italian: 'Hai già un account? ',
  });

  String get dontHaveAccount => _t({
    AppLocale.japanese: 'アカウントをお持ちでないですか？ ',
    AppLocale.english: "Don't have an account? ",
    AppLocale.spanish: '¿No tienes una cuenta? ',
    AppLocale.chinese: '还没有账户？ ',
    AppLocale.korean: '계정이 없으신가요? ',
    AppLocale.french: "Vous n'avez pas de compte ? ",
    AppLocale.german: 'Sie haben noch kein Konto? ',
    AppLocale.italian: 'Non hai un account? ',
  });

  String get checkYourEmail => _t({
    AppLocale.japanese: 'メールをご確認ください',
    AppLocale.english: 'Check your email',
    AppLocale.spanish: 'Revisa tu correo electrónico',
    AppLocale.chinese: '请查看您的邮箱',
    AppLocale.korean: '이메일을 확인해주세요',
    AppLocale.french: 'Vérifiez votre e-mail',
    AppLocale.german: 'Überprüfen Sie Ihre E-Mail',
    AppLocale.italian: 'Controlla la tua email',
  });

  String weSentCodeTo(String email) => _t({
    AppLocale.japanese: '確認コードを次のアドレスに送信しました\n$email',
    AppLocale.english: 'We sent a verification code to\n$email',
    AppLocale.spanish: 'Enviamos un código de verificación a\n$email',
    AppLocale.chinese: '我们已将验证码发送至\n$email',
    AppLocale.korean: '다음 주소로 인증 코드를 보냈습니다\n$email',
    AppLocale.french: 'Nous avons envoyé un code de vérification à\n$email',
    AppLocale.german: 'Wir haben einen Bestätigungscode gesendet an\n$email',
    AppLocale.italian: 'Abbiamo inviato un codice di verifica a\n$email',
  });

  String get verificationCodeRequired => _t({
    AppLocale.japanese: '確認コードを入力してください',
    AppLocale.english: 'Please enter the verification code',
    AppLocale.spanish: 'Por favor, introduce el código de verificación',
    AppLocale.chinese: '请输入验证码',
    AppLocale.korean: '인증 코드를 입력해주세요',
    AppLocale.french: 'Veuillez saisir le code de vérification',
    AppLocale.german: 'Bitte geben Sie den Bestätigungscode ein',
    AppLocale.italian: 'Inserisci il codice di verifica',
  });

  String get newPasswordRequired => _t({
    AppLocale.japanese: '新しいパスワードを入力してください',
    AppLocale.english: 'Please enter a new password',
    AppLocale.spanish: 'Por favor, introduce una nueva contraseña',
    AppLocale.chinese: '请输入新密码',
    AppLocale.korean: '새 비밀번호를 입력해주세요',
    AppLocale.french: 'Veuillez saisir un nouveau mot de passe',
    AppLocale.german: 'Bitte geben Sie ein neues Passwort ein',
    AppLocale.italian: 'Inserisci una nuova password',
  });

  String get confirmNewPasswordRequired => _t({
    AppLocale.japanese: '新しいパスワードを確認してください',
    AppLocale.english: 'Please confirm your new password',
    AppLocale.spanish: 'Por favor, confirma tu nueva contraseña',
    AppLocale.chinese: '请确认您的新密码',
    AppLocale.korean: '새 비밀번호를 확인해주세요',
    AppLocale.french: 'Veuillez confirmer votre nouveau mot de passe',
    AppLocale.german: 'Bitte bestätigen Sie Ihr neues Passwort',
    AppLocale.italian: 'Conferma la nuova password',
  });

  String get failedToLoadDiary => _t({
    AppLocale.japanese: '日記の読み込みに失敗しました',
    AppLocale.english: 'Failed to load diary',
    AppLocale.spanish: 'Error al cargar el diario',
    AppLocale.chinese: '加载日记失败',
    AppLocale.korean: '일기를 불러오지 못했습니다',
    AppLocale.french: 'Échec du chargement du journal',
    AppLocale.german: 'Tagebuch konnte nicht geladen werden',
    AppLocale.italian: 'Impossibile caricare il diario',
  });

  // --- Notification / Dialog strings ---

  String get dailyCorrectionLimitReached => _t({
    AppLocale.japanese: '本日の添削回数の上限に達しました',
    AppLocale.english: 'Daily Correction Limit Reached',
    AppLocale.spanish: 'Límite diario de correcciones alcanzado',
    AppLocale.chinese: '已达每日修改上限',
    AppLocale.korean: '일일 교정 한도에 도달했습니다',
    AppLocale.french: 'Limite de corrections quotidienne atteinte',
    AppLocale.german: 'Tägliches Korrekturlimit erreicht',
    AppLocale.italian: 'Limite giornaliero di correzioni raggiunto',
  });

  String correctionLimitBody(int remainingBonus) => _t({
    AppLocale.japanese: '本日の無料添削を使い切りました。\n\n短い広告を見て、ボーナス添削を1回獲得しましょう！\n(本日のボーナス添削残り$remainingBonus回)\n\n視聴後、もう一度「AI添削を実行」をタップしてください。',
    AppLocale.english: 'You\'ve used your free corrections for today.\n\nWatch a short ad to get 1 bonus correction!\n($remainingBonus bonus corrections remaining today)\n\nAfter watching, tap "Run AI Correction" again to use your bonus.',
    AppLocale.spanish: 'Has usado tus correcciones gratuitas de hoy.\n\nMira un breve anuncio para obtener 1 corrección extra.\n($remainingBonus correcciones extra restantes hoy)\n\nDespués de ver el anuncio, toca "Ejecutar corrección IA" de nuevo.',
    AppLocale.chinese: '您今天的免费修改次数已用完。\n\n观看一段短广告即可获得1次额外修改！\n(今天还剩$remainingBonus次额外修改)\n\n观看后，再次点击"运行AI修改"即可使用。',
    AppLocale.korean: '오늘의 무료 교정을 모두 사용했습니다.\n\n짧은 광고를 시청하고 보너스 교정 1회를 받으세요!\n(오늘 남은 보너스 교정 $remainingBonus회)\n\n시청 후 "AI 교정 실행"을 다시 탭하세요.',
    AppLocale.french: 'Vous avez utilisé vos corrections gratuites aujourd\'hui.\n\nRegardez une courte publicité pour obtenir 1 correction bonus !\n($remainingBonus corrections bonus restantes aujourd\'hui)\n\nAprès le visionnage, appuyez à nouveau sur "Lancer la correction IA".',
    AppLocale.german: 'Sie haben Ihre kostenlosen Korrekturen für heute aufgebraucht.\n\nSchauen Sie eine kurze Werbung für 1 Bonuskorrektur!\n($remainingBonus Bonuskorrekturen heute übrig)\n\nTippen Sie danach erneut auf "KI-Korrektur starten".',
    AppLocale.italian: 'Hai esaurito le correzioni gratuite di oggi.\n\nGuarda un breve annuncio per ottenere 1 correzione bonus!\n($remainingBonus correzioni bonus rimanenti oggi)\n\nDopo la visione, tocca di nuovo "Esegui correzione IA".',
  });

  String get maxBonusReachedBody => _t({
    AppLocale.japanese: '本日の添削回数（ボーナス含む）をすべて使い切りました。\n\n明日また無料添削をご利用いただけます。プレミアムにアップグレードすると、AI添削が無制限になります！',
    AppLocale.english: 'You\'ve used all your corrections for today, including bonus corrections.\n\nCome back tomorrow for more free corrections, or upgrade to Premium for unlimited AI corrections!',
    AppLocale.spanish: 'Has usado todas tus correcciones de hoy, incluidas las extra.\n\nVuelve mañana para más correcciones gratuitas, o actualiza a Premium para correcciones ilimitadas.',
    AppLocale.chinese: '您今天的所有修改次数（包括额外次数）已用完。\n\n明天回来享受更多免费修改，或升级到高级版获得无限AI修改！',
    AppLocale.korean: '오늘의 모든 교정(보너스 포함)을 사용했습니다.\n\n내일 다시 무료 교정을 이용하거나, 프리미엄으로 업그레이드하여 무제한 AI 교정을 받으세요!',
    AppLocale.french: 'Vous avez utilisé toutes vos corrections aujourd\'hui, y compris les bonus.\n\nRevenez demain pour plus de corrections gratuites, ou passez à Premium pour des corrections IA illimitées !',
    AppLocale.german: 'Sie haben alle Korrekturen für heute aufgebraucht, einschließlich Bonuskorrekturen.\n\nKommen Sie morgen für mehr kostenlose Korrekturen wieder, oder upgraden Sie auf Premium für unbegrenzte KI-Korrekturen!',
    AppLocale.italian: 'Hai esaurito tutte le correzioni di oggi, incluse quelle bonus.\n\nTorna domani per altre correzioni gratuite, o passa a Premium per correzioni IA illimitate!',
  });

  String get bonusCorrectionGranted => _t({
    AppLocale.japanese: 'ボーナス添削を獲得しました！「AI添削を実行」をタップして使用してください。',
    AppLocale.english: 'Bonus correction granted! Tap "Run AI Correction" to use it.',
    AppLocale.spanish: '¡Corrección extra obtenida! Toca "Ejecutar corrección IA" para usarla.',
    AppLocale.chinese: '已获得额外修改！点击"运行AI修改"即可使用。',
    AppLocale.korean: '보너스 교정을 받았습니다! "AI 교정 실행"을 탭하여 사용하세요.',
    AppLocale.french: 'Correction bonus accordée ! Appuyez sur "Lancer la correction IA" pour l\'utiliser.',
    AppLocale.german: 'Bonuskorrektur erhalten! Tippen Sie auf "KI-Korrektur starten", um sie zu nutzen.',
    AppLocale.italian: 'Correzione bonus ottenuta! Tocca "Esegui correzione IA" per usarla.',
  });

  String failedToGrantBonus(String error) => _t({
    AppLocale.japanese: 'ボーナスの付与に失敗しました: $error',
    AppLocale.english: 'Failed to grant bonus: $error',
    AppLocale.spanish: 'Error al otorgar el bono: $error',
    AppLocale.chinese: '无法授予奖励: $error',
    AppLocale.korean: '보너스 부여 실패: $error',
    AppLocale.french: 'Échec de l\'attribution du bonus : $error',
    AppLocale.german: 'Bonus konnte nicht gewährt werden: $error',
    AppLocale.italian: 'Impossibile concedere il bonus: $error',
  });

  String get correctionLimitReached403 => _t({
    AppLocale.japanese: '本日の添削回数の上限に達しました。明日再度お試しいただくか、広告を視聴してボーナス添削を獲得してください。',
    AppLocale.english: 'Daily correction limit reached. Try again tomorrow or watch an ad for bonus corrections.',
    AppLocale.spanish: 'Límite diario de correcciones alcanzado. Inténtalo mañana o mira un anuncio para correcciones extra.',
    AppLocale.chinese: '已达每日修改上限。请明天再试或观看广告获得额外修改。',
    AppLocale.korean: '일일 교정 한도에 도달했습니다. 내일 다시 시도하거나 광고를 시청하여 보너스 교정을 받으세요.',
    AppLocale.french: 'Limite de corrections quotidienne atteinte. Réessayez demain ou regardez une publicité pour des corrections bonus.',
    AppLocale.german: 'Tägliches Korrekturlimit erreicht. Versuchen Sie es morgen erneut oder schauen Sie eine Werbung für Bonuskorrekturen.',
    AppLocale.italian: 'Limite giornaliero di correzioni raggiunto. Riprova domani o guarda un annuncio per correzioni bonus.',
  });

  String failedToUpdate(String error) => _t({
    AppLocale.japanese: '更新に失敗しました: $error',
    AppLocale.english: 'Failed to update: $error',
    AppLocale.spanish: 'Error al actualizar: $error',
    AppLocale.chinese: '更新失败: $error',
    AppLocale.korean: '업데이트 실패: $error',
    AppLocale.french: 'Échec de la mise à jour : $error',
    AppLocale.german: 'Aktualisierung fehlgeschlagen: $error',
    AppLocale.italian: 'Aggiornamento non riuscito: $error',
  });

  String failedToSave(String error) => _t({
    AppLocale.japanese: '保存に失敗しました: $error',
    AppLocale.english: 'Failed to save: $error',
    AppLocale.spanish: 'Error al guardar: $error',
    AppLocale.chinese: '保存失败: $error',
    AppLocale.korean: '저장 실패: $error',
    AppLocale.french: 'Échec de la sauvegarde : $error',
    AppLocale.german: 'Speichern fehlgeschlagen: $error',
    AppLocale.italian: 'Salvataggio non riuscito: $error',
  });

  String failedToDelete(String error) => _t({
    AppLocale.japanese: '削除に失敗しました: $error',
    AppLocale.english: 'Failed to delete: $error',
    AppLocale.spanish: 'Error al eliminar: $error',
    AppLocale.chinese: '删除失败: $error',
    AppLocale.korean: '삭제 실패: $error',
    AppLocale.french: 'Échec de la suppression : $error',
    AppLocale.german: 'Löschen fehlgeschlagen: $error',
    AppLocale.italian: 'Eliminazione non riuscita: $error',
  });

  String get analyzingHandwriting => _t({
    AppLocale.japanese: 'AIで手書きを解析中...',
    AppLocale.english: 'Analyzing handwriting with AI...',
    AppLocale.spanish: 'Analizando escritura con IA...',
    AppLocale.chinese: '正在用AI分析手写内容...',
    AppLocale.korean: 'AI로 손글씨 분석 중...',
    AppLocale.french: 'Analyse de l\'écriture avec l\'IA...',
    AppLocale.german: 'Handschrift wird mit KI analysiert...',
    AppLocale.italian: 'Analisi della scrittura con IA...',
  });

  String failedToCaptureImage(String error) => _t({
    AppLocale.japanese: '画像の撮影に失敗しました: $error',
    AppLocale.english: 'Failed to capture image: $error',
    AppLocale.spanish: 'Error al capturar imagen: $error',
    AppLocale.chinese: '拍摄失败: $error',
    AppLocale.korean: '이미지 촬영 실패: $error',
    AppLocale.french: 'Échec de la capture d\'image : $error',
    AppLocale.german: 'Bildaufnahme fehlgeschlagen: $error',
    AppLocale.italian: 'Acquisizione immagine non riuscita: $error',
  });

  String get noTextDetected => _t({
    AppLocale.japanese: 'テキストが検出されませんでした。手書きが見えるようにしてください。',
    AppLocale.english: 'No text detected. Make sure the handwriting is visible.',
    AppLocale.spanish: 'No se detectó texto. Asegúrate de que la escritura sea visible.',
    AppLocale.chinese: '未检测到文字。请确保手写内容清晰可见。',
    AppLocale.korean: '텍스트가 감지되지 않았습니다. 손글씨가 보이는지 확인하세요.',
    AppLocale.french: 'Aucun texte détecté. Assurez-vous que l\'écriture est visible.',
    AppLocale.german: 'Kein Text erkannt. Stellen Sie sicher, dass die Handschrift sichtbar ist.',
    AppLocale.italian: 'Nessun testo rilevato. Assicurati che la scrittura sia visibile.',
  });

  String get textRecognizedSuccessfully => _t({
    AppLocale.japanese: 'テキストの認識に成功しました！',
    AppLocale.english: 'Text recognized successfully!',
    AppLocale.spanish: '¡Texto reconocido con éxito!',
    AppLocale.chinese: '文字识别成功！',
    AppLocale.korean: '텍스트 인식 성공!',
    AppLocale.french: 'Texte reconnu avec succès !',
    AppLocale.german: 'Text erfolgreich erkannt!',
    AppLocale.italian: 'Testo riconosciuto con successo!',
  });

  String failedToProcessImage(String error) => _t({
    AppLocale.japanese: '画像の処理に失敗しました: $error',
    AppLocale.english: 'Failed to process image: $error',
    AppLocale.spanish: 'Error al procesar imagen: $error',
    AppLocale.chinese: '图片处理失败: $error',
    AppLocale.korean: '이미지 처리 실패: $error',
    AppLocale.french: 'Échec du traitement de l\'image : $error',
    AppLocale.german: 'Bildverarbeitung fehlgeschlagen: $error',
    AppLocale.italian: 'Elaborazione immagine non riuscita: $error',
  });

  String get pleaseEnterCompleteCode => _t({
    AppLocale.japanese: '6桁のコードをすべて入力してください',
    AppLocale.english: 'Please enter the complete 6-digit code',
    AppLocale.spanish: 'Por favor, introduce el código completo de 6 dígitos',
    AppLocale.chinese: '请输入完整的6位验证码',
    AppLocale.korean: '6자리 코드를 모두 입력해 주세요',
    AppLocale.french: 'Veuillez saisir le code complet à 6 chiffres',
    AppLocale.german: 'Bitte geben Sie den vollständigen 6-stelligen Code ein',
    AppLocale.italian: 'Inserisci il codice completo a 6 cifre',
  });

  String get emailVerifiedPleaseSignIn => _t({
    AppLocale.japanese: 'メールアドレスが確認されました！ログインしてください。',
    AppLocale.english: 'Email verified! Please sign in.',
    AppLocale.spanish: '¡Correo verificado! Por favor, inicia sesión.',
    AppLocale.chinese: '邮箱验证成功！请登录。',
    AppLocale.korean: '이메일 인증 완료! 로그인해 주세요.',
    AppLocale.french: 'E-mail vérifié ! Veuillez vous connecter.',
    AppLocale.german: 'E-Mail verifiziert! Bitte melden Sie sich an.',
    AppLocale.italian: 'Email verificata! Accedi.',
  });

  String get verificationCodeSent => _t({
    AppLocale.japanese: '確認コードを送信しました！',
    AppLocale.english: 'Verification code sent!',
    AppLocale.spanish: '¡Código de verificación enviado!',
    AppLocale.chinese: '验证码已发送！',
    AppLocale.korean: '인증 코드가 전송되었습니다!',
    AppLocale.french: 'Code de vérification envoyé !',
    AppLocale.german: 'Bestätigungscode gesendet!',
    AppLocale.italian: 'Codice di verifica inviato!',
  });

  String get signUpSuccessPleaseLogIn => _t({
    AppLocale.japanese: '登録が完了しました！ログインしてください。',
    AppLocale.english: 'Successfully signed up! Please log in.',
    AppLocale.spanish: '¡Registro exitoso! Por favor, inicia sesión.',
    AppLocale.chinese: '注册成功！请登录。',
    AppLocale.korean: '가입 성공! 로그인해 주세요.',
    AppLocale.french: 'Inscription réussie ! Veuillez vous connecter.',
    AppLocale.german: 'Erfolgreich registriert! Bitte melden Sie sich an.',
    AppLocale.italian: 'Registrazione completata! Accedi.',
  });

  String get checkEmailForVerificationCode => _t({
    AppLocale.japanese: 'メールに届いた確認コードをご確認ください',
    AppLocale.english: 'Please check your email for verification code',
    AppLocale.spanish: 'Revisa tu correo para el código de verificación',
    AppLocale.chinese: '请查看邮箱中的验证码',
    AppLocale.korean: '이메일에서 인증 코드를 확인해 주세요',
    AppLocale.french: 'Veuillez vérifier votre e-mail pour le code de vérification',
    AppLocale.german: 'Bitte überprüfen Sie Ihre E-Mail auf den Bestätigungscode',
    AppLocale.italian: 'Controlla la tua email per il codice di verifica',
  });

  String improveWriting(String languageName) => _t({
    AppLocale.japanese: '$languageNameのライティングを上達させよう',
    AppLocale.english: 'Improve your $languageName writing',
    AppLocale.spanish: 'Mejora tu escritura en $languageName',
    AppLocale.chinese: '提升你的${languageName}写作能力',
    AppLocale.korean: '$languageName 작문 실력을 향상시키세요',
    AppLocale.french: 'Améliorez votre écriture en $languageName',
    AppLocale.german: 'Verbessern Sie Ihr $languageName-Schreiben',
    AppLocale.italian: 'Migliora la tua scrittura in $languageName',
  });

  String get logIn => _t({
    AppLocale.japanese: 'ログイン',
    AppLocale.english: 'Log In',
    AppLocale.spanish: 'Iniciar sesión',
    AppLocale.chinese: '登录',
    AppLocale.korean: '로그인',
    AppLocale.french: 'Se connecter',
    AppLocale.german: 'Anmelden',
    AppLocale.italian: 'Accedi',
  });

  String get signUp => _t({
    AppLocale.japanese: '新規登録',
    AppLocale.english: 'Sign Up',
    AppLocale.spanish: 'Registrarse',
    AppLocale.chinese: '注册',
    AppLocale.korean: '가입',
    AppLocale.french: 'S\'inscrire',
    AppLocale.german: 'Registrieren',
    AppLocale.italian: 'Registrati',
  });

  String get verifyEmail => _t({
    AppLocale.japanese: 'メール認証',
    AppLocale.english: 'Verify Email',
    AppLocale.spanish: 'Verificar correo',
    AppLocale.chinese: '验证邮箱',
    AppLocale.korean: '이메일 인증',
    AppLocale.french: 'Vérifier l\'e-mail',
    AppLocale.german: 'E-Mail verifizieren',
    AppLocale.italian: 'Verifica email',
  });

  String get resend => _t({
    AppLocale.japanese: '再送信',
    AppLocale.english: 'Resend',
    AppLocale.spanish: 'Reenviar',
    AppLocale.chinese: '重新发送',
    AppLocale.korean: '재전송',
    AppLocale.french: 'Renvoyer',
    AppLocale.german: 'Erneut senden',
    AppLocale.italian: 'Reinvia',
  });

  String get openSettings => _t({
    AppLocale.japanese: '設定を開く',
    AppLocale.english: 'Open Settings',
    AppLocale.spanish: 'Abrir ajustes',
    AppLocale.chinese: '打开设置',
    AppLocale.korean: '설정 열기',
    AppLocale.french: 'Ouvrir les paramètres',
    AppLocale.german: 'Einstellungen öffnen',
    AppLocale.italian: 'Apri impostazioni',
  });

  String get tryAgain => _t({
    AppLocale.japanese: 'もう一度',
    AppLocale.english: 'Try Again',
    AppLocale.spanish: 'Intentar de nuevo',
    AppLocale.chinese: '重试',
    AppLocale.korean: '다시 시도',
    AppLocale.french: 'Réessayer',
    AppLocale.german: 'Erneut versuchen',
    AppLocale.italian: 'Riprova',
  });

  // --- Camera Permission strings ---

  String get cameraPermissionRequired => _t({
    AppLocale.japanese: '日記をスキャンするにはカメラのアクセス許可が必要です。',
    AppLocale.english: 'Camera permission is required to scan your diary.',
    AppLocale.spanish: 'Se requiere permiso de cámara para escanear tu diario.',
    AppLocale.chinese: '扫描日记需要相机权限。',
    AppLocale.korean: '일기를 스캔하려면 카메라 권한이 필요합니다.',
    AppLocale.french: 'L\'autorisation de la caméra est requise pour scanner votre journal.',
    AppLocale.german: 'Kamerazugriff erforderlich, um Ihr Tagebuch zu scannen.',
    AppLocale.italian: 'L\'autorizzazione della fotocamera è necessaria per scansionare il diario.',
  });

  String get cameraPermissionPermanentlyDenied => _t({
    AppLocale.japanese: 'カメラへのアクセスが拒否されています。設定からカメラを有効にしてください。',
    AppLocale.english: 'Camera permission is permanently denied.\nPlease enable it in Settings.',
    AppLocale.spanish: 'Permiso de cámara denegado permanentemente.\nActívalo en Configuración.',
    AppLocale.chinese: '相机权限被永久拒绝。\n请在设置中启用它。',
    AppLocale.korean: '카메라 권한이 영구적으로 거부되었습니다.\n설정에서 활성화해 주세요.',
    AppLocale.french: 'Autorisation caméra refusée définitivement.\nActivez-la dans les Paramètres.',
    AppLocale.german: 'Kamerazugriff dauerhaft verweigert.\nBitte in den Einstellungen aktivieren.',
    AppLocale.italian: 'Autorizzazione fotocamera negata definitivamente.\nAbilitala nelle Impostazioni.',
  });

  String get noCameraFound => _t({
    AppLocale.japanese: 'このデバイスにはカメラが見つかりません。',
    AppLocale.english: 'No camera found on this device.',
    AppLocale.spanish: 'No se encontró cámara en este dispositivo.',
    AppLocale.chinese: '此设备上未找到相机。',
    AppLocale.korean: '이 기기에서 카메라를 찾을 수 없습니다.',
    AppLocale.french: 'Aucune caméra trouvée sur cet appareil.',
    AppLocale.german: 'Keine Kamera auf diesem Gerät gefunden.',
    AppLocale.italian: 'Nessuna fotocamera trovata su questo dispositivo.',
  });

  String cameraError(String desc) => _t({
    AppLocale.japanese: 'カメラエラー: $desc',
    AppLocale.english: 'Camera error: $desc',
    AppLocale.spanish: 'Error de cámara: $desc',
    AppLocale.chinese: '相机错误：$desc',
    AppLocale.korean: '카메라 오류: $desc',
    AppLocale.french: 'Erreur caméra : $desc',
    AppLocale.german: 'Kamerafehler: $desc',
    AppLocale.italian: 'Errore fotocamera: $desc',
  });

  // --- SRS (Spaced Repetition) strings ---

  String get srAgain => _t({
    AppLocale.japanese: 'もう一度',
    AppLocale.english: 'Again',
    AppLocale.spanish: 'Otra vez',
    AppLocale.chinese: '再来一次',
    AppLocale.korean: '다시',
    AppLocale.french: 'Encore',
    AppLocale.german: 'Nochmal',
    AppLocale.italian: 'Ancora',
  });

  String get srHard => _t({
    AppLocale.japanese: '難しい',
    AppLocale.english: 'Hard',
    AppLocale.spanish: 'Difícil',
    AppLocale.chinese: '困难',
    AppLocale.korean: '어려움',
    AppLocale.french: 'Difficile',
    AppLocale.german: 'Schwer',
    AppLocale.italian: 'Difficile',
  });

  String get srGood => _t({
    AppLocale.japanese: '良い',
    AppLocale.english: 'Good',
    AppLocale.spanish: 'Bien',
    AppLocale.chinese: '良好',
    AppLocale.korean: '좋음',
    AppLocale.french: 'Bien',
    AppLocale.german: 'Gut',
    AppLocale.italian: 'Bene',
  });

  String get srEasy => _t({
    AppLocale.japanese: '簡単',
    AppLocale.english: 'Easy',
    AppLocale.spanish: 'Fácil',
    AppLocale.chinese: '简单',
    AppLocale.korean: '쉬움',
    AppLocale.french: 'Facile',
    AppLocale.german: 'Einfach',
    AppLocale.italian: 'Facile',
  });

  String get allCaughtUp => _t({
    AppLocale.japanese: '復習完了！',
    AppLocale.english: 'All Caught Up!',
    AppLocale.spanish: '¡Todo al día!',
    AppLocale.chinese: '全部复习完毕！',
    AppLocale.korean: '모두 복습했어요!',
    AppLocale.french: 'Tout est à jour !',
    AppLocale.german: 'Alles erledigt!',
    AppLocale.italian: 'Tutto in pari!',
  });

  String get allCaughtUpDesc => _t({
    AppLocale.japanese: '今日の復習カードはすべて完了しました。また後でチェックしましょう！',
    AppLocale.english: 'You\'ve reviewed all due cards for today. Check back later!',
    AppLocale.spanish: 'Has repasado todas las tarjetas programadas para hoy. ¡Vuelve más tarde!',
    AppLocale.chinese: '您已复习了今天所有到期的卡片。稍后再来看看！',
    AppLocale.korean: '오늘의 복습 카드를 모두 완료했습니다. 나중에 다시 확인하세요!',
    AppLocale.french: 'Vous avez revu toutes les cartes du jour. Revenez plus tard !',
    AppLocale.german: 'Sie haben alle fälligen Karten für heute überprüft. Schauen Sie später wieder vorbei!',
    AppLocale.italian: 'Hai rivisto tutte le schede in scadenza per oggi. Torna più tardi!',
  });

  String get dueCards => _t({
    AppLocale.japanese: '復習カード',
    AppLocale.english: 'Due Cards',
    AppLocale.spanish: 'Tarjetas pendientes',
    AppLocale.chinese: '待复习',
    AppLocale.korean: '복습 카드',
    AppLocale.french: 'Cartes à réviser',
    AppLocale.german: 'Fällige Karten',
    AppLocale.italian: 'Schede da rivedere',
  });

  String get showAllCards => _t({
    AppLocale.japanese: 'すべてのカード',
    AppLocale.english: 'All Cards',
    AppLocale.spanish: 'Todas las tarjetas',
    AppLocale.chinese: '所有卡片',
    AppLocale.korean: '모든 카드',
    AppLocale.french: 'Toutes les cartes',
    AppLocale.german: 'Alle Karten',
    AppLocale.italian: 'Tutte le schede',
  });

  String get howWasIt => _t({
    AppLocale.japanese: '覚えていましたか？',
    AppLocale.english: 'How did you do?',
    AppLocale.spanish: '¿Cómo te fue?',
    AppLocale.chinese: '你记住了吗？',
    AppLocale.korean: '얼마나 잘 기억했나요?',
    AppLocale.french: 'Comment ça s\'est passé ?',
    AppLocale.german: 'Wie war es?',
    AppLocale.italian: 'Come è andata?',
  });

  String nextReviewIn(int days) => _t({
    AppLocale.japanese: days == 1 ? '次回: 明日' : '次回: $days日後',
    AppLocale.english: days == 1 ? 'Next review: Tomorrow' : 'Next review: in $days days',
    AppLocale.spanish: days == 1 ? 'Próxima revisión: mañana' : 'Próxima revisión: en $days días',
    AppLocale.chinese: days == 1 ? '下次复习：明天' : '下次复习：$days天后',
    AppLocale.korean: days == 1 ? '다음 복습: 내일' : '다음 복습: $days일 후',
    AppLocale.french: days == 1 ? 'Prochaine révision : demain' : 'Prochaine révision : dans $days jours',
    AppLocale.german: days == 1 ? 'Nächste Wiederholung: morgen' : 'Nächste Wiederholung: in $days Tagen',
    AppLocale.italian: days == 1 ? 'Prossima revisione: domani' : 'Prossima revisione: tra $days giorni',
  });

  String dueCardsCount(int count) => _t({
    AppLocale.japanese: '$count枚',
    AppLocale.english: '$count due',
    AppLocale.spanish: '$count pendientes',
    AppLocale.chinese: '$count个待复习',
    AppLocale.korean: '$count개 복습',
    AppLocale.french: '$count à réviser',
    AppLocale.german: '$count fällig',
    AppLocale.italian: '$count da rivedere',
  });

  // --- Subscription Status strings ---

  String get subscriptionActive => _t({
    AppLocale.japanese: 'プレミアム有効',
    AppLocale.english: 'Premium Active',
    AppLocale.spanish: 'Premium activo',
    AppLocale.chinese: '高级版有效',
    AppLocale.korean: '프리미엄 활성',
    AppLocale.french: 'Premium actif',
    AppLocale.german: 'Premium aktiv',
    AppLocale.italian: 'Premium attivo',
  });

  String get subscriptionCanceling => _t({
    AppLocale.japanese: 'キャンセル予定',
    AppLocale.english: 'Canceling',
    AppLocale.spanish: 'Cancelando',
    AppLocale.chinese: '即将取消',
    AppLocale.korean: '취소 예정',
    AppLocale.french: 'En cours d\'annulation',
    AppLocale.german: 'Wird gekündigt',
    AppLocale.italian: 'In cancellazione',
  });

  String get subscriptionBillingIssue => _t({
    AppLocale.japanese: '支払いに問題があります',
    AppLocale.english: 'Billing Issue',
    AppLocale.spanish: 'Problema de facturación',
    AppLocale.chinese: '计费问题',
    AppLocale.korean: '결제 문제',
    AppLocale.french: 'Problème de facturation',
    AppLocale.german: 'Abrechnungsproblem',
    AppLocale.italian: 'Problema di fatturazione',
  });

  String get subscriptionGracePeriod => _t({
    AppLocale.japanese: 'グレース期間中',
    AppLocale.english: 'Grace Period',
    AppLocale.spanish: 'Período de gracia',
    AppLocale.chinese: '宽限期',
    AppLocale.korean: '유예 기간',
    AppLocale.french: 'Période de grâce',
    AppLocale.german: 'Nachfrist',
    AppLocale.italian: 'Periodo di grazia',
  });

  String get subscriptionExpired => _t({
    AppLocale.japanese: '期限切れ',
    AppLocale.english: 'Expired',
    AppLocale.spanish: 'Caducado',
    AppLocale.chinese: '已过期',
    AppLocale.korean: '만료됨',
    AppLocale.french: 'Expiré',
    AppLocale.german: 'Abgelaufen',
    AppLocale.italian: 'Scaduto',
  });

  String subscriptionRenewsOn(String date) => _t({
    AppLocale.japanese: '次回更新日: $date',
    AppLocale.english: 'Renews on $date',
    AppLocale.spanish: 'Se renueva el $date',
    AppLocale.chinese: '续订日期：$date',
    AppLocale.korean: '갱신일: $date',
    AppLocale.french: 'Renouvellement le $date',
    AppLocale.german: 'Verlängerung am $date',
    AppLocale.italian: 'Rinnovo il $date',
  });

  String subscriptionAccessUntil(String date) => _t({
    AppLocale.japanese: 'アクセス期限: $date',
    AppLocale.english: 'Access until $date',
    AppLocale.spanish: 'Acceso hasta $date',
    AppLocale.chinese: '访问有效期至：$date',
    AppLocale.korean: '$date까지 이용 가능',
    AppLocale.french: 'Accès jusqu\'au $date',
    AppLocale.german: 'Zugang bis $date',
    AppLocale.italian: 'Accesso fino al $date',
  });

  String get updatePaymentMethod => _t({
    AppLocale.japanese: '支払い方法を更新',
    AppLocale.english: 'Update Payment Method',
    AppLocale.spanish: 'Actualizar método de pago',
    AppLocale.chinese: '更新支付方式',
    AppLocale.korean: '결제 수단 업데이트',
    AppLocale.french: 'Mettre à jour le mode de paiement',
    AppLocale.german: 'Zahlungsmethode aktualisieren',
    AppLocale.italian: 'Aggiorna metodo di pagamento',
  });

  String get manageSubscription => _t({
    AppLocale.japanese: 'サブスクリプションを管理',
    AppLocale.english: 'Manage Subscription',
    AppLocale.spanish: 'Gestionar suscripción',
    AppLocale.chinese: '管理订阅',
    AppLocale.korean: '구독 관리',
    AppLocale.french: 'Gérer l\'abonnement',
    AppLocale.german: 'Abonnement verwalten',
    AppLocale.italian: 'Gestisci abbonamento',
  });
}

/// Provider for localized strings
final stringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(locale);
});
