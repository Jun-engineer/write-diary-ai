import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/providers/locale_provider.dart';

/// Toggle for due-only filter (default: show only due cards)
final _dueOnlyProvider = StateProvider.autoDispose<bool>((ref) => true);

/// Provider for review cards list (respects due-only filter)
final reviewCardsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final dueOnly = ref.watch(_dueOnlyProvider);
  return apiService.getReviewCards(dueOnly: dueOnly);
});

class ReviewListScreen extends ConsumerStatefulWidget {
  const ReviewListScreen({super.key});

  @override
  ConsumerState<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends ConsumerState<ReviewListScreen> {
  Future<void> _deleteCard(String cardId) async {
    final s = ref.read(stringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteCard),
        content: Text(s.deleteCardConfirm),
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

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.deleteReviewCard(cardId);
      ref.invalidate(reviewCardsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.cardDeleted), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.failedToDelete('$e')), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(reviewCardsProvider);
    final dueOnly = ref.watch(_dueOnlyProvider);
    final s = ref.watch(stringsProvider);

    // Count due cards for badge
    final dueCount = cardsAsync.valueOrNull
            ?.where((c) {
              final dueAt = c['dueAt'] as int?;
              return dueAt != null && dueAt <= DateTime.now().millisecondsSinceEpoch;
            })
            .length ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.reviewCards),
        actions: [
          if (!dueOnly && dueCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Badge(
                label: Text('$dueCount'),
                child: const SizedBox(width: 24),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(reviewCardsProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(s.dueCards),
                  selected: dueOnly,
                  onSelected: (_) => ref.read(_dueOnlyProvider.notifier).state = true,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(s.showAllCards),
                  selected: !dueOnly,
                  onSelected: (_) => ref.read(_dueOnlyProvider.notifier).state = false,
                ),
              ],
            ),
          ),
        ),
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(s.failedToLoadCards, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(error.toString(), style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(reviewCardsProvider),
                child: Text(s.retry),
              ),
            ],
          ),
        ),
        data: (cards) {
          if (cards.isEmpty && dueOnly) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.celebration_outlined, size: 80, color: Colors.amber),
                  const SizedBox(height: 16),
                  Text(
                    s.allCaughtUp,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      s.allCaughtUpDesc,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(_dueOnlyProvider.notifier).state = false,
                    icon: const Icon(Icons.style_outlined),
                    label: Text(s.showAllCards),
                  ),
                ],
              ),
            );
          }

          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    s.noReviewCardsYet,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(s.createCardsFromCorrections, style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(reviewCardsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return _ReviewCardItem(
                  card: card,
                  onDelete: () => _deleteCard(card['cardId'] as String),
                  onRated: () => ref.invalidate(reviewCardsProvider),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReviewCardItem extends ConsumerStatefulWidget {
  final Map<String, dynamic> card;
  final VoidCallback onDelete;
  final VoidCallback onRated;

  const _ReviewCardItem({
    required this.card,
    required this.onDelete,
    required this.onRated,
  });

  @override
  ConsumerState<_ReviewCardItem> createState() => _ReviewCardItemState();
}

class _ReviewCardItemState extends ConsumerState<_ReviewCardItem> {
  bool _isFlipped = false;
  bool _isRating = false;

  bool get _isDue {
    final dueAt = widget.card['dueAt'] as int?;
    if (dueAt == null) return true; // legacy cards with no dueAt are due
    return dueAt <= DateTime.now().millisecondsSinceEpoch;
  }

  int get _daysUntilDue {
    final dueAt = widget.card['dueAt'] as int?;
    if (dueAt == null) return 0;
    final diff = dueAt - DateTime.now().millisecondsSinceEpoch;
    return (diff / (1000 * 60 * 60 * 24)).ceil();
  }

  Future<void> _rate(String rating) async {
    if (_isRating) return;
    setState(() => _isRating = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.reviewCard(cardId: widget.card['cardId'] as String, rating: rating);
      widget.onRated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
        setState(() => _isRating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final before = widget.card['before'] as String? ?? '';
    final after = widget.card['after'] as String? ?? '';
    final context_ = widget.card['context'] as String? ?? '';
    final tags = (widget.card['tags'] as List<dynamic>?)?.cast<String>() ?? [];

    return GestureDetector(
      onTap: () {
        if (!_isFlipped) setState(() => _isFlipped = true);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _isFlipped
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: tags + due badge + delete
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Due badge
                        if (_isDue)
                          Chip(
                            avatar: const Icon(Icons.notifications_active, size: 14, color: Colors.white),
                            label: const Text('Due', style: TextStyle(fontSize: 11, color: Colors.white)),
                            backgroundColor: Colors.red[400],
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          )
                        else
                          Chip(
                            avatar: Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                            label: Text(
                              s.nextReviewIn(_daysUntilDue),
                              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                            ),
                            backgroundColor: Colors.grey[200],
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ...tags.map((tag) {
                          String localizedTag = tag;
                          if (tag == 'grammar') {
                            localizedTag = s.grammar;
                          } else if (tag == 'style') {
                            localizedTag = s.style;
                          } else if (tag == 'vocabulary') {
                            localizedTag = s.vocabulary;
                          } else if (tag == 'spelling') {
                            localizedTag = s.spelling;
                          }
                          return Chip(
                            label: Text(localizedTag, style: const TextStyle(fontSize: 11)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: widget.onDelete,
                    color: Colors.grey[600],
                    tooltip: s.deleteCard,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Card content (flip animation)
              AnimatedCrossFade(
                firstChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.whatsWrongWithThis,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      before,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.tapToSeeAnswer,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600], size: 18),
                        const SizedBox(width: 4),
                        Text(s.correctExpression, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      after,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (context_.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s.contextLabel(context_),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // SRS rating buttons
                    Text(
                      s.howWasIt,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    _isRating
                        ? const Center(child: SizedBox(height: 36, width: 36, child: CircularProgressIndicator(strokeWidth: 2)))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _RatingButton(
                                label: s.srAgain,
                                color: Colors.red,
                                onTap: () => _rate('again'),
                              ),
                              _RatingButton(
                                label: s.srHard,
                                color: Colors.orange,
                                onTap: () => _rate('hard'),
                              ),
                              _RatingButton(
                                label: s.srGood,
                                color: Colors.blue,
                                onTap: () => _rate('good'),
                              ),
                              _RatingButton(
                                label: s.srEasy,
                                color: Colors.green,
                                onTap: () => _rate('easy'),
                              ),
                            ],
                          ),
                  ],
                ),
                crossFadeState: _isFlipped ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}
