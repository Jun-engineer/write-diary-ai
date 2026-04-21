import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/user_provider.dart';
import 'package:intl/intl.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isLoading = false;
  bool _isYearlySelected = true; // Default to yearly (best value)

  @override
  void initState() {
    super.initState();
    // Subscription service is initialized globally at app start.
    // Just load offerings if not already loaded.
    Future.microtask(() async {
      final service = ref.read(subscriptionServiceProvider);
      await service.refreshSubscriptionStatus();
      // Paywall analytics: log view event
      debugPrint('[Analytics] paywall_view: ${DateTime.now().toIso8601String()}');
      try {
        await Purchases.setAttributes({
          'last_paywall_view': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    });
  }

  Package? get _monthlyPackage {
    final packages = ref.read(availablePackagesProvider);
    return packages
        .where((p) => p.packageType == PackageType.monthly)
        .firstOrNull;
  }

  Package? get _yearlyPackage {
    final packages = ref.read(availablePackagesProvider);
    return packages
        .where((p) => p.packageType == PackageType.annual)
        .firstOrNull;
  }

  Future<void> _handlePurchase() async {
    final package = _isYearlySelected ? _yearlyPackage : _monthlyPackage;
    if (package == null) return;

    // Paywall analytics: log purchase start
    debugPrint('[Analytics] paywall_purchase_start: ${package.identifier} at ${DateTime.now().toIso8601String()}');
    try {
      await Purchases.setAttributes({
        'last_purchase_attempt': package.identifier,
        'last_purchase_attempt_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    setState(() => _isLoading = true);

    try {
      final service = ref.read(subscriptionServiceProvider);
      final success = await service.purchasePackage(package);
      debugPrint('[Analytics] paywall_purchase_${success ? "success" : "cancelled"}: ${package.identifier}');
    } catch (e) {
      debugPrint('[Analytics] paywall_purchase_error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(subscriptionServiceProvider);
      await service.restorePurchases();

      if (mounted) {
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.restoreCompleted), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final subscriptionDetail = ref.watch(subscriptionDetailProvider);
    final packages = ref.watch(availablePackagesProvider);
    final theme = Theme.of(context);

    // Get prices from RevenueCat packages
    String monthlyPrice = '\$4.99';
    String yearlyPrice = '\$29.99';
    String yearlyMonthlyPrice = '\$2.50';

    for (final pkg in packages) {
      if (pkg.packageType == PackageType.monthly) {
        monthlyPrice = pkg.storeProduct.priceString;
      } else if (pkg.packageType == PackageType.annual) {
        yearlyPrice = pkg.storeProduct.priceString;
        final monthlyEquiv = pkg.storeProduct.price / 12;
        yearlyMonthlyPrice = monthlyEquiv.toStringAsFixed(2);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.premiumPlan),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade600, Colors.orange.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.workspace_premium, size: 64, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      s.premiumPlan,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Benefits
              Text(s.premiumBenefits, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              _buildBenefitTile(Icons.auto_fix_high, s.unlimitedCorrections, s.unlimitedCorrectionsDesc, theme),
              _buildBenefitTile(Icons.camera_alt, s.unlimitedScans, s.unlimitedScansDesc, theme),
              _buildBenefitTile(Icons.block, s.noAds, s.noAdsDesc, theme),

              const SizedBox(height: 32),

              // Plan selection
              if (!isPremium) ...[
                Text(s.choosePlan, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Yearly plan card
                _buildPlanCard(
                  isSelected: _isYearlySelected,
                  title: s.yearlyPlan,
                  price: yearlyPrice,
                  subtitle: '$yearlyMonthlyPrice / ${s.month}',
                  badge: s.save50,
                  onTap: () => setState(() => _isYearlySelected = true),
                  theme: theme,
                ),

                const SizedBox(height: 12),

                // Monthly plan card
                _buildPlanCard(
                  isSelected: !_isYearlySelected,
                  title: s.monthlyPlan,
                  price: '$monthlyPrice / ${s.month}',
                  subtitle: null,
                  badge: null,
                  onTap: () => setState(() => _isYearlySelected = false),
                  theme: theme,
                ),

                const SizedBox(height: 24),

                // Subscribe button
                ElevatedButton(
                  onPressed: _isLoading || subscriptionStatus == SubscriptionStatus.pending
                      ? null
                      : _handlePurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: _isLoading || subscriptionStatus == SubscriptionStatus.pending
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(s.subscribePremium),
                ),

                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading ? null : _handleRestore,
                  child: Text(s.restorePurchases),
                ),
              ] else ...[
                // Already premium — show detailed subscription status
                _buildSubscriptionStatusCard(s, subscriptionDetail, theme),
              ],

              const SizedBox(height: 24),

              // Comparison table
              _buildComparisonCard(s, theme),

              const SizedBox(height: 16),

              // Terms
              Text(
                s.subscriptionTerms,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionStatusCard(AppStrings s, SubscriptionDetail detail, ThemeData theme) {
    // Determine status color + label + icon
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData statusIcon;
    String statusLabel;

    if (detail.hasBillingIssue) {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
      textColor = Colors.red.shade800;
      statusIcon = Icons.credit_card_off;
      statusLabel = s.subscriptionBillingIssue;
    } else if (detail.isCanceled) {
      bgColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade300;
      textColor = Colors.orange.shade800;
      statusIcon = Icons.cancel_outlined;
      statusLabel = s.subscriptionCanceling;
    } else {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade200;
      textColor = Colors.green.shade700;
      statusIcon = Icons.check_circle;
      statusLabel = s.subscriptionActive;
    }

    final expiryString = detail.expiresAt != null
        ? DateFormat.yMMMd().format(detail.expiresAt!)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: textColor),
              const SizedBox(width: 8),
              Text(statusLabel, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          if (expiryString != null) ...[
            const SizedBox(height: 8),
            Text(
              detail.isCanceled || detail.hasBillingIssue
                  ? s.subscriptionAccessUntil(expiryString)
                  : s.subscriptionRenewsOn(expiryString),
              style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 13),
            ),
          ],
          if (detail.hasBillingIssue) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // Open App Store subscription management
                debugPrint('[Analytics] manage_subscription_tapped');
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(s.updatePaymentMethod),
              style: OutlinedButton.styleFrom(foregroundColor: textColor, side: BorderSide(color: borderColor)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required bool isSelected,
    required String title,
    required String price,
    required String? subtitle,
    required String? badge,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.amber.shade700 : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
          color: isSelected ? Colors.amber.shade50 : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.amber.shade700 : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
            Text(
              price,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.amber.shade700 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitTile(IconData icon, String title, String subtitle, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.amber.shade700, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(AppStrings s, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(s.planComparison, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1.5), 2: FlexColumnWidth(1.5)},
              children: [
                TableRow(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                  children: [
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('')),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(s.freePlan, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(s.premiumLabel, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade700), textAlign: TextAlign.center)),
                  ],
                ),
                _buildComparisonRow(s.correctionsLabel, '3/${s.day}', s.noLimit),
                _buildComparisonRow(s.scans, '1/${s.day}', s.noLimit),
                _buildComparisonRow(s.ads, s.yes, s.no),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildComparisonRow(String feature, String free, String premium) {
    return TableRow(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(feature)),
        Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(free, textAlign: TextAlign.center)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(premium, textAlign: TextAlign.center, style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
