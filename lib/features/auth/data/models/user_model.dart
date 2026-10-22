class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'user',
    this.isActive = true,
  });

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager';

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role,
    'isActive':isActive,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        email: (json['email'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        role: (json['role'] as String?) ?? 'user',
        isActive: (json['isActive'] as bool?) ?? true,
      );


  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    bool? isActive,
  }) =>
      UserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name ?? this.name,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
      );
}
