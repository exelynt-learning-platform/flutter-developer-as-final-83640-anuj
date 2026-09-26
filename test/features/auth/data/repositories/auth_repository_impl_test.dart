import 'package:exelynt_learning/core/error/failures.dart';
import 'package:exelynt_learning/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:exelynt_learning/features/auth/data/models/user_model.dart';
import 'package:exelynt_learning/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignInException, GoogleSignInExceptionCode;
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late MockAuthRemoteDataSource dataSource;
  late AuthRepositoryImpl repository;

  const user = UserModel(uid: 'u1', email: 'user@example.com', displayName: 'User');

  setUp(() {
    dataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(dataSource);
  });

  group('signInWithEmailPassword', () {
    test('returns the user on success', () async {
      when(() => dataSource.signInWithEmailPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => user);

      final result = await repository.signInWithEmailPassword(email: 'user@example.com', password: 'secret1');

      expect(result.getOrElse(() => throw StateError('expected Right')), user);
    });

    test('maps FirebaseAuthException("wrong-password") to a friendly AuthFailure', () async {
      when(() => dataSource.signInWithEmailPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(FirebaseAuthException(code: 'wrong-password'));

      final result = await repository.signInWithEmailPassword(email: 'user@example.com', password: 'wrong');

      expect(
        result.fold((f) => f, (_) => null),
        isA<AuthFailure>().having((f) => f.message, 'message', 'Incorrect email or password.'),
      );
    });

    test('maps FirebaseAuthException("user-not-found")', () async {
      when(() => dataSource.signInWithEmailPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(FirebaseAuthException(code: 'user-not-found'));

      final result = await repository.signInWithEmailPassword(email: 'nope@example.com', password: 'secret1');

      expect(
        result.fold((f) => f, (_) => null),
        isA<AuthFailure>().having((f) => f.message, 'message', 'No account found for that email.'),
      );
    });
  });

  group('registerWithEmailPassword', () {
    test('returns the created user on success', () async {
      when(() => dataSource.registerWithEmailPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          )).thenAnswer((_) async => user);

      final result = await repository.registerWithEmailPassword(
        email: 'user@example.com',
        password: 'secret1',
        name: 'User',
      );

      expect(result.isRight(), isTrue);
    });

    test('maps "email-already-in-use"', () async {
      when(() => dataSource.registerWithEmailPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      final result = await repository.registerWithEmailPassword(
        email: 'user@example.com',
        password: 'secret1',
        name: 'User',
      );

      expect(
        result.fold((f) => f, (_) => null),
        isA<AuthFailure>().having((f) => f.message, 'message', 'An account already exists for that email.'),
      );
    });
  });

  group('signInWithGoogle', () {
    test('returns the user on success', () async {
      when(() => dataSource.signInWithGoogle()).thenAnswer((_) async => user);

      final result = await repository.signInWithGoogle();

      expect(result.getOrElse(() => throw StateError('expected Right')), user);
    });

    test('maps a cancelled Google sign-in to a friendly AuthFailure', () async {
      when(() => dataSource.signInWithGoogle()).thenThrow(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      );

      final result = await repository.signInWithGoogle();

      expect(
        result.fold((f) => f, (_) => null),
        isA<AuthFailure>().having((f) => f.message, 'message', 'Google sign-in was cancelled'),
      );
    });

    test('maps other Google sign-in failures', () async {
      when(() => dataSource.signInWithGoogle()).thenThrow(
        const GoogleSignInException(code: GoogleSignInExceptionCode.uiUnavailable, description: 'no UI'),
      );

      final result = await repository.signInWithGoogle();

      expect(result.fold((f) => f, (_) => null), isA<AuthFailure>());
    });
  });

  group('sendPasswordResetEmail', () {
    test('succeeds', () async {
      when(() => dataSource.sendPasswordResetEmail(email: any(named: 'email'))).thenAnswer((_) async {});

      final result = await repository.sendPasswordResetEmail(email: 'user@example.com');

      expect(result.isRight(), isTrue);
    });

    test('maps failure', () async {
      when(() => dataSource.sendPasswordResetEmail(email: any(named: 'email')))
          .thenThrow(FirebaseAuthException(code: 'user-not-found'));

      final result = await repository.sendPasswordResetEmail(email: 'nope@example.com');

      expect(result.isLeft(), isTrue);
    });
  });

  group('signOut', () {
    test('delegates to the data source', () async {
      when(() => dataSource.signOut()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result.isRight(), isTrue);
      verify(() => dataSource.signOut()).called(1);
    });
  });

  group('passthrough getters', () {
    test('currentUser reflects the data source', () {
      when(() => dataSource.currentUser).thenReturn(user);
      expect(repository.currentUser, user);
    });

    test('authStateChanges reflects the data source stream', () {
      when(() => dataSource.authStateChanges).thenAnswer((_) => Stream.value(user));
      expect(repository.authStateChanges, emits(user));
    });
  });
}
