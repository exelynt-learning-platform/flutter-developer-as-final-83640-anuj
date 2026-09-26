import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase.dart';
import '../entities/employee_entity.dart';
import '../repositories/employee_repository.dart';

class GetEmployees implements UseCase<List<EmployeeEntity>, NoParams> {
  GetEmployees(this.repository);

  final EmployeeRepository repository;

  @override
  Future<Either<Failure, List<EmployeeEntity>>> call(NoParams params) {
    return repository.getEmployees();
  }
}
