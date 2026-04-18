import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/config/amplifyconfiguration.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for all supported locales
  await initializeDateFormatting();
  
  // Initialize Amplify
  await _configureAmplify();
  
  // Initialize AdMob (ATT dialog is requested after first frame in AdService)
  await AdService.initialize();

  // Check if language has been selected before
  final localeNotifier = LocaleNotifier();
  final isSelected = await localeNotifier.isLanguageSelected();
  
  runApp(
    ProviderScope(
      overrides: [
        languageSelectedProvider.overrideWith((ref) => isSelected),
      ],
      child: const WriteDiaryAiApp(),
    ),
  );
}

Future<void> _configureAmplify() async {
  try {
    final authPlugin = AmplifyAuthCognito();
    await Amplify.addPlugins([authPlugin]);
    await Amplify.configure(amplifyconfig);
    safePrint('Amplify configured successfully');
  } on Exception catch (e) {
    safePrint('Error configuring Amplify: $e');
  }
}

class WriteDiaryAiApp extends ConsumerWidget {
  const WriteDiaryAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final appLocale = ref.watch(localeProvider);
    
    return MaterialApp.router(
      title: 'Write Diary AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      locale: appLocale.toLocale(),
      supportedLocales: AppLocale.values.map((l) => l.toLocale()),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
