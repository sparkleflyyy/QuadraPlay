/// Model untuk User
class UserModel {
  final String? id;
  final String userId;
  final String name;
  final String email;
  final String? passwordHash;
  final String role; // "user" | "admin"
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.passwordHash,
    required this.role,
    required this.createdAt,
  });

  /// Factory constructor untuk membuat UserModel dari JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String?,
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      passwordHash: json['password'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt: json['createdat'] != null 
          ? DateTime.tryParse(json['createdat'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Konversi UserModel ke JSON untuk disimpan
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'password': passwordHash ?? '',
      'role': role,
      'createdat': createdAt.toIso8601String(),
    };
  }

  /// Konversi ke JSON tanpa password (untuk response)
  Map<String, dynamic> toJsonSafe() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'role': role,
      'createdat': createdAt.toIso8601String(),
    };
  }

  /// Copy with method untuk update partial
  UserModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? passwordHash,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, name: $name, email: $email, role: $role)';
  }
}
