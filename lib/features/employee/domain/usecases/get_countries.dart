import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase.dart';
import '../entities/country_entity.dart';
import '../repositories/country_repository.dart';

class GetCountries implements UseCase<List<CountryEntity>, NoParams> {
  GetCountries(this.repository);

  final CountryRepository repository;

  @override
  Future<Either<Failure, List<CountryEntity>>> call(NoParams params) {
    return repository.getCountries();
  }
}
