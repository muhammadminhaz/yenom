import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String password;

  @HiveField(4)
  final String role;

  @HiveField(5)
  final String firstName;

  @HiveField(6)
  final String lastName;

  @HiveField(7)
  final String? city;

  @HiveField(8)
  final String? country;

  @HiveField(9)
  final String? continent;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.city,
    this.country,
    this.continent,
    required this.createdAt,
    required this.updatedAt,
  });
}
