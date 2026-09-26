import '../../domain/entities/country_entity.dart';

class CountryModel extends CountryEntity {
  const CountryModel({required super.id, required super.name, super.flagUrl});

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id']?.toString() ?? '',
      name: json['country']?.toString() ?? '',
      flagUrl: (json['flag'] as String?)?.isNotEmpty == true ? json['flag'] as String : null,
    );
  }
}
