import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

import '../../../../../helpers/helpers.dart';

class MockCreditsRepository extends Mock implements CreditsRepository {}

CreditPackage _package(String id) => CreditPackage(
  id: id,
  name: id,
  description: '',
  price: 10,
  credits: 100,
  benefits: const [],
);

const _session = CreditCheckoutSession(
  checkoutSessionId: 'cs_1',
  checkoutSessionUrl: 'https://pay.test/cs_1',
);

void main() {
  late MockCreditsRepository repository;
  late ProviderContainer container;
  late Completer<Result<CreditCheckoutSession>> pending;

  setUp(() {
    repository = MockCreditsRepository();
    pending = Completer();
    when(
      () => repository.purchaseCredits(
        planId: any(named: 'planId'),
        email: any(named: 'email'),
      ),
    ).thenAnswer((_) => pending.future);
    container = ProviderContainer(
      overrides: [creditsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  CreditsNotifier notifier() =>
      container.read(creditsNotifierProvider.notifier);

  int purchaseCalls() => verify(
    () => repository.purchaseCredits(
      planId: any(named: 'planId'),
      email: any(named: 'email'),
    ),
  ).callCount;

  test(
    'a repeat or another plan while one is pending starts no request',
    () async {
      final first = notifier().purchasePackage(
        package: _package('pro'),
        email: 'a@example.com',
      );
      final repeat = await notifier().purchasePackage(
        package: _package('pro'),
        email: 'a@example.com',
      );
      final other = await notifier().purchasePackage(
        package: _package('team'),
        email: 'a@example.com',
      );

      expect(repeat, isNull);
      expect(other, isNull);
      expect(
        container.read(creditsNotifierProvider).purchasingPackageId,
        'pro',
      );

      pending.complete(const Success(_session));
      expect(await first, _session);
      expect(purchaseCalls(), 1);
    },
  );

  test('a new purchase can start once the pending one has finished', () async {
    final first = notifier().purchasePackage(
      package: _package('pro'),
      email: 'a@example.com',
    );
    pending.complete(const Failure(ApiFailure(message: 'declined')));
    expect(await first, isNull);
    expect(container.read(creditsNotifierProvider).purchasingPackageId, isNull);

    pending = Completer()..complete(const Success(_session));
    expect(
      await notifier().purchasePackage(
        package: _package('team'),
        email: 'a@example.com',
      ),
      _session,
    );
    expect(purchaseCalls(), 2);
  });
}
