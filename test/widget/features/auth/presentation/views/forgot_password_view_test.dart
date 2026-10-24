import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

// Fake notifier that avoids GetIt/locator setup while remaining type-compatible
// with authNotifierProvider (which is NotifierProvider<AuthNotifier, AuthState>).
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier({
    AuthState initial = const AuthState(status: AuthStatus.unauthenticated),
    void Function(String email)? onForgotPassword,
    Future<void>? pendingRequest,
  }) : _initial = initial,
       _onForgotPassword = onForgotPassword,
       _pendingRequest = pendingRequest;

  final AuthState _initial;
  final void Function(String email)? _onForgotPassword;
  final Future<void>? _pendingRequest;

  @override
  AuthState build() => _initial;

  @override
  Future<bool> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true);
    _onForgotPassword?.call(email);
    await _pendingRequest;
    state = state.copyWith(isLoading: false);
    return false;
  }
}

Widget buildForgotPasswordViewUnderTest({FakeAuthNotifier? notifier}) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => notifier ?? FakeAuthNotifier()),
    ],
    child: buildTestMaterialApp(const ForgotPasswordView()),
  );
}

void main() {
  group('ForgotPasswordView', () {
    Future<void> pumpView(
      WidgetTester tester,
      FakeAuthNotifier notifier,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1440, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        buildForgotPasswordViewUnderTest(notifier: notifier),
      );
      await tester.pump();
    }

    for (final invalidEmail in ['', 'invalid-email']) {
      testWidgets('Enter validates email "$invalidEmail" without submitting', (
        tester,
      ) async {
        var calls = 0;
        await pumpView(
          tester,
          FakeAuthNotifier(onForgotPassword: (_) => calls++),
        );
        await tester.enterText(find.byType(TextFormField), invalidEmail);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(
          find.text(
            invalidEmail.isEmpty
                ? 'Email is required'
                : 'Please enter a valid email',
          ),
          findsOneWidget,
        );
        expect(calls, 0);
      });
    }

    testWidgets('Enter submits a valid email once while the request runs', (
      tester,
    ) async {
      final pendingRequest = Completer<void>();
      final emails = <String>[];
      await pumpView(
        tester,
        FakeAuthNotifier(
          onForgotPassword: emails.add,
          pendingRequest: pendingRequest.future,
        ),
      );
      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'user@example.com ');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      // Refocus after each submission: Flutter's done action unfocuses the field.
      await tester.tap(emailField);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(emails, ['user@example.com']);

      pendingRequest.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('Enter does not submit while a request is already loading', (
      tester,
    ) async {
      var calls = 0;
      await pumpView(
        tester,
        FakeAuthNotifier(
          initial: const AuthState(
            status: AuthStatus.unauthenticated,
            isLoading: true,
          ),
          onForgotPassword: (_) => calls++,
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'user@example.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(calls, 0);
    });
  });
}
