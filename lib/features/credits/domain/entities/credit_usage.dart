class CreditUsage {
  const CreditUsage({
    required this.balance,
    required this.totalPurchased,
    required this.totalConsumed,
  });

  final int balance;
  final int totalPurchased;
  final int totalConsumed;

  static const empty = CreditUsage(
    balance: 0,
    totalPurchased: 0,
    totalConsumed: 0,
  );
}
