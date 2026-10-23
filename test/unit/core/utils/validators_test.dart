import 'package:zedu/core/core.dart';
import '../../../helpers/helpers.dart';

// validateEmail takes a BuildContext but never reads it.
class _MockBuildContext extends Mock implements BuildContext {}

void main() {
  final context = _MockBuildContext();

  group('Validators.validateEmail', () {
    test('accepts a valid email', () {
      expect(Validators.validateEmail(context, 'you@example.com'), isNull);
    });

    test('accepts an email with leading or trailing spaces', () {
      expect(Validators.validateEmail(context, 'you@example.com '), isNull);
      expect(Validators.validateEmail(context, ' you@example.com'), isNull);
      expect(Validators.validateEmail(context, '  you@example.com  '), isNull);
      expect(Validators.validateEmail(context, 'you@example.com\t'), isNull);
    });

    test('accepts valid emails with dots, plus tags and subdomains', () {
      for (final email in [
        'first.last@example.com',
        'first.last+tag@mail.school.co.uk',
        'a_b%c@sub-domain.example.org',
        'x@a-b.io',
      ]) {
        expect(Validators.validateEmail(context, email), isNull, reason: email);
      }
    });

    test('requires an email when the field is empty or only whitespace', () {
      expect(Validators.validateEmail(context, null), 'Email is required');
      expect(Validators.validateEmail(context, ''), 'Email is required');
      expect(Validators.validateEmail(context, '   '), 'Email is required');
    });

    test('rejects invalid emails', () {
      for (final email in [
        'you@',
        'you example.com',
        'you@example',
        'you @example.com',
        '@example.com',
        'a@b..com',
        'a@-b.com',
        'a@b-.com',
        'a@.x.com',
        '..a@x.com',
        'a..b@x.com',
        'a.@x.com',
      ]) {
        expect(
          Validators.validateEmail(context, email),
          'Please enter a valid email',
          reason: email,
        );
      }
    });
  });
}
