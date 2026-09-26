import '../../../../core/network/api_client.dart';
import '../models/country_model.dart';

abstract class CountryRemoteDataSource {
  Future<List<CountryModel>> getCountries();
}

class CountryApiDataSource implements CountryRemoteDataSource {
  CountryApiDataSource(this._client);

  final ApiClient _client;

  @override
  Future<List<CountryModel>> getCountries() async {
    final data = await _client.get('/country') as List<dynamic>;
    return data.map((json) => CountryModel.fromJson(json as Map<String, dynamic>)).toList();
  }
}
