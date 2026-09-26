import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/country_entity.dart';
import '../../domain/repositories/country_repository.dart';
import '../datasources/country_remote_data_source.dart';

class CountryRepositoryImpl implements CountryRepository {
  CountryRepositoryImpl(this._remoteDataSource);

  final CountryRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, List<CountryEntity>>> getCountries() async {
    try {
      return Right(await _remoteDataSource.getCountries());
    } on ApiException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
