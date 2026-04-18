import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/providers/locale_provider.dart';
import 'diary_detail_screen.dart';
import 'diary_list_screen.dart';

class DiaryEditScreen extends ConsumerStatefulWidget {
  final String diaryId;
  final Map<String, dynamic>? diary;

  const DiaryEditScreen({
    super.key,
    required this.diaryId,
    this.diary,
  });

  @override
  ConsumerState<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends ConsumerState<DiaryEditScreen> {
  late TextEditingController _textController;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final originalText = widget.diary?['originalText'] as String? ?? '';
    _textController = TextEditingController(text: originalText);
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final original = widget.diary?['originalText'] as String? ?? '';
    setState(() {
      _hasChanges = _textController.text.trim() != original.trim();
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _textController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.updateDiary(
        diaryId: widget.diaryId,
        originalText: _textController.text.trim(),
      );

      // Refresh providers
      ref.invalidate(diaryDetailProvider(widget.diaryId));
      ref.invalidate(diaryListProvider);

      if (mounted) {
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.diaryUpdatedCorrectionCleared),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/diaries/${widget.diaryId}');
      }
    } catch (e) {
      if (mounted) {
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.failedToUpdate('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final s = ref.read(stringsProvider);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.discardChangesTitle),
        content: Text(s.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.discard),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.go('/diaries/${widget.diaryId}');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (_hasChanges) {
                final shouldPop = await _onWillPop();
                if (shouldPop && context.mounted) {
                  context.go('/diaries/${widget.diaryId}');
                }
              } else {
                context.go('/diaries/${widget.diaryId}');
              }
            },
          ),
          title: Text(s.editDiary),
          actions: [
            TextButton.icon(
              onPressed: _hasChanges && !_isSaving ? _saveChanges : null,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? s.saving : s.save),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.editDiary,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                s.editingNoteWarning,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: s.writeEnglishDiaryHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
