import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterWithEmailPassword implements UseCase<UserEntity, RegisterParams> {
  RegisterWithEmailPassword(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) {
    return repository.registerWithEmailPassword(
      email: params.email,
      password: params.password,
      name: params.name,
    );
  }
}

class RegisterParams {
  const RegisterParams({required this.email, required this.password, required this.name});

  final String email;
  final String password;
  final String name;
}
