import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/register_with_email_password.dart';
import '../../domain/usecases/send_password_reset_email.dart';
import '../../domain/usecases/sign_in_with_email_password.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthRepository authRepository,
    required SignInWithEmailPassword signInWithEmailPassword,
    required RegisterWithEmailPassword registerWithEmailPassword,
    required SignInWithGoogle signInWithGoogle,
    required SendPasswordResetEmail sendPasswordResetEmail,
    required SignOut signOut,
  }) : _authRepository = authRepository,
       _signInWithEmailPassword = signInWithEmailPassword,
       _registerWithEmailPassword = registerWithEmailPassword,
       _signInWithGoogle = signInWithGoogle,
       _sendPasswordResetEmail = sendPasswordResetEmail,
       _signOut = signOut {
    _authSubscription = _authRepository.authStateChanges.listen(_onAuthStateChanged);
  }

  final AuthRepository _authRepository;
  final SignInWithEmailPassword _signInWithEmailPassword;
  final RegisterWithEmailPassword _registerWithEmailPassword;
  final SignInWithGoogle _signInWithGoogle;
  final SendPasswordResetEmail _sendPasswordResetEmail;
  final SignOut _signOut;
  late final StreamSubscription<UserEntity?> _authSubscription;

  AuthStatus _status = AuthStatus.unknown;
  UserEntity? _user;
  bool _isSubmitting = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserEntity? get user => _user;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  void _onAuthStateChanged(UserEntity? user) {
    _user = user;
    _status = user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) {
    return _runAuthAction(
      () => _signInWithEmailPassword(SignInParams(email: email, password: password)),
    );
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) {
    return _runAuthAction(
      () => _registerWithEmailPassword(
        RegisterParams(email: email, password: password, name: name),
      ),
    );
  }

  Future<bool> signInWithGoogle() {
    return _runAuthAction(() => _signInWithGoogle(const NoParams()));
  }

  Future<bool> sendPasswordReset(String email) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _sendPasswordResetEmail(email);
    _isSubmitting = false;
    final success = result.fold((failure) {
      _errorMessage = failure.message;
      return false;
    }, (_) => true);
    notifyListeners();
    return success;
  }

  Future<void> logOut() async {
    _isSubmitting = true;
    notifyListeners();
    await _signOut(const NoParams());
    _isSubmitting = false;
    notifyListeners();
  }

  Future<bool> _runAuthAction(
    Future<dynamic> Function() action,
  ) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final result = await action();
    _isSubmitting = false;
    final success = result.fold((failure) {
      _errorMessage = failure.message;
      return false;
    }, (user) {
      _user = user as UserEntity;
      _status = AuthStatus.authenticated;
      return true;
    });
    notifyListeners();
    return success;
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
