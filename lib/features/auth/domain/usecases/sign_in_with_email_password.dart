import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmailPassword implements UseCase<UserEntity, SignInParams> {
  SignInWithEmailPassword(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams params) {
    return repository.signInWithEmailPassword(email: params.email, password: params.password);
  }
}

class SignInParams {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;
}
