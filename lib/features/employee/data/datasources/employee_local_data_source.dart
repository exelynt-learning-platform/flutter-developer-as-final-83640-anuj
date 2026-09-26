import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/employee_model.dart';

abstract class EmployeeLocalDataSource {
  Future<List<EmployeeModel>> getCachedEmployees();

  Future<void> cacheEmployees(List<EmployeeModel> employees);
}

class EmployeeSharedPrefsDataSource implements EmployeeLocalDataSource {
  static const _cacheKey = 'cached_employees';

  @override
  Future<List<EmployeeModel>> getCachedEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((json) => EmployeeModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> cacheEmployees(List<EmployeeModel> employees) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(employees.map((e) => e.toJson()..['id'] = e.id).toList());
    await prefs.setString(_cacheKey, encoded);
  }
}
