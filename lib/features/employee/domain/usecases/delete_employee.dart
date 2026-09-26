import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase.dart';
import '../repositories/employee_repository.dart';

class DeleteEmployee implements UseCase<void, String> {
  DeleteEmployee(this.repository);

  final EmployeeRepository repository;

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deleteEmployee(id);
  }
}
