import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:exelynt_learning/core/error/failures.dart';
import 'package:exelynt_learning/features/auth/domain/entities/user_entity.dart';
import 'package:exelynt_learning/features/auth/domain/repositories/auth_repository.dart';
import 'package:exelynt_learning/features/auth/domain/usecases/register_with_email_password.dart';
import 'package:exelynt_learning/features/auth/domain/usecases/send_password_reset_email.dart';
import 'package:exelynt_learning/features/auth/domain/usecases/sign_in_with_email_password.dart';
import 'package:exelynt_learning/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:exelynt_learning/features/auth/domain/usecases/sign_out.dart';
import 'package:exelynt_learning/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late StreamController<UserEntity?> authStateController;
  late AuthProvider provider;

  const user = UserEntity(uid: 'u1', email: 'user@example.com', displayName: 'User');

  setUp(() {
    repository = MockAuthRepository();
    authStateController = StreamController<UserEntity?>.broadcast();
    when(() => repository.authStateChanges).thenAnswer((_) => authStateController.stream);

    provider = AuthProvider(
      authRepository: repository,
      signInWithEmailPassword: SignInWithEmailPassword(repository),
      registerWithEmailPassword: RegisterWithEmailPassword(repository),
      signInWithGoogle: SignInWithGoogle(repository),
      sendPasswordResetEmail: SendPasswordResetEmail(repository),
      signOut: SignOut(repository),
    );
  });

  tearDown(() {
    authStateController.close();
    provider.dispose();
  });

  test('starts in the unknown state', () {
    expect(provider.status, AuthStatus.unknown);
  });

  test('moves to unauthenticated when the auth stream emits null', () async {
    authStateController.add(null);
    await Future<void>.delayed(Duration.zero);

    expect(provider.status, AuthStatus.unauthenticated);
    expect(provider.user, isNull);
  });

  test('moves to authenticated when the auth stream emits a user', () async {
    authStateController.add(user);
    await Future<void>.delayed(Duration.zero);

    expect(provider.status, AuthStatus.authenticated);
    expect(provider.user, user);
  });

  group('signIn', () {
    test('on success updates user/status and clears isSubmitting', () async {
      when(() => repository.signInWithEmailPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => const Right(user));

      final success = await provider.signIn(email: 'user@example.com', password: 'secret1');

      expect(success, isTrue);
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.isSubmitting, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('on failure sets errorMessage and does not authenticate', () async {
      when(() => repository.signInWithEmailPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => const Left(AuthFailure('Incorrect email or password.')));

      final success = await provider.signIn(email: 'user@example.com', password: 'wrong');

      expect(success, isFalse);
      expect(provider.errorMessage, 'Incorrect email or password.');
      expect(provider.status, isNot(AuthStatus.authenticated));
    });
  });

  group('signInWithGoogle', () {
    test('on success authenticates the user', () async {
      when(() => repository.signInWithGoogle()).thenAnswer((_) async => const Right(user));

      final success = await provider.signInWithGoogle();

      expect(success, isTrue);
      expect(provider.status, AuthStatus.authenticated);
    });

    test('on cancellation surfaces the error message', () async {
      when(() => repository.signInWithGoogle())
          .thenAnswer((_) async => const Left(AuthFailure('Google sign-in was cancelled')));

      final success = await provider.signInWithGoogle();

      expect(success, isFalse);
      expect(provider.errorMessage, 'Google sign-in was cancelled');
    });
  });

  group('sendPasswordReset', () {
    test('returns true on success', () async {
      when(() => repository.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async => const Right(null));

      final success = await provider.sendPasswordReset('user@example.com');

      expect(success, isTrue);
      expect(provider.isSubmitting, isFalse);
    });

    test('returns false and sets errorMessage on failure', () async {
      when(() => repository.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async => const Left(AuthFailure('No account found for that email.')));

      final success = await provider.sendPasswordReset('nope@example.com');

      expect(success, isFalse);
      expect(provider.errorMessage, 'No account found for that email.');
    });
  });

  group('logOut', () {
    test('delegates to the repository and resets isSubmitting', () async {
      when(() => repository.signOut()).thenAnswer((_) async => const Right(null));

      await provider.logOut();

      verify(() => repository.signOut()).called(1);
      expect(provider.isSubmitting, isFalse);
    });
  });

  test('clearError resets the error message', () async {
    when(() => repository.signInWithEmailPassword(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const Left(AuthFailure('boom')));
    await provider.signIn(email: 'a@a.com', password: 'secret1');
    expect(provider.errorMessage, isNotNull);

    provider.clearError();

    expect(provider.errorMessage, isNull);
  });
}
