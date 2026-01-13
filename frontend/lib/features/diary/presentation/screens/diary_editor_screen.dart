import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import 'diary_list_screen.dart';

class DiaryEditorScreen extends ConsumerStatefulWidget {
  final String? initialText;
  final String? inputType; // 'manual' or 'scan'
  
  const DiaryEditorScreen({
    super.key, 
    this.initialText,
    this.inputType,
  });

  @override
  ConsumerState<DiaryEditorScreen> createState() => _DiaryEditorScreenState();
}

class _DiaryEditorScreenState extends ConsumerState<DiaryEditorScreen> {
  final _textController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveDiary() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.createDiary(
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        originalText: _textController.text,
        inputType: widget.inputType ?? 'manual',
      );

      if (mounted) {
        // Invalidate the diary list to refresh
        ref.invalidate(diaryListProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diary saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to the new diary's detail page
        final diaryId = response['diaryId'] as String?;
        if (diaryId != null) {
          context.go('/diaries/$diaryId');
        } else {
          context.go('/diaries');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isScanned = widget.inputType == 'scan' || widget.initialText != null;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/diaries'),
        ),
        title: Text(isScanned ? 'Scanned Diary' : 'New Diary'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveDiary,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector
          InkWell(
            onTap: _selectDate,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          
          // Scanned indicator
          if (isScanned)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.camera_alt, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Scanned from handwriting - Please review and edit if needed',
                    style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
          
          // Text input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Write about your day in English...',
                  border: InputBorder.none,
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          
          // Word count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, child) {
                    final wordCount = value.text.trim().isEmpty
                        ? 0
                        : value.text.trim().split(RegExp(r'\s+')).length;
                    return Text(
                      '$wordCount words',
                      style: TextStyle(color: Colors.grey[500]),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
