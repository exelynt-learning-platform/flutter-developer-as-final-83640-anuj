import 'package:flutter/foundation.dart';

import '../../../../core/usecase.dart';
import '../../domain/entities/employee_entity.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/usecases/create_employee.dart';
import '../../domain/usecases/delete_employee.dart';
import '../../domain/usecases/get_employee_by_id.dart';
import '../../domain/usecases/get_employees.dart';
import '../../domain/usecases/update_employee.dart';

enum EmployeeListStatus { initial, loading, loaded, error }

enum EmployeeFilterField { name, email, mobile, country }

extension EmployeeFilterFieldLabel on EmployeeFilterField {
  String get label {
    switch (this) {
      case EmployeeFilterField.name:
        return 'Name';
      case EmployeeFilterField.email:
        return 'Email';
      case EmployeeFilterField.mobile:
        return 'Mobile';
      case EmployeeFilterField.country:
        return 'Country';
    }
  }
}

class EmployeeProvider extends ChangeNotifier {
  EmployeeProvider({
    required EmployeeRepository repository,
    required GetEmployees getEmployees,
    required GetEmployeeById getEmployeeById,
    required CreateEmployee createEmployee,
    required UpdateEmployee updateEmployee,
    required DeleteEmployee deleteEmployee,
  }) : _repository = repository,
       _getEmployees = getEmployees,
       _getEmployeeById = getEmployeeById,
       _createEmployee = createEmployee,
       _updateEmployee = updateEmployee,
       _deleteEmployee = deleteEmployee;

  final EmployeeRepository _repository;
  final GetEmployees _getEmployees;
  final GetEmployeeById _getEmployeeById;
  final CreateEmployee _createEmployee;
  final UpdateEmployee _updateEmployee;
  final DeleteEmployee _deleteEmployee;

  EmployeeListStatus _status = EmployeeListStatus.initial;
  List<EmployeeEntity> _employees = [];
  String? _errorMessage;
  bool _isRefreshing = false;
  bool _isMutating = false;
  bool _isShowingCache = false;

  EmployeeFilterField? _filterField;
  String _filterQuery = '';

  String? _searchId;
  EmployeeEntity? _searchResult;
  bool _isSearching = false;
  String? _searchError;

  EmployeeListStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isRefreshing => _isRefreshing;
  bool get isMutating => _isMutating;
  bool get isShowingCache => _isShowingCache;

  EmployeeFilterField? get filterField => _filterField;
  String get filterQuery => _filterQuery;
  bool get isFilterActive => _filterField != null && _filterQuery.trim().isNotEmpty;

  bool get isSearchingById => _searchId != null && _searchId!.isNotEmpty;
  bool get isSearchInFlight => _isSearching;
  EmployeeEntity? get searchResult => _searchResult;
  String? get searchError => _searchError;

  List<EmployeeEntity> get employees {
    if (_filterField == null || _filterQuery.trim().isEmpty) {
      return _employees;
    }
    final query = _filterQuery.trim().toLowerCase();
    return _employees.where((employee) {
      final value = switch (_filterField!) {
        EmployeeFilterField.name => employee.name,
        EmployeeFilterField.email => employee.email,
        EmployeeFilterField.mobile => employee.mobile,
        EmployeeFilterField.country => employee.country,
      };
      return value.toLowerCase().contains(query);
    }).toList();
  }

  List<EmployeeEntity> idSuggestions(String query, {int limit = 8}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final startsWith = <EmployeeEntity>[];
    final contains = <EmployeeEntity>[];
    for (final employee in _employees) {
      if (employee.id.startsWith(trimmed)) {
        startsWith.add(employee);
      } else if (employee.id.contains(trimmed)) {
        contains.add(employee);
      }
    }
    return [...startsWith, ...contains].take(limit).toList();
  }

  Future<void> fetchEmployees() async {
    _status = EmployeeListStatus.loading;
    _errorMessage = null;
    notifyListeners();
    await _load();
  }

  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();
    await _load();
    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> _load() async {
    final result = await _getEmployees(const NoParams());
    await result.fold(
      (failure) async {
        final cached = await _repository.getCachedEmployees();
        if (cached.isNotEmpty) {
          _employees = cached;
          _status = EmployeeListStatus.loaded;
          _isShowingCache = true;
          _errorMessage = 'Showing offline data — ${failure.message}';
        } else {
          _status = EmployeeListStatus.error;
          _errorMessage = failure.message;
        }
      },
      (employees) async {
        _employees = employees;
        _status = EmployeeListStatus.loaded;
        _isShowingCache = false;
        _errorMessage = null;
      },
    );
    notifyListeners();
  }

  void setFilter(EmployeeFilterField? field, String query) {
    _filterField = field;
    _filterQuery = query;
    notifyListeners();
  }

  void clearFilter() {
    _filterField = null;
    _filterQuery = '';
    notifyListeners();
  }

  Future<void> searchById(String id) async {
    _searchId = id;
    if (id.trim().isEmpty) {
      clearSearch();
      return;
    }
    _isSearching = true;
    _searchError = null;
    _searchResult = null;
    notifyListeners();

    final result = await _getEmployeeById(id.trim());
    _isSearching = false;
    result.fold(
      (failure) {
        _searchResult = null;
        _searchError = 'No employee found for ID "$id"';
      },
      (employee) {
        _searchResult = employee;
        _searchError = null;
      },
    );
    notifyListeners();
  }

  void clearSearch() {
    _searchId = null;
    _searchResult = null;
    _searchError = null;
    _isSearching = false;
    notifyListeners();
  }

  Future<bool> addEmployee(EmployeeEntity employee) async {
    _isMutating = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _createEmployee(employee);
    _isMutating = false;
    final success = result.fold((failure) {
      _errorMessage = failure.message;
      return false;
    }, (created) {
      _employees = [created, ..._employees];
      return true;
    });
    notifyListeners();
    return success;
  }

  Future<bool> editEmployee(EmployeeEntity employee) async {
    _isMutating = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _updateEmployee(employee);
    _isMutating = false;
    final success = result.fold((failure) {
      _errorMessage = failure.message;
      return false;
    }, (updated) {
      _employees = _employees.map((e) => e.id == updated.id ? updated : e).toList();
      return true;
    });
    notifyListeners();
    return success;
  }

  Future<bool> removeEmployee(String id) async {
    _isMutating = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _deleteEmployee(id);
    _isMutating = false;
    final success = result.fold((failure) {
      _errorMessage = failure.message;
      return false;
    }, (_) {
      _employees = _employees.where((e) => e.id != id).toList();
      return true;
    });
    notifyListeners();
    return success;
  }
}
