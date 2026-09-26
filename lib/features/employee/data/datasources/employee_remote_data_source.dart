import '../../../../core/network/api_client.dart';
import '../models/employee_model.dart';

abstract class EmployeeRemoteDataSource {
  Future<List<EmployeeModel>> getEmployees();

  Future<EmployeeModel> getEmployeeById(String id);

  Future<EmployeeModel> createEmployee(EmployeeModel employee);

  Future<EmployeeModel> updateEmployee(EmployeeModel employee);

  Future<void> deleteEmployee(String id);
}

class EmployeeApiDataSource implements EmployeeRemoteDataSource {
  EmployeeApiDataSource(this._client);

  final ApiClient _client;

  @override
  Future<List<EmployeeModel>> getEmployees() async {
    final data = await _client.get('/employee') as List<dynamic>;
    return data.map((json) => EmployeeModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<EmployeeModel> getEmployeeById(String id) async {
    final data = await _client.get('/employee/$id') as Map<String, dynamic>;
    return EmployeeModel.fromJson(data);
  }

  @override
  Future<EmployeeModel> createEmployee(EmployeeModel employee) async {
    final data = await _client.post('/employee', employee.toJson()) as Map<String, dynamic>;
    return EmployeeModel.fromJson(data);
  }

  @override
  Future<EmployeeModel> updateEmployee(EmployeeModel employee) async {
    final data = await _client.put('/employee/${employee.id}', employee.toJson())
        as Map<String, dynamic>;
    return EmployeeModel.fromJson(data);
  }

  @override
  Future<void> deleteEmployee(String id) async {
    await _client.delete('/employee/$id');
  }
}
