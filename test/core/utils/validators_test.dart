import 'package:exelynt_learning/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty value', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email(null), 'Email is required');
    });

    test('rejects malformed email', () {
      expect(Validators.email('not-an-email'), 'Enter a valid email address');
      expect(Validators.email('missing@domain'), 'Enter a valid email address');
    });

    test('accepts a valid email', () {
      expect(Validators.email('user@example.com'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects empty value', () {
      expect(Validators.password(''), 'Password is required');
    });

    test('rejects passwords shorter than 6 characters', () {
      expect(Validators.password('12345'), 'Password must be at least 6 characters');
    });

    test('accepts a 6+ character password', () {
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects empty value', () {
      expect(Validators.confirmPassword('', 'abc123'), 'Please confirm your password');
    });

    test('rejects mismatched passwords', () {
      expect(Validators.confirmPassword('abc124', 'abc123'), 'Passwords do not match');
    });

    test('accepts matching passwords', () {
      expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
    });
  });

  group('Validators.required', () {
    test('rejects empty/whitespace-only value with field name in message', () {
      expect(Validators.required('   ', field: 'Name'), 'Name is required');
    });

    test('accepts non-empty value', () {
      expect(Validators.required('John'), isNull);
    });
  });

  group('Validators.mobile', () {
    test('rejects empty value', () {
      expect(Validators.mobile(''), 'Mobile number is required');
    });

    test('rejects values that are not exactly 10 digits', () {
      const message = 'Mobile number must be exactly 10 digits';
      expect(Validators.mobile('12345'), message);
      expect(Validators.mobile('987654321'), message);
      expect(Validators.mobile('98765432101'), message);
      expect(Validators.mobile('abcdefghij'), message);
      expect(Validators.mobile('98765 4321'), message);
    });

    test('accepts a valid mobile number', () {
      expect(Validators.mobile('9876543210'), isNull);
    });
  });
}
