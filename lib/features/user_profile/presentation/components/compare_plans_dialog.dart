import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

const _planOrder = ['free', 'pro', 'pro plus', 'business', 'enterprise'];

String _normalizePlanName(String name) {
  final lower = name.trim().toLowerCase();
  return lower.startsWith('zedu ') ? lower.substring(5) : lower;
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.benefits,
    required this.fee,
    required this.credits,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: (json['description'] as String? ?? '').trim(),
      benefits:
          (json['benefits'] as List<dynamic>?)
              ?.whereType<String>()
              .where((b) => b.trim().isNotEmpty)
              .toList() ??
          const [],
      fee: (json['fee'] as num?)?.toDouble() ?? 0,
      credits: (json['credits'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String name;
  final String description;
  final List<String> benefits;
  final double fee;
  final int credits;
}

/// Same plan list the web app shows: GET /subscriptions/plans.
final subscriptionPlansProvider =
    FutureProvider.autoDispose<List<SubscriptionPlan>>((ref) async {
      final response = await locator<ApiBaseService>()
          .get<Map<String, dynamic>>(path: '/subscriptions/plans');
      final data = response.data['data'];
      if (data is! List) return [];
      final plans = data
          .cast<Map<String, dynamic>>()
          .map(SubscriptionPlan.fromJson)
          .toList();
      int tier(SubscriptionPlan p) {
        final index = _planOrder.indexOf(_normalizePlanName(p.name));
        return index == -1 ? _planOrder.length : index;
      }

      plans.sort((a, b) {
        final byTier = tier(a).compareTo(tier(b));
        return byTier != 0 ? byTier : a.fee.compareTo(b.fee);
      });
      return plans;
    });

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

  Future<void> _upgrade(SubscriptionPlan plan) async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    setState(() => _loadingPlanId = plan.id);
    try {
      final payload = {
        'plan_name': plan.name,
        'org_id': user.currentOrg,
        'email': user.email,
      };
      final api = locator<ApiBaseService>();
      final response = _normalizePlanName(widget.currentPlan) == 'free'
          ? await api.post<Map<String, dynamic>>(
              path: '/subscriptions/create',
              data: payload,
            )
          : await api.put<Map<String, dynamic>>(
              path: '/subscriptions/modify',
              data: payload,
            );
      final data = response.data['data'];
      final url = data is Map ? data['checkout_session_url'] as String? : null;
      final uri = url == null ? null : Uri.tryParse(url);
      if (!mounted) return;
      if (uri == null) {
        AppToastService.show(
          context,
          type: AppToastType.error,
          message: 'Could not get a checkout link. Please try again.',
        );
        return;
      }
      final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!launched && mounted) {
        AppToastService.show(
          context,
          type: AppToastType.error,
          message: 'Could not open the payment page automatically.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppToastService.show(
          context,
          type: AppToastType.error,
          message: 'An error occurred during upgrade. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingPlanId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final plans = ref.watch(subscriptionPlansProvider);

    return AlertDialog(
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
                for (final plan in items) ...[
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
