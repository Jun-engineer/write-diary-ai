import 'package:flutter/material.dart';
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
}

/// Provider for localized strings
final stringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(locale);
});
