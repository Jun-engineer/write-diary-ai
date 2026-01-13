import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/correction_mode_provider.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';

/// Provider for scan usage data
final scanUsageProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getScanUsage();
});

/// Provider for user profile data
final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getUserProfile();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isDeleting = false;

  String _getThemeModeText(ThemeMode mode, AppStrings s) {
    switch (mode) {
      case ThemeMode.system:
        return s.systemDefault;
      case ThemeMode.light:
        return s.lightMode;
      case ThemeMode.dark:
        return s.darkModeOption;
    }
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref, ThemeMode currentMode, AppStrings s) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(s.selectTheme),
        children: [
          RadioListTile<ThemeMode>(
            title: Text(s.systemDefault),
            value: ThemeMode.system,
            groupValue: currentMode,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).setThemeMode(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(s.lightMode),
            value: ThemeMode.light,
            groupValue: currentMode,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).setThemeMode(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(s.darkModeOption),
            value: ThemeMode.dark,
            groupValue: currentMode,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).setThemeMode(value!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, AppLocale currentLocale, AppStrings s) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(s.selectLanguage),
        children: [
          RadioListTile<AppLocale>(
            title: const Text('日本語'),
            value: AppLocale.japanese,
            groupValue: currentLocale,
            onChanged: (value) {
              ref.read(localeProvider.notifier).setLocale(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<AppLocale>(
            title: const Text('English'),
            value: AppLocale.english,
            groupValue: currentLocale,
            onChanged: (value) {
              ref.read(localeProvider.notifier).setLocale(value!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showCorrectionModeDialog(BuildContext context, WidgetRef ref, CorrectionMode currentMode, AppStrings s) {
    final isJapanese = ref.read(localeProvider) == AppLocale.japanese;
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(s.selectCorrectionMode),
        children: CorrectionMode.values.map((mode) {
          return RadioListTile<CorrectionMode>(
            title: Text(mode.getDisplayName(isJapanese)),
            value: mode,
            groupValue: currentMode,
            onChanged: (value) {
              ref.read(correctionModeProvider.notifier).setCorrectionMode(value!);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _editDisplayName(String currentName, AppStrings s) async {
    final controller = TextEditingController(text: currentName);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.editDisplayName),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: s.displayName,
            hintText: s.enterDisplayName,
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(s.save),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newName == null || newName.isEmpty || newName == currentName) return;

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.updateUserProfile(displayName: newName);
      
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.displayNameUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.updateFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount(AppStrings s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteAccountTitle),
        content: Text(s.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.deleteAccount();

      if (mounted) {
        await ref.read(authProvider.notifier).signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.accountDeleted),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.deleteFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanUsageAsync = ref.watch(scanUsageProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final s = ref.watch(stringsProvider);
    final locale = ref.watch(localeProvider);
    final isJapanese = locale == AppLocale.japanese;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.settings),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userProfileProvider);
              ref.invalidate(scanUsageProvider);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // User Info Section
          _buildSection(
            context,
            title: s.account,
            children: [
              userProfileAsync.when(
                loading: () => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(s.loading),
                  subtitle: Text(s.freePlan),
                ),
                error: (_, __) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(s.loadingError),
                  subtitle: Text(s.tapToRetry),
                ),
                data: (profile) {
                  final displayName = profile['displayName'] as String? ?? 'User';
                  final email = profile['email'] as String? ?? '';
                  final plan = profile['plan'] as String? ?? 'free';
                  
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(child: Text(displayName)),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _editDisplayName(displayName, s),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: s.editDisplayName,
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(email),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: plan == 'premium' ? Colors.amber : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            plan.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: plan == 'premium' ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: plan != 'premium'
                        ? TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(s.comingSoon)),
                              );
                            },
                            child: Text(s.upgrade),
                          )
                        : null,
                  );
                },
              ),
            ],
          ),

          const Divider(),

          // Correction Settings
          _buildSection(
            context,
            title: s.correctionSettings,
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final correctionMode = ref.watch(correctionModeProvider);
                  return ListTile(
                    leading: const Icon(Icons.auto_fix_high),
                    title: Text(s.defaultCorrectionMode),
                    subtitle: Text(correctionMode.getDisplayName(isJapanese)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showCorrectionModeDialog(context, ref, correctionMode, s),
                  );
                },
              ),
            ],
          ),

          const Divider(),

          // Usage Section
          _buildSection(
            context,
            title: s.todaysUsage,
            children: [
              scanUsageAsync.when(
                loading: () => ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text(s.scansUsed),
                  trailing: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (error, __) => ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text(s.scansUsed),
                  subtitle: Text('${s.loadingError}: $error'),
                  trailing: const Text('-- / --'),
                ),
                data: (usage) {
                  final count = usage['count'] ?? 0;
                  final limit = usage['limit'] ?? 1;
                  final isPremium = limit >= 999;
                  
                  final usageText = isPremium 
                      ? s.noLimit
                      : '$count / $limit';
                  
                  return ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: Text(s.scansUsed),
                    subtitle: Text('${s.plan}: ${isPremium ? "PREMIUM" : "FREE"}'),
                    trailing: Text(
                      usageText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPremium ? Colors.amber[700] : null,
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  s.freePlanInfo,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ),

          const Divider(),

          // App Settings
          _buildSection(
            context,
            title: s.app,
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final themeMode = ref.watch(themeModeProvider);
                  return ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: Text(s.darkMode),
                    subtitle: Text(_getThemeModeText(themeMode, s)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemeModeDialog(context, ref, themeMode, s),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, _) {
                  final currentLocale = ref.watch(localeProvider);
                  return ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(s.language),
                    subtitle: Text(currentLocale.displayName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageDialog(context, ref, currentLocale, s),
                  );
                },
              ),
            ],
          ),

          const Divider(),

          // About Section
          _buildSection(
            context,
            title: s.about,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(s.version),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(s.termsOfService),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsOfServiceScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(s.privacyPolicy),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const Divider(),

          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(s.logOut),
                    content: Text(s.logOutConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(s.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(authProvider.notifier).signOut();
                        },
                        child: Text(s.logOut),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout),
              label: Text(s.logOut),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),

          // Delete Account
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton.icon(
              onPressed: _isDeleting ? null : () => _deleteAccount(s),
              icon: _isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                    )
                  : const Icon(Icons.delete_forever),
              label: Text(_isDeleting ? s.deleting : s.deleteAccount),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}
