import 'package:flutter/foundation.dart';

import '../../../../core/usecase.dart';
import '../../domain/entities/country_entity.dart';
import '../../domain/usecases/get_countries.dart';

enum CountryListStatus { initial, loading, loaded, error }

class CountryProvider extends ChangeNotifier {
  CountryProvider({required GetCountries getCountries}) : _getCountries = getCountries;

  final GetCountries _getCountries;

  CountryListStatus _status = CountryListStatus.initial;
  List<CountryEntity> _countries = [];
  String? _errorMessage;

  CountryListStatus get status => _status;
  List<CountryEntity> get countries => _countries;
  String? get errorMessage => _errorMessage;

  Future<void> loadCountries() async {
    if (_status == CountryListStatus.loaded) return;
    _status = CountryListStatus.loading;
    notifyListeners();

    final result = await _getCountries(const NoParams());
    result.fold((failure) {
      _status = CountryListStatus.error;
      _errorMessage = failure.message;
    }, (countries) {
      _countries = countries;
      _status = CountryListStatus.loaded;
    });
    notifyListeners();
  }
}
