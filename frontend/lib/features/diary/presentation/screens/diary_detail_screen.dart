import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiaryDetailScreen extends StatefulWidget {
  final String diaryId;
  
  const DiaryDetailScreen({super.key, required this.diaryId});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  String _selectedMode = 'intermediate';
  bool _isLoading = false;
  bool _isCorrecting = false;

  // TODO: Replace with actual diary data from API
  final Map<String, dynamic> _mockDiary = {
    'diaryId': '123',
    'date': '2026-01-11',
    'originalText': 'I went to airport to say goodbye my friend. It was very sad moment.',
    'correctedText': null,
    'corrections': null,
  };

  Future<void> _runCorrection() async {
    setState(() => _isCorrecting = true);

    try {
      // TODO: Call API for correction
      // final response = await apiService.correctDiary(
      //   diaryId: widget.diaryId,
      //   mode: _selectedMode,
      // );

      // Mock response
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _mockDiary['correctedText'] = 'I went to the airport to say goodbye to my friend. It was a very sad moment.';
        _mockDiary['corrections'] = [
          {
            'type': 'grammar',
            'before': 'airport',
            'after': 'the airport',
            'explanation': 'Use definite article "the" when referring to a specific place.',
          },
          {
            'type': 'grammar',
            'before': 'say goodbye my friend',
            'after': 'say goodbye to my friend',
            'explanation': 'The phrase "say goodbye" requires the preposition "to" before the object.',
          },
          {
            'type': 'grammar',
            'before': 'very sad moment',
            'after': 'a very sad moment',
            'explanation': 'Use indefinite article "a" before singular countable nouns.',
          },
        ];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correction complete!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Correction failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCorrecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCorrections = _mockDiary['corrections'] != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/diaries'),
        ),
        title: Text(_mockDiary['date']),
        actions: [
          if (hasCorrections)
            IconButton(
              icon: const Icon(Icons.add_card),
              onPressed: () {
                // TODO: Show dialog to create review cards
              },
              tooltip: 'Create Review Cards',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original Text Section
            Text(
              'Original',
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
                _mockDiary['originalText'],
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Correction Mode Selector
            if (!hasCorrections) ...[
              Text(
                'Correction Mode',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'beginner', label: Text('Beginner')),
                  ButtonSegment(value: 'intermediate', label: Text('Intermediate')),
                  ButtonSegment(value: 'advanced', label: Text('Advanced')),
                ],
                selected: {_selectedMode},
                onSelectionChanged: (Set<String> selection) {
                  setState(() => _selectedMode = selection.first);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCorrecting ? null : _runCorrection,
                  icon: _isCorrecting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: Text(_isCorrecting ? 'Correcting...' : 'Run AI Correction'),
                ),
              ),
            ],
            
            // Corrected Text Section
            if (hasCorrections) ...[
              Text(
                'Corrected',
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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _mockDiary['correctedText'],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Corrections List
              Text(
                'Corrections',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...(_mockDiary['corrections'] as List).map((correction) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                correction['type'].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
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
                                text: correction['before'],
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.red,
                                ),
                              ),
                              const TextSpan(text: ' → '),
                              TextSpan(
                                text: correction['after'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          correction['explanation'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
