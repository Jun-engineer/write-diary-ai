import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../core/providers/locale_provider.dart';

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
    final s = ref.read(stringsProvider);
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
              title: Text(s.dailyScanLimitReached),
              content: Text(s.usedAllScansToday),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(s.ok),
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
    final s = ref.read(stringsProvider);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.dailyScanLimitReached),
        content: Text(s.usedFreeScanWatchAd(remainingBonus)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.watchAd),
          ),
        ],
      ),
    );
  }

  Future<void> _watchAdAndScan() async {
    final adService = ref.read(adServiceProvider);
    final s = ref.read(stringsProvider);
    
    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.loadingAd), duration: const Duration(seconds: 5)),
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
          SnackBar(content: Text(s.adNotAvailable)),
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
          SnackBar(
            content: Text(s.bonusScanGranted),
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
      final s = ref.read(stringsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.pleaseWatchCompleteAd)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diariesAsync = ref.watch(diaryListProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myDiaries),
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
                s.failedToLoadDiaries,
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
                child: Text(s.retry),
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
                    s.noDiariesYet,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.startWritingFirst,
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
            label: Text(s.write),
          ),
        ],
      ),
    );
  }

  void _showCalendar(BuildContext context) async {
    final s = ref.read(stringsProvider);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: s.selectDateToView,
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
              SnackBar(content: Text(s.noDiaryForDate(DateFormat('MMMM d, yyyy').format(picked)))),
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

class _DiaryCard extends ConsumerWidget {
  final Map<String, dynamic> diary;

  const _DiaryCard({required this.diary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
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
                  // Date - make it flexible to allow space for tags
                  Flexible(
                    child: Text(
                      dateTime != null 
                          ? DateFormat('MMMM d, yyyy').format(dateTime)
                          : date,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tags row - wrap in a Row with constrained width
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Input type indicator
                      if (inputType == 'scan')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt, size: 12, color: Colors.blue[700]),
                              const SizedBox(width: 3),
                              Text(
                                s.handwritten,
                                style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                              ),
                            ],
                          ),
                        ),
                      // Correction status
                      if (hasCorrection) ...[
                        if (inputType == 'scan') const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 12, color: Colors.green[700]),
                              const SizedBox(width: 3),
                              Text(
                                s.corrected2,
                                style: TextStyle(fontSize: 10, color: Colors.green[700]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
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
