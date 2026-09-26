import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<UserEntity?> get authStateChanges => _remoteDataSource.authStateChanges;

  @override
  UserEntity? get currentUser => _remoteDataSource.currentUser;

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailPassword({
    required String email,
    required String password,
  }) => _guard(() => _remoteDataSource.signInWithEmailPassword(email: email, password: password));

  @override
  Future<Either<Failure, UserEntity>> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) => _guard(
    () => _remoteDataSource.registerWithEmailPassword(
      email: email,
      password: password,
      name: name,
    ),
  );

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() =>
      _guard(_remoteDataSource.signInWithGoogle);

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({required String email}) =>
      _guard(() => _remoteDataSource.sendPasswordResetEmail(email: email));

  @override
  Future<Either<Failure, void>> signOut() => _guard(_remoteDataSource.signOut);

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_messageForCode(e.code)));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const Left(AuthFailure('Google sign-in was cancelled'));
      }
      return Left(AuthFailure('Google sign-in failed: ${e.description ?? e.code}'));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'That password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
