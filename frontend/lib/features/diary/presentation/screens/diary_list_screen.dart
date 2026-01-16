import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/ad_service.dart';

/// Provider for diary list
final diaryListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getDiaries();
});

class DiaryListScreen extends ConsumerStatefulWidget {
  const DiaryListScreen({super.key});

  @override
  ConsumerState<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends ConsumerState<DiaryListScreen> {
  @override
  void initState() {
    super.initState();
    // Preload rewarded ad for scan bonus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adServiceProvider).loadRewardedAd();
    });
  }

  Future<void> _onScanButtonPressed(BuildContext context) async {
    try {
      // Check scan usage first
      final apiService = ref.read(apiServiceProvider);
      final usage = await apiService.getScanUsage();
      
      final count = usage['count'] as int? ?? 0;
      final baseLimit = usage['limit'] as int? ?? 1;
      final bonusCount = usage['bonusCount'] as int? ?? 0;
      final maxBonus = usage['maxBonus'] as int? ?? 2;
      final totalLimit = baseLimit + bonusCount;
      
      // Check if user has scans remaining
      if (count < totalLimit) {
        // Has scans remaining, go to camera
        if (mounted) context.go('/diaries/camera');
        return;
      }
      
      // No scans remaining, check if can watch ad for bonus
      if (bonusCount < maxBonus) {
        // Can watch ad for bonus scan
        final watchAd = await _showWatchAdDialog(maxBonus - bonusCount);
        if (watchAd == true && mounted) {
          await _watchAdAndScan();
        }
      } else {
        // Max bonus reached
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Daily Scan Limit Reached'),
              content: const Text(
                'You\'ve used all your scans for today, including bonus scans.\n\n'
                'Come back tomorrow for more free scans, or upgrade to Premium for unlimited scanning!',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking scan usage: $e');
      // If error checking, still allow to go to camera (backend will check again)
      if (mounted) context.go('/diaries/camera');
    }
  }

  Future<bool?> _showWatchAdDialog(int remainingBonus) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Scan Limit Reached'),
        content: Text(
          'You\'ve used your free scan for today.\n\n'
          'Watch a short ad to get 1 bonus scan!\n'
          '($remainingBonus bonus scans remaining today)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Watch Ad'),
          ),
        ],
      ),
    );
  }

  Future<void> _watchAdAndScan() async {
    final adService = ref.read(adServiceProvider);
    
    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading ad...'), duration: Duration(seconds: 5)),
      );
    }

    // Wait for ad to load if not ready
    if (!adService.isRewardedAdReady) {
      adService.loadRewardedAd();
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (adService.isRewardedAdReady) break;
      }
    }

    if (!adService.isRewardedAdReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad not available. Please try again in a moment.')),
        );
      }
      adService.loadRewardedAd();
      return;
    }

    // Show rewarded ad
    final rewardEarned = await adService.showRewardedAd();

    if (rewardEarned && mounted) {
      try {
        // Grant bonus scan
        final apiService = ref.read(apiServiceProvider);
        await apiService.grantBonusScan();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bonus scan granted!'),
            backgroundColor: Colors.green,
          ),
        );

        // Now go to camera
        if (mounted) context.go('/diaries/camera');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to grant bonus: $e')),
          );
        }
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please watch the complete ad to earn the bonus scan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diariesAsync = ref.watch(diaryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Diaries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _showCalendar(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(diaryListProvider),
          ),
        ],
      ),
      body: diariesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Failed to load diaries',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(diaryListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (diaries) {
          if (diaries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No diaries yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start writing your first diary entry!',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(diaryListProvider);
              await ref.read(diaryListProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: diaries.length,
              itemBuilder: (context, index) {
                final diary = diaries[index];
                return _DiaryCard(diary: diary);
              },
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scan button
          FloatingActionButton.small(
            heroTag: 'scan',
            onPressed: () => _onScanButtonPressed(context),
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 8),
          // Manual entry button
          FloatingActionButton.extended(
            heroTag: 'manual',
            onPressed: () => context.go('/diaries/new'),
            icon: const Icon(Icons.edit),
            label: const Text('Write'),
          ),
        ],
      ),
    );
  }

  void _showCalendar(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Select a date to view diaries',
    );

    if (picked != null && mounted) {
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      // Fetch diaries for that specific date
      try {
        final apiService = ref.read(apiServiceProvider);
        final diaries = await apiService.getDiaries(
          startDate: dateStr,
          endDate: dateStr,
        );
        
        if (mounted) {
          if (diaries.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No diary entry for ${DateFormat('MMMM d, yyyy').format(picked)}')),
            );
          } else {
            // Navigate to the first diary of that date
            context.go('/diaries/${diaries.first['diaryId']}');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

class _DiaryCard extends StatelessWidget {
  final Map<String, dynamic> diary;

  const _DiaryCard({required this.diary});

  @override
  Widget build(BuildContext context) {
    final date = diary['date'] as String? ?? '';
    final originalText = diary['originalText'] as String? ?? '';
    final hasCorrection = diary['correctedText'] != null;
    final inputType = diary['inputType'] as String? ?? 'manual';

    // Parse date
    DateTime? dateTime;
    try {
      dateTime = DateFormat('yyyy-MM-dd').parse(date);
    } catch (_) {}

    // Get preview text (first 100 chars)
    final preview = originalText.length > 100 
        ? '${originalText.substring(0, 100)}...' 
        : originalText;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/diaries/${diary['diaryId']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Date
                  Text(
                    dateTime != null 
                        ? DateFormat('MMMM d, yyyy').format(dateTime)
                        : date,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Input type indicator
                  if (inputType == 'scan')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            '手書き',
                            style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                          ),
                        ],
                      ),
                    ),
                  // Correction status
                  if (hasCorrection) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            '添削済み',
                            style: TextStyle(fontSize: 12, color: Colors.green[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Preview text
              Text(
                preview,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
