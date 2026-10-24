import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

const _planOrder = ['free', 'pro', 'pro plus', 'business', 'enterprise'];

String _normalizePlanName(String name) {
  final lower = name.trim().toLowerCase();
  return lower.startsWith('zedu ') ? lower.substring(5) : lower;
}

int _planTier(SubscriptionPlan plan) {
  final index = _planOrder.indexOf(_normalizePlanName(plan.name));
  return index == -1 ? _planOrder.length : index;
}

List<SubscriptionPlan> _sortedPlans(List<SubscriptionPlan> plans) {
  final sorted = [...plans];
  sorted.sort((a, b) {
    final byTier = _planTier(a).compareTo(_planTier(b));
    return byTier != 0 ? byTier : a.fee.compareTo(b.fee);
  });
  return sorted;
}

Future<void> showComparePlansDialog(
  BuildContext context, {
  required String currentPlan,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ComparePlansDialog(currentPlan: currentPlan),
  );
}

class ComparePlansDialog extends ConsumerStatefulWidget {
  const ComparePlansDialog({super.key, required this.currentPlan});

  final String currentPlan;

  @override
  ConsumerState<ComparePlansDialog> createState() => _ComparePlansDialogState();
}

class _ComparePlansDialogState extends ConsumerState<ComparePlansDialog> {
  String? _loadingPlanId;

  bool _isCurrent(SubscriptionPlan plan) =>
      _normalizePlanName(plan.name) == _normalizePlanName(widget.currentPlan);

  void _showError(String message) {
    if (!mounted) return;
    AppToastService.show(context, type: AppToastType.error, message: message);
  }

  Future<void> _upgrade(SubscriptionPlan plan) async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    setState(() => _loadingPlanId = plan.id);
    final result = await ref
        .read(userProfileRepositoryProvider)
        .startPlanCheckout(
          planName: plan.name,
          orgId: user.currentOrg,
          email: user.email,
          isNewSubscription: _normalizePlanName(widget.currentPlan) == 'free',
        );
    if (!mounted) return;
    setState(() => _loadingPlanId = null);

    switch (result) {
      case Success<String>(:final value):
        final uri = value.isEmpty ? null : Uri.tryParse(value);
        if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
          _showError('Could not get a checkout link. Please try again.');
          return;
        }
        try {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
          if (!launched) {
            _showError('Could not open the payment page automatically.');
          }
        } catch (_) {
          _showError('Could not open the payment page automatically.');
        }
      case Failure<String>(:final error):
        _showError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final plans = ref.watch(subscriptionPlansProvider);

    return AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Compare plans',
        style: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 960,
        child: plans.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Could not load plans. Please try again.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
          data: (items) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final plan in _sortedPlans(items)) ...[
                  _PlanColumn(
                    plan: plan,
                    isCurrent: _isCurrent(plan),
                    isLoading: _loadingPlanId == plan.id,
                    onUpgrade: _loadingPlanId == null
                        ? () => _upgrade(plan)
                        : null,
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _PlanColumn extends StatelessWidget {
  const _PlanColumn({
    required this.plan,
    required this.isCurrent,
    required this.isLoading,
    required this.onUpgrade,
  });

  final SubscriptionPlan plan;
  final bool isCurrent;
  final bool isLoading;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final price = plan.fee == 0
        ? 'Free'
        : '\$${plan.fee.toStringAsFixed(plan.fee % 1 == 0 ? 0 : 2)}/month';

    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? colors.primaryBg : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? colors.primary : colors.borderOutline,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (isCurrent)
                Text(
                  'Current plan',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              plan.description,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (plan.credits > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${plan.credits} credits',
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (final benefit in plan.benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check, size: 16, color: colors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      benefit,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (!isCurrent)
            AppButton(
              label: 'Upgrade',
              height: 40,
              loading: isLoading,
              onPressed: onUpgrade,
            ),
        ],
      ),
    );
  }
}
