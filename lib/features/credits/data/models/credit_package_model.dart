import 'package:zedu/features/features.dart';

class CreditPackageModel extends CreditPackage {
  const CreditPackageModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.credits,
    required super.benefits,
    super.planSlug,
  });

  factory CreditPackageModel.fromJson(Map<String, dynamic> json) {
    final benefitsRaw = json['benefits'];
    final benefits = benefitsRaw is List
        ? benefitsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return CreditPackageModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      benefits: benefits,
      planSlug: json['plan_slug'] as String? ?? json['slug'] as String?,
    );
  }
}
