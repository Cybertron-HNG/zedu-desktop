import 'dart:async';

import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';
import '../../../../../helpers/helpers.dart';

// Fake notifier that avoids repository/locator setup while remaining
// type-compatible with authNotifierProvider.
class FakeForgotPasswordNotifier extends AuthNotifier {
  FakeForgotPasswordNotifier({
    AuthState initial = const AuthState(status: AuthStatus.unauthenticated),
    void Function(String email)? onForgotPassword,
    Future<bool>? pendingForgot,
  }) : _initial = initial,
       _onForgotPassword = onForgotPassword,
       _pendingForgot = pendingForgot;

  final AuthState _initial;
  final void Function(String email)? _onForgotPassword;
  final Future<bool>? _pendingForgot;

  @override
  AuthState build() => _initial;

  @override
  Future<bool> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true);
    _onForgotPassword?.call(email);
    final result = await _pendingForgot ?? true;
    state = state.copyWith(isLoading: false);
    return result;
  }

  @override
  Future<void> logout() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

Widget buildForgotPasswordViewUnderTest({
  FakeForgotPasswordNotifier? notifier,
}) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(
        () => notifier ?? FakeForgotPasswordNotifier(),
      ),
    ],
    child: buildTestMaterialApp(const ForgotPasswordView()),
  );
}

void main() {
  group('ForgotPasswordView', () {
    Future<void> pumpDesktopForgot(
      WidgetTester tester,
      FakeForgotPasswordNotifier notifier,
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
        var forgotCalls = 0;
        await pumpDesktopForgot(
          tester,
          FakeForgotPasswordNotifier(onForgotPassword: (_) => forgotCalls++),
        );
        await tester.enterText(find.byType(TextFormField).at(0), invalidEmail);
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
        expect(forgotCalls, 0);
      });
    }

    testWidgets('Enter submits valid email once and blocks double-submit', (
      tester,
    ) async {
      final pendingForgot = Completer<bool>();
      final attempts = <String>[];
      await pumpDesktopForgot(
        tester,
        FakeForgotPasswordNotifier(
          onForgotPassword: attempts.add,
          pendingForgot: pendingForgot.future,
        ),
      );
      final emailField = find.byType(TextFormField).at(0);
      await tester.enterText(emailField, 'user@example.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      // Refocus after each submission: Flutter's done action unfocuses.
      // Submit again before pumping to exercise the sync loading guard.
      await tester.tap(emailField);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.tap(emailField);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(attempts, ['user@example.com']);

      pendingForgot.complete(true);
      await tester.pumpAndSettle();

      // After loading clears + navigation, retry is permitted.
      // Navigation goes to Reset Password which needs an email extra;
      // just verify single submit happened while loading.
      expect(attempts, ['user@example.com']);
    });

    testWidgets('Submit button tap submits when form is valid', (tester) async {
      String? capturedEmail;
      await pumpDesktopForgot(
        tester,
        FakeForgotPasswordNotifier(
          onForgotPassword: (email) => capturedEmail = email,
        ),
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'user@example.com',
      );

      final submitButton = find.widgetWithText(ElevatedButton, 'Submit');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(capturedEmail, 'user@example.com');
    });
  });
}
