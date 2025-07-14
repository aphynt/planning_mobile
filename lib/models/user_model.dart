part of 'models.dart';

class User {
  final int id;
  final String? uuid;
  final int statusEnabled;
  final String nik;
  final String? email;
  final String name;
  final String role;
  final String? avatar;
  final String? emailVerifiedAt;
  final int isSynced;
  final String? createdAt;
  final String? updatedAt;
  final String? updatedBy;
  final String? deletedBy;

  User({
    required this.id,
    this.uuid,
    required this.statusEnabled,
    required this.nik,
    this.email,
    required this.name,
    required this.role,
    this.avatar,
    this.emailVerifiedAt,
    required this.isSynced,
    this.createdAt,
    this.updatedAt,
    this.updatedBy,
    this.deletedBy,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _toInt(json['id']),
      uuid: json['uuid'],
      statusEnabled: _toInt(json['statusenabled']),
      nik: json['nik']?.toString() ?? '',
      email: json['email'],
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      avatar: json['avatar'],
      emailVerifiedAt: json['email_verified_at'],
      isSynced: _toInt(json['is_synced']),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      updatedBy: json['updated_by'],
      deletedBy: json['deleted_by'],
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'uuid': uuid,
        'statusenabled': statusEnabled,
        'nik': nik,
        'email': email,
        'name': name,
        'role': role,
        'avatar': avatar,
        'email_verified_at': emailVerifiedAt,
        'is_synced': isSynced,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'updated_by': updatedBy,
        'deleted_by': deletedBy,
      };
}