import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/locale_provider.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // App icon
              Icon(
                Icons.auto_stories,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Write Diary AI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              // Title in multiple languages
              const Text(
                'Select your language',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const Text(
                '言語を選択してください',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              // Language list
              Expanded(
                child: ListView.builder(
                  itemCount: AppLocale.values.length,
                  itemBuilder: (context, index) {
                    final locale = AppLocale.values[index];
                    final isSelected = locale == currentLocale;
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
                          locale.displayName,
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
                          ref.read(localeProvider.notifier).setLocale(locale);
                        },
                      ),
                    );
                  },
                ),
              ),
              // Continue button
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () async {
                      await ref
                          .read(localeProvider.notifier)
                          .completeLanguageSelection();
                      ref.read(languageSelectedProvider.notifier).state = true;
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    child: Text(
                      _getContinueText(currentLocale),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getContinueText(AppLocale locale) {
    switch (locale) {
      case AppLocale.japanese:
        return '続ける';
      case AppLocale.english:
        return 'Continue';
      case AppLocale.spanish:
        return 'Continuar';
      case AppLocale.chinese:
        return '继续';
      case AppLocale.korean:
        return '계속하다';
      case AppLocale.french:
        return 'Continuer';
      case AppLocale.german:
        return 'Weiter';
      case AppLocale.italian:
        return 'Continua';
    }
  }
}
