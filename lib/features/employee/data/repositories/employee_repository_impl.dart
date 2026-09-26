import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/repositories/employee_repository.dart';
import '../datasources/employee_local_data_source.dart';
import '../datasources/employee_remote_data_source.dart';
import '../models/employee_model.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
  EmployeeRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final EmployeeRemoteDataSource _remoteDataSource;
  final EmployeeLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, List<EmployeeEntity>>> getEmployees() async {
    try {
      final employees = await _remoteDataSource.getEmployees();
      await _localDataSource.cacheEmployees(employees);
      return Right(employees);
    } on ApiException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EmployeeEntity>> getEmployeeById(String id) async {
    try {
      return Right(await _remoteDataSource.getEmployeeById(id));
    } on ApiException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EmployeeEntity>> createEmployee(EmployeeEntity employee) async {
    try {
      return Right(
        await _remoteDataSource.createEmployee(EmployeeModel.fromEntity(employee)),
      );
    } on ApiException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EmployeeEntity>> updateEmployee(EmployeeEntity employee) async {
    try {
      return Right(
        await _remoteDataSource.updateEmployee(EmployeeModel.fromEntity(employee)),
      );
    } on ApiException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEmployee(String id) async {
    try {
      await _remoteDataSource.deleteEmployee(id);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<List<EmployeeEntity>> getCachedEmployees() => _localDataSource.getCachedEmployees();
}
