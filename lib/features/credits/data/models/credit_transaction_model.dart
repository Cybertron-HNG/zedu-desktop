import 'package:zedu/features/features.dart';

class CreditTransactionModel extends CreditTransaction {
  const CreditTransactionModel({
    required super.id,
    required super.amount,
    required super.credits,
    required super.status,
    required super.createdAt,
  });

  factory CreditTransactionModel.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['created_at'] as String?;
    return CreditTransactionModel(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'completed',
      createdAt: createdRaw != null
          ? DateTime.tryParse(createdRaw) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
