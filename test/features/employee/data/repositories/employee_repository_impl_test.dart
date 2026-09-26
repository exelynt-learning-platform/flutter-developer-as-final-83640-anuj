import 'package:exelynt_learning/core/error/failures.dart';
import 'package:exelynt_learning/core/network/api_client.dart';
import 'package:exelynt_learning/features/employee/data/datasources/employee_local_data_source.dart';
import 'package:exelynt_learning/features/employee/data/datasources/employee_remote_data_source.dart';
import 'package:exelynt_learning/features/employee/data/models/employee_model.dart';
import 'package:exelynt_learning/features/employee/data/repositories/employee_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmployeeRemoteDataSource extends Mock implements EmployeeRemoteDataSource {}

class MockEmployeeLocalDataSource extends Mock implements EmployeeLocalDataSource {}

void main() {
  late MockEmployeeRemoteDataSource remote;
  late MockEmployeeLocalDataSource local;
  late EmployeeRepositoryImpl repository;

  const employee = EmployeeModel(
    id: '1',
    name: 'Jane Doe',
    email: 'jane@example.com',
    mobile: '9876543210',
    country: 'India',
    state: 'Maharashtra',
    district: 'Pune',
  );

  setUpAll(() {
    registerFallbackValue(const EmployeeModel(
      name: '',
      email: '',
      mobile: '',
      country: '',
      state: '',
      district: '',
    ));
  });

  setUp(() {
    remote = MockEmployeeRemoteDataSource();
    local = MockEmployeeLocalDataSource();
    repository = EmployeeRepositoryImpl(remote, local);
  });

  group('getEmployees', () {
    test('returns the list and caches it on success', () async {
      when(() => remote.getEmployees()).thenAnswer((_) async => [employee]);
      when(() => local.cacheEmployees(any())).thenAnswer((_) async {});

      final result = await repository.getEmployees();

      expect(result.getOrElse(() => []), [employee]);
      verify(() => local.cacheEmployees(any())).called(1);
    });

    test('maps an ApiException to a NetworkFailure', () async {
      when(() => remote.getEmployees()).thenThrow(ApiException('No internet connection'));

      final result = await repository.getEmployees();

      expect(
        result.fold((f) => f, (_) => null),
        isA<NetworkFailure>().having((f) => f.message, 'message', 'No internet connection'),
      );
    });
  });

  group('getEmployeeById', () {
    test('returns the employee on success', () async {
      when(() => remote.getEmployeeById('1')).thenAnswer((_) async => employee);

      final result = await repository.getEmployeeById('1');

      expect(result.getOrElse(() => throw StateError('expected Right')), employee);
    });

    test('maps a 404 ApiException to a failure', () async {
      when(() => remote.getEmployeeById('999'))
          .thenThrow(ApiException('Not found', statusCode: 404));

      final result = await repository.getEmployeeById('999');

      expect(result.isLeft(), isTrue);
    });
  });

  group('createEmployee', () {
    test('returns the created employee on success', () async {
      when(() => remote.createEmployee(any())).thenAnswer((_) async => employee);

      final result = await repository.createEmployee(employee);

      expect(result.getOrElse(() => throw StateError('expected Right')), employee);
    });

    test('maps failures to ServerFailure', () async {
      when(() => remote.createEmployee(any())).thenThrow(Exception('boom'));

      final result = await repository.createEmployee(employee);

      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });

  group('updateEmployee', () {
    test('returns the updated employee on success', () async {
      when(() => remote.updateEmployee(any())).thenAnswer((_) async => employee);

      final result = await repository.updateEmployee(employee);

      expect(result.isRight(), isTrue);
    });
  });

  group('deleteEmployee', () {
    test('succeeds', () async {
      when(() => remote.deleteEmployee('1')).thenAnswer((_) async {});

      final result = await repository.deleteEmployee('1');

      expect(result.isRight(), isTrue);
      verify(() => remote.deleteEmployee('1')).called(1);
    });

    test('maps failure', () async {
      when(() => remote.deleteEmployee('1')).thenThrow(ApiException('Not found', statusCode: 404));

      final result = await repository.deleteEmployee('1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('getCachedEmployees', () {
    test('delegates to the local data source', () async {
      when(() => local.getCachedEmployees()).thenAnswer((_) async => [employee]);

      final result = await repository.getCachedEmployees();

      expect(result, [employee]);
    });
  });
}
