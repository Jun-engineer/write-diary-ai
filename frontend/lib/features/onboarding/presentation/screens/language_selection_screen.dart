import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/locale_provider.dart';

/// Tracks current step: 0 = native language, 1 = target language
final _onboardingStepProvider = StateProvider<int>((ref) => 0);

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(_onboardingStepProvider);
    final targetLocale = ref.watch(onboardingTargetLanguageProvider);
    final nativeLocale = ref.watch(localeProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // App icon
              Icon(
                Icons.auto_stories,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Write Diary AI',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Step indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepDot(active: step == 0),
                  const SizedBox(width: 8),
                  _StepDot(active: step == 1),
                ],
              ),
              const SizedBox(height: 24),
              // Title changes based on step
              if (step == 0) ...[
                // Step 1: Native language - show in the language being selected
                Text(
                  _getNativeTitle(nativeLocale),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _getNativeSubtitle(nativeLocale),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                // Step 2: Target language - show in the user's native language
                Text(
                  _getTargetTitle(nativeLocale),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _getTargetSubtitle(nativeLocale),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              // Language list
              Expanded(
                child: ListView.builder(
                  itemCount: AppLocale.values.length,
                  itemBuilder: (context, index) {
                    final locale = AppLocale.values[index];
                    final isSelected = step == 0
                        ? locale == nativeLocale
                        : locale == targetLocale;
                    return Card(
                      elevation: isSelected ? 2 : 0,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected
                            ? BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        title: Text(
                          step == 0
                              ? locale.displayName
                              : ref.read(stringsProvider).getLanguageName(locale.code),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () {
                          if (step == 0) {
                            // Native language - updates UI language immediately
                            ref.read(localeProvider.notifier).setLocale(locale);
                          } else {
                            // Target language
                            ref.read(onboardingTargetLanguageProvider.notifier).state = locale;
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              // Buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Row(
                  children: [
                    // Back button (only on step 1)
                    if (step == 1) ...[
                      SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () {
                            ref.read(_onboardingStepProvider.notifier).state = 0;
                          },
                          child: Text(
                            _getBackText(nativeLocale),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    // Next / Continue button
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () async {
                            if (step == 0) {
                              // Go to step 2: target language
                              ref.read(_onboardingStepProvider.notifier).state = 1;
                            } else {
                              // Save both selections and proceed
                              await ref
                                  .read(localeProvider.notifier)
                                  .setOnboardingTargetLanguage(targetLocale);
                              await ref
                                  .read(localeProvider.notifier)
                                  .setOnboardingNativeLanguage(nativeLocale);
                              await ref
                                  .read(localeProvider.notifier)
                                  .completeLanguageSelection();
                              ref.read(languageSelectedProvider.notifier).state = true;
                              if (context.mounted) {
                                context.go('/login');
                              }
                            }
                          },
                          child: Text(
                            step == 0
                                ? _getNextText(nativeLocale)
                                : _getContinueText(nativeLocale),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTargetTitle(AppLocale locale) {
    const m = {
      AppLocale.japanese: '学びたい言語',
      AppLocale.english: 'Language you want to learn',
      AppLocale.spanish: 'Idioma que quieres aprender',
      AppLocale.chinese: '你想学的语言',
      AppLocale.korean: '배우고 싶은 언어',
      AppLocale.french: 'Langue que vous voulez apprendre',
      AppLocale.german: 'Sprache, die Sie lernen möchten',
      AppLocale.italian: 'Lingua che vuoi imparare',
    };
    return m[locale] ?? m[AppLocale.english]!;
  }

  String _getTargetSubtitle(AppLocale locale) {
    const m = {
      AppLocale.japanese: '日記を書く言語を選んでください',
      AppLocale.english: 'Choose the language to write your diary in',
      AppLocale.spanish: 'Elige el idioma para escribir tu diario',
      AppLocale.chinese: '选择写日记的语言',
      AppLocale.korean: '일기를 쓸 언어를 선택하세요',
      AppLocale.french: 'Choisissez la langue pour écrire votre journal',
      AppLocale.german: 'Wählen Sie die Sprache für Ihr Tagebuch',
      AppLocale.italian: 'Scegli la lingua per scrivere il tuo diario',
    };
    return m[locale] ?? m[AppLocale.english]!;
  }

  String _getNativeTitle(AppLocale locale) {
    const m = {
      AppLocale.japanese: '母国語',
      AppLocale.english: 'Your native language',
      AppLocale.spanish: 'Tu idioma nativo',
      AppLocale.chinese: '你的母语',
      AppLocale.korean: '모국어',
      AppLocale.french: 'Votre langue maternelle',
      AppLocale.german: 'Ihre Muttersprache',
      AppLocale.italian: 'La tua lingua madre',
    };
    return m[locale] ?? m[AppLocale.english]!;
  }

  String _getNativeSubtitle(AppLocale locale) {
    const m = {
      AppLocale.japanese: 'AI の解説で使用する言語です',
      AppLocale.english: 'Used for AI explanations and app UI',
      AppLocale.spanish: 'Se usa para explicaciones de IA y la interfaz',
      AppLocale.chinese: '用于AI解释和应用界面',
      AppLocale.korean: 'AI 설명 및 앱 UI에 사용됩니다',
      AppLocale.french: "Utilisée pour les explications de l'IA et l'interface",
      AppLocale.german: 'Wird für KI-Erklärungen und die App-Oberfläche verwendet',
      AppLocale.italian: "Usata per le spiegazioni dell'IA e l'interfaccia",
    };
    return m[locale] ?? m[AppLocale.english]!;
  }

  String _getNextText(AppLocale locale) {
    const m = {
      AppLocale.japanese: '次へ',
      AppLocale.english: 'Next',
      AppLocale.spanish: 'Siguiente',
      AppLocale.chinese: '下一步',
      AppLocale.korean: '다음',
      AppLocale.french: 'Suivant',
      AppLocale.german: 'Weiter',
      AppLocale.italian: 'Avanti',
    };
    return m[locale] ?? m[AppLocale.english]!;
  }

  String _getBackText(AppLocale locale) {
    const m = {
      AppLocale.japanese: '戻る',
      AppLocale.english: 'Back',
      AppLocale.spanish: 'Atrás',
      AppLocale.chinese: '返回',
      AppLocale.korean: '뒤로',
      AppLocale.french: 'Retour',
      AppLocale.german: 'Zurück',
      AppLocale.italian: 'Indietro',
    };
    return m[locale] ?? m[AppLocale.english]!;
  }

  String _getContinueText(AppLocale locale) {
    const m = {
      AppLocale.japanese: '続ける',
      AppLocale.english: 'Continue',
      AppLocale.spanish: 'Continuar',
      AppLocale.chinese: '继续',
      AppLocale.korean: '계속하다',
      AppLocale.french: 'Continuer',
      AppLocale.german: 'Starten',
      AppLocale.italian: 'Continua',
    };
    return m[locale] ?? m[AppLocale.english]!;
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
