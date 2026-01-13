import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported correction modes
enum CorrectionMode {
  beginner('beginner', 'Beginner', '初級'),
  intermediate('intermediate', 'Intermediate', '中級'),
  advanced('advanced', 'Advanced', '上級');

  const CorrectionMode(this.code, this.englishName, this.japaneseName);
  final String code;
  final String englishName;
  final String japaneseName;

  String getDisplayName(bool isJapanese) {
    return isJapanese ? japaneseName : englishName;
  }

  static CorrectionMode fromCode(String code) {
    return CorrectionMode.values.firstWhere(
      (m) => m.code == code,
      orElse: () => CorrectionMode.intermediate, // Default to intermediate
    );
  }
}

/// Correction mode provider
final correctionModeProvider = StateNotifierProvider<CorrectionModeNotifier, CorrectionMode>((ref) {
  return CorrectionModeNotifier();
});

class CorrectionModeNotifier extends StateNotifier<CorrectionMode> {
  CorrectionModeNotifier() : super(CorrectionMode.intermediate) {
    _loadCorrectionMode();
  }

  static const _key = 'correction_mode';

  Future<void> _loadCorrectionMode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      state = CorrectionMode.fromCode(code);
    }
  }

  Future<void> setCorrectionMode(CorrectionMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.code);
  }
}
