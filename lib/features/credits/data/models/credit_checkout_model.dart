import 'package:zedu/features/features.dart';

class CreditCheckoutModel extends CreditCheckoutSession {
  const CreditCheckoutModel({
    required super.checkoutSessionId,
    required super.checkoutSessionUrl,
  });

  factory CreditCheckoutModel.fromJson(Map<String, dynamic> json) {
    return CreditCheckoutModel(
      checkoutSessionId:
          json['checkout_session_id'] as String? ??
          json['session_id'] as String? ??
          '',
      checkoutSessionUrl:
          json['checkout_session_url'] as String? ??
          json['url'] as String? ??
          '',
    );
  }
}
