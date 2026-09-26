import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase.dart';
import '../entities/employee_entity.dart';
import '../repositories/employee_repository.dart';

class GetEmployeeById implements UseCase<EmployeeEntity, String> {
  GetEmployeeById(this.repository);

  final EmployeeRepository repository;

  @override
  Future<Either<Failure, EmployeeEntity>> call(String id) {
    return repository.getEmployeeById(id);
  }
}
