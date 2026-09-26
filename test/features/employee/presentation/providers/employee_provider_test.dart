import 'package:dartz/dartz.dart';
import 'package:exelynt_learning/core/error/failures.dart';
import 'package:exelynt_learning/features/employee/domain/entities/employee_entity.dart';
import 'package:exelynt_learning/features/employee/domain/repositories/employee_repository.dart';
import 'package:exelynt_learning/features/employee/domain/usecases/create_employee.dart';
import 'package:exelynt_learning/features/employee/domain/usecases/delete_employee.dart';
import 'package:exelynt_learning/features/employee/domain/usecases/get_employee_by_id.dart';
import 'package:exelynt_learning/features/employee/domain/usecases/get_employees.dart';
import 'package:exelynt_learning/features/employee/domain/usecases/update_employee.dart';
import 'package:exelynt_learning/features/employee/presentation/providers/employee_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmployeeRepository extends Mock implements EmployeeRepository {}

void main() {
  late MockEmployeeRepository repository;
  late EmployeeProvider provider;

  const jane = EmployeeEntity(
    id: '1',
    name: 'Jane Doe',
    email: 'jane@example.com',
    mobile: '9876543210',
    country: 'India',
    state: 'Maharashtra',
    district: 'Pune',
  );
  const john = EmployeeEntity(
    id: '2',
    name: 'John Smith',
    email: 'john@example.com',
    mobile: '9123456780',
    country: 'USA',
    state: 'California',
    district: 'LA',
  );

  setUpAll(() {
    registerFallbackValue(jane);
  });

  setUp(() {
    repository = MockEmployeeRepository();
    provider = EmployeeProvider(
      repository: repository,
      getEmployees: GetEmployees(repository),
      getEmployeeById: GetEmployeeById(repository),
      createEmployee: CreateEmployee(repository),
      updateEmployee: UpdateEmployee(repository),
      deleteEmployee: DeleteEmployee(repository),
    );
  });

  group('fetchEmployees', () {
    test('on success moves to loaded with the fetched list', () async {
      when(() => repository.getEmployees()).thenAnswer((_) async => const Right([jane, john]));

      await provider.fetchEmployees();

      expect(provider.status, EmployeeListStatus.loaded);
      expect(provider.employees, [jane, john]);
      expect(provider.isShowingCache, isFalse);
    });

    test('on failure with no cache moves to the error state', () async {
      when(() => repository.getEmployees())
          .thenAnswer((_) async => const Left(NetworkFailure('No internet connection')));
      when(() => repository.getCachedEmployees()).thenAnswer((_) async => []);

      await provider.fetchEmployees();

      expect(provider.status, EmployeeListStatus.error);
      expect(provider.errorMessage, 'No internet connection');
    });

    test('on failure with cached data falls back to the cache', () async {
      when(() => repository.getEmployees())
          .thenAnswer((_) async => const Left(NetworkFailure('No internet connection')));
      when(() => repository.getCachedEmployees()).thenAnswer((_) async => [jane]);

      await provider.fetchEmployees();

      expect(provider.status, EmployeeListStatus.loaded);
      expect(provider.isShowingCache, isTrue);
      expect(provider.employees, [jane]);
    });
  });

  group('filtering', () {
    setUp(() async {
      when(() => repository.getEmployees()).thenAnswer((_) async => const Right([jane, john]));
      await provider.fetchEmployees();
    });

    test('filters by name (case-insensitive, partial match)', () {
      provider.setFilter(EmployeeFilterField.name, 'jane');
      expect(provider.employees, [jane]);
    });

    test('filters by country', () {
      provider.setFilter(EmployeeFilterField.country, 'usa');
      expect(provider.employees, [john]);
    });

    test('filters by email', () {
      provider.setFilter(EmployeeFilterField.email, 'JOHN@');
      expect(provider.employees, [john]);
    });

    test('filters by mobile', () {
      provider.setFilter(EmployeeFilterField.mobile, '98765');
      expect(provider.employees, [jane]);
    });

    test('isFilterActive is false for a blank query', () {
      provider.setFilter(EmployeeFilterField.name, '   ');
      expect(provider.isFilterActive, isFalse);
      expect(provider.employees, [jane, john]);
    });

    test('clearFilter restores the full list', () {
      provider.setFilter(EmployeeFilterField.name, 'jane');
      provider.clearFilter();
      expect(provider.employees, [jane, john]);
      expect(provider.isFilterActive, isFalse);
    });
  });

  group('idSuggestions', () {
    final e12 = jane.copyWith(id: '12');
    final e21 = john.copyWith(id: '21');
    final e3 = jane.copyWith(id: '3');

    setUp(() async {
      when(() => repository.getEmployees()).thenAnswer((_) async => Right([e21, e3, e12]));
      await provider.fetchEmployees();
    });

    test('returns nothing for an empty query', () {
      expect(provider.idSuggestions('  '), isEmpty);
    });

    test('lists IDs starting with the query before IDs that only contain it', () {
      expect(provider.idSuggestions('1'), [e12, e21]);
    });

    test('returns nothing when no ID matches', () {
      expect(provider.idSuggestions('9'), isEmpty);
    });

    test('respects the limit', () {
      expect(provider.idSuggestions('1', limit: 1), [e12]);
    });
  });

  group('searchById', () {
    test('populates searchResult when found', () async {
      when(() => repository.getEmployeeById('1')).thenAnswer((_) async => const Right(jane));

      await provider.searchById('1');

      expect(provider.isSearchingById, isTrue);
      expect(provider.searchResult, jane);
      expect(provider.searchError, isNull);
    });

    test('sets searchError when not found', () async {
      when(() => repository.getEmployeeById('999'))
          .thenAnswer((_) async => const Left(NetworkFailure('Not found')));

      await provider.searchById('999');

      expect(provider.searchResult, isNull);
      expect(provider.searchError, isNotNull);
    });

    test('clearSearch resets search state', () async {
      when(() => repository.getEmployeeById('1')).thenAnswer((_) async => const Right(jane));
      await provider.searchById('1');

      provider.clearSearch();

      expect(provider.isSearchingById, isFalse);
      expect(provider.searchResult, isNull);
    });
  });

  group('CRUD', () {
    test('addEmployee prepends the created employee on success', () async {
      when(() => repository.getEmployees()).thenAnswer((_) async => const Right([john]));
      await provider.fetchEmployees();

      when(() => repository.createEmployee(any())).thenAnswer((_) async => const Right(jane));

      final success = await provider.addEmployee(jane);

      expect(success, isTrue);
      expect(provider.employees, [jane, john]);
    });

    test('editEmployee replaces the matching employee on success', () async {
      when(() => repository.getEmployees()).thenAnswer((_) async => const Right([jane]));
      await provider.fetchEmployees();

      final updatedJane = jane.copyWith(name: 'Jane Updated');
      when(() => repository.updateEmployee(any())).thenAnswer((_) async => Right(updatedJane));

      final success = await provider.editEmployee(updatedJane);

      expect(success, isTrue);
      expect(provider.employees.single.name, 'Jane Updated');
    });

    test('removeEmployee deletes the matching employee on success', () async {
      when(() => repository.getEmployees()).thenAnswer((_) async => const Right([jane, john]));
      await provider.fetchEmployees();

      when(() => repository.deleteEmployee('1')).thenAnswer((_) async => const Right(null));

      final success = await provider.removeEmployee('1');

      expect(success, isTrue);
      expect(provider.employees, [john]);
    });

    test('removeEmployee keeps the list unchanged and sets errorMessage on failure', () async {
      when(() => repository.getEmployees()).thenAnswer((_) async => const Right([jane]));
      await provider.fetchEmployees();

      when(() => repository.deleteEmployee('1'))
          .thenAnswer((_) async => const Left(NetworkFailure('No internet connection')));

      final success = await provider.removeEmployee('1');

      expect(success, isFalse);
      expect(provider.errorMessage, 'No internet connection');
      expect(provider.employees, [jane]);
    });
  });
}
