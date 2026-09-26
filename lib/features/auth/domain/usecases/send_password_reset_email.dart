import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase.dart';
import '../repositories/auth_repository.dart';

class SendPasswordResetEmail implements UseCase<void, String> {
  SendPasswordResetEmail(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, void>> call(String email) {
    return repository.sendPasswordResetEmail(email: email);
  }
}
