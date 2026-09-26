import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase.dart';
import '../repositories/auth_repository.dart';

class SignOut implements UseCase<void, NoParams> {
  SignOut(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.signOut();
  }
}
