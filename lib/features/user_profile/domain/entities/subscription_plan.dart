class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.benefits,
    required this.fee,
    required this.credits,
  });

  final String id;
  final String name;
  final String description;
  final List<String> benefits;
  final double fee;
  final int credits;
}
