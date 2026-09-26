class CreditTransaction {
  const CreditTransaction({
    required this.id,
    required this.amount,
    required this.credits,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final int amount;
  final int credits;
  final String status;
  final DateTime createdAt;
}
