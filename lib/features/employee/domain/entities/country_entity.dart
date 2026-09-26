import 'package:equatable/equatable.dart';

class CountryEntity extends Equatable {
  const CountryEntity({required this.id, required this.name, this.flagUrl});

  final String id;
  final String name;
  final String? flagUrl;

  @override
  List<Object?> get props => [id, name, flagUrl];
}
