import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _boxName = 'users';
  static const String _sessionKey = 'current_user_id';
  static const uuid = Uuid();

  static Box<UserModel> get _box => Hive.box<UserModel>(_boxName);

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static Future<void> seedAdminIfNeeded() async {
    if (_box.isEmpty) {
      final admin = UserModel(
        id: uuid.v4(),
        username: 'admin',
        passwordHash: hashPassword('admin123'),
        role: 'admin',
        createdAt: DateTime.now(),
        isActive: true,
      );
      await _box.put(admin.id, admin);
    }
  }

  static UserModel? login(String username, String password) {
    final hash = hashPassword(password);
    try {
      return _box.values.firstWhere(
        (u) => u.username == username && u.passwordHash == hash && u.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<UserModel> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    final user = UserModel(
      id: uuid.v4(),
      username: username,
      passwordHash: hashPassword(password),
      role: role,
      createdAt: DateTime.now(),
      isActive: true,
    );
    await _box.put(user.id, user);
    return user;
  }

  static List<UserModel> getAllUsers() => _box.values.toList();

  static Future<void> toggleUserStatus(String userId) async {
    final user = _box.get(userId);
    if (user != null) {
      user.isActive = !user.isActive;
      await user.save();
    }
  }

  static Future<void> deleteUser(String userId) async {
    await _box.delete(userId);
  }

  static Future<void> updatePassword(String userId, String newPassword) async {
    final user = _box.get(userId);
    if (user != null) {
      user.passwordHash = hashPassword(newPassword);
      await user.save();
    }
  }

  static bool usernameExists(String username) {
    return _box.values.any((u) => u.username == username);
  }

  /// Returns true if at least one admin account exists in the database.
  static bool hasAnyAdmin() {
    return _box.values.any((u) => u.role == 'admin');
  }
}
