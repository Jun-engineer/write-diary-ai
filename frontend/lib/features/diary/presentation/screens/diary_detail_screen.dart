import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/correction_mode_provider.dart';
import 'diary_list_screen.dart';

/// Provider for a single diary - using StateProvider to allow manual updates
final diaryDetailProvider = StateNotifierProvider.autoDispose
    .family<DiaryDetailNotifier, AsyncValue<Map<String, dynamic>>, String>(
  (ref, diaryId) => DiaryDetailNotifier(ref, diaryId),
);

class DiaryDetailNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final Ref _ref;
  final String _diaryId;

  DiaryDetailNotifier(this._ref, this._diaryId) : super(const AsyncValue.loading()) {
    _loadDiary();
  }

  Future<void> _loadDiary() async {
    try {
      state = const AsyncValue.loading();
      final apiService = _ref.read(apiServiceProvider);
      final diary = await apiService.getDiary(_diaryId);
      state = AsyncValue.data(diary);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _loadDiary();
  }

  void updateDiary(Map<String, dynamic> diary) {
    state = AsyncValue.data(diary);
  }
}

class DiaryDetailScreen extends ConsumerStatefulWidget {
  final String diaryId;

  const DiaryDetailScreen({super.key, required this.diaryId});

  @override
  ConsumerState<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends ConsumerState<DiaryDetailScreen> {
  String _selectedMode = 'intermediate'; // Will be updated from provider
  bool _isCorrecting = false;
  bool _isCreatingCards = false;
  bool _isDeleting = false;
  Set<int> _selectedCorrections = {};
  bool _isSelectMode = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize with the default correction mode from settings (only once)
    if (!_initialized) {
      _selectedMode = ref.read(correctionModeProvider).code;
      _initialized = true;
    }
  }

  Future<void> _runCorrection() async {
    setState(() => _isCorrecting = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.correctDiary(
        diaryId: widget.diaryId,
        mode: _selectedMode,
      );

      debugPrint('Correction result: $result');
      debugPrint('correctedText: ${result['correctedText']}');
      debugPrint('corrections: ${result['corrections']}');

      // Update the local state immediately with the correction result
      final notifier = ref.read(diaryDetailProvider(widget.diaryId).notifier);
      final currentState = ref.read(diaryDetailProvider(widget.diaryId));
      
      if (currentState.hasValue) {
        final updatedDiary = Map<String, dynamic>.from(currentState.value!);
        updatedDiary['correctedText'] = result['correctedText'];
        updatedDiary['corrections'] = result['corrections'];
        debugPrint('Updated diary: $updatedDiary');
        notifier.updateDiary(updatedDiary);
      } else {
        debugPrint('No current state value, refreshing from server');
        await notifier.refresh();
      }

      // Also refresh the list
      ref.invalidate(diaryListProvider);

      if (mounted) {
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.correctionComplete),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.correctionFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCorrecting = false);
      }
    }
  }

  Future<void> _createSelectedReviewCards() async {
    final s = ref.read(stringsProvider);
    if (_selectedCorrections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.noSelectionsError),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCreatingCards = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.createReviewCardsFromSelection(
        diaryId: widget.diaryId,
        selectedIndices: _selectedCorrections.toList(),
      );

      if (mounted) {
        final cardCount = result['created'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.cardsCreated(cardCount)),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedCorrections.clear();
          _isSelectMode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.cardCreationFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingCards = false);
      }
    }
  }

  Future<void> _deleteDiary() async {
    final s = ref.read(stringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteDiaryTitle),
        content: Text(s.deleteDiaryConfirm),
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
      await apiService.deleteDiary(widget.diaryId);

      ref.invalidate(diaryListProvider);

      if (mounted) {
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.diaryDeleted),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/diaries');
      }
    } catch (e) {
      if (mounted) {
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.deleteFailed2}: $e'),
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

  void _editDiary(Map<String, dynamic> diary) {
    context.push('/diaries/${widget.diaryId}/edit', extra: diary);
  }

  @override
  Widget build(BuildContext context) {
    final diaryAsync = ref.watch(diaryDetailProvider(widget.diaryId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/diaries'),
        ),
        title: const Text('Diary'),
        actions: [
          if (diaryAsync.hasValue) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editDiary(diaryAsync.value!),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete),
              onPressed: _isDeleting ? null : _deleteDiary,
              tooltip: 'Delete',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(diaryDetailProvider(widget.diaryId).notifier).refresh(),
          ),
        ],
      ),
      body: diaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Failed to load diary', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(error.toString(), style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(diaryDetailProvider(widget.diaryId).notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (diary) => _buildContent(context, diary),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> diary) {
    final s = ref.watch(stringsProvider);
    
    final date = diary['date'] as String? ?? '';
    final originalText = diary['originalText'] as String? ?? '';
    final correctedText = diary['correctedText'] as String?;
    final corrections = diary['corrections'] as List<dynamic>?;
    final hasCorrections = corrections != null && corrections.isNotEmpty;

    DateTime? dateTime;
    try {
      dateTime = DateFormat('yyyy-MM-dd').parse(date);
    } catch (_) {}

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          if (dateTime != null)
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(dateTime),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          const SizedBox(height: 16),

          // Original Text Section
          Text(
            s.originalDiary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              originalText,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),

          const SizedBox(height: 24),

          // Correction Mode Selector (always show to allow re-correction)
          Text(
            s.aiCorrection,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'beginner', label: Text(s.beginner)),
              ButtonSegment(value: 'intermediate', label: Text(s.intermediate)),
              ButtonSegment(value: 'advanced', label: Text(s.advanced)),
            ],
            selected: {_selectedMode},
            onSelectionChanged: (Set<String> selection) {
              setState(() => _selectedMode = selection.first);
            },
          ),
          const SizedBox(height: 8),
          _buildModeDescription(s),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isCorrecting ? null : _runCorrection,
              icon: _isCorrecting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_fix_high),
              label: Text(_isCorrecting
                  ? s.correcting
                  : hasCorrections
                      ? s.reCorrect
                      : s.runAiCorrection),
            ),
          ),

          // Corrected Text Section
          if (hasCorrections) ...[
            const SizedBox(height: 24),
            Text(
              s.corrected,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                correctedText ?? originalText,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),

            const SizedBox(height: 24),

            // Corrections List with selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.corrections(corrections.length),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    if (_isSelectMode) ...[
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCorrections.clear();
                            _isSelectMode = false;
                          });
                        },
                        child: Text(s.cancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _isCreatingCards ? null : _createSelectedReviewCards,
                        icon: _isCreatingCards
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.add_card, size: 18),
                        label: Text(_isCreatingCards
                            ? s.creating
                            : s.addToCards(_selectedCorrections.length)),
                      ),
                    ] else
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _isSelectMode = true);
                        },
                        icon: const Icon(Icons.add_card, size: 18),
                        label: Text(s.addToReviewCards),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isSelectMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  s.selectCorrectionsHint,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            ...corrections.asMap().entries.map((entry) {
              final index = entry.key;
              final correction = entry.value;
              return _buildCorrectionCard(correction, index);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildModeDescription(AppStrings s) {
    String description;
    switch (_selectedMode) {
      case 'beginner':
        description = s.beginnerDesc;
        break;
      case 'intermediate':
        description = s.intermediateDesc;
        break;
      case 'advanced':
        description = s.advancedDesc;
        break;
      default:
        description = '';
    }
    return Text(
      description,
      style: TextStyle(color: Colors.grey[600], fontSize: 13),
    );
  }

  Widget _buildCorrectionCard(dynamic correction, int index) {
    final type = correction['type'] as String? ?? 'grammar';
    final before = correction['before'] as String? ?? '';
    final after = correction['after'] as String? ?? '';
    final explanation = correction['explanation'] as String? ?? '';
    final isSelected = _selectedCorrections.contains(index);

    Color typeColor;
    switch (type.toLowerCase()) {
      case 'grammar':
        typeColor = Colors.orange;
        break;
      case 'spelling':
        typeColor = Colors.red;
        break;
      case 'style':
        typeColor = Colors.purple;
        break;
      case 'vocabulary':
        typeColor = Colors.blue;
        break;
      default:
        typeColor = Colors.grey;
    }

    return GestureDetector(
      onTap: _isSelectMode
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedCorrections.remove(index);
                } else {
                  _selectedCorrections.add(index);
                }
              });
            }
          : null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_isSelectMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedCorrections.add(index);
                          } else {
                            _selectedCorrections.remove(index);
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: typeColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: before,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.red,
                      ),
                    ),
                    const TextSpan(text: ' → '),
                    TextSpan(
                      text: after,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              if (explanation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  explanation,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
