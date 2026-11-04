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

    test('rejects dots in the wrong place', () {
      for (final email in [
        'a@b..com',
        'a..b@example.com',
        '.ab@example.com',
        'ab.@example.com',
        'ab@.example.com',
        'ab@example..co.uk',
      ]) {
        expect(
          Validators.validateEmail(context, email),
          'Please enter a valid email',
          reason: email,
        );
      }
    });

    test('rejects a domain label that starts or ends with a hyphen', () {
      expect(
        Validators.validateEmail(context, 'ab@-example.com'),
        'Please enter a valid email',
      );
      expect(
        Validators.validateEmail(context, 'ab@example-.com'),
        'Please enter a valid email',
      );
    });

    test('still accepts dotted names, plus tags, subdomains and hyphens', () {
      for (final email in [
        'first.last@example.com',
        'ada+zedu@mail.example.co.uk',
        'a_b%c@sub-domain.example.ng',
        'x@y.io',
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
