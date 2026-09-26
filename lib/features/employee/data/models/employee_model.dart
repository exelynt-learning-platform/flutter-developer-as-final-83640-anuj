import '../../domain/entities/employee_entity.dart';

class EmployeeModel extends EmployeeEntity {
  const EmployeeModel({
    super.id,
    required super.name,
    required super.email,
    required super.mobile,
    required super.country,
    required super.state,
    required super.district,
    super.avatarUrl,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      avatarUrl: (json['avatar'] as String?)?.isNotEmpty == true
          ? json['avatar'] as String
          : null,
    );
  }

  factory EmployeeModel.fromEntity(EmployeeEntity entity) {
    return EmployeeModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      mobile: entity.mobile,
      country: entity.country,
      state: entity.state,
      district: entity.district,
      avatarUrl: entity.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'mobile': mobile,
    'country': country,
    'state': state,
    'district': district,
    'avatar': avatarUrl ?? '',
  };
}
