import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase.dart';
import '../entities/employee_entity.dart';
import '../repositories/employee_repository.dart';

class CreateEmployee implements UseCase<EmployeeEntity, EmployeeEntity> {
  CreateEmployee(this.repository);

  final EmployeeRepository repository;

  @override
  Future<Either<Failure, EmployeeEntity>> call(EmployeeEntity params) {
    return repository.createEmployee(params);
  }
}
