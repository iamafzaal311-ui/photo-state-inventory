import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String username;

  @HiveField(2)
  late String passwordHash;

  @HiveField(3)
  late String role; // 'admin' or 'user'

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  late bool isActive;

  UserModel({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });
}
