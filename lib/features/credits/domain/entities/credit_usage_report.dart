class CreditUsageReport {
  const CreditUsageReport({
    required this.balance,
    required this.purchased,
    required this.consumed,
    required this.periodLabel,
  });

  final int balance;
  final int purchased;
  final int consumed;
  final String periodLabel;

  static const empty = CreditUsageReport(
    balance: 0,
    purchased: 0,
    consumed: 0,
    periodLabel: 'This month',
  );
}
