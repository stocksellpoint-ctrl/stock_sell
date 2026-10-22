class CustomerModel {
  final String? id;
  final String name;
  final String phone;
  final String email;
  final String? address;
  final DateTime createdAt;

  const CustomerModel({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.address,
    required this.createdAt,
  });

  CustomerModel copyWith({
    String? id, String? name, String? phone, String? email,
    String? address, DateTime? createdAt,
  }) =>
      CustomerModel(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'phone': phone, 'email': email,
        'address': address, 'createdAt': createdAt.toIso8601String(),
      };
  Map<String, dynamic> toApiJson() => {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      if (email.isNotEmpty) 'email': email,
      if (address != null && address!.isNotEmpty) 'address': address,
    };

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        id: json['id']?.toString(),
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String? ?? '',
        address: json['address'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  factory CustomerModel.fromApiJson(Map<String, dynamic> json) => CustomerModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String? ?? '',
      address: json['address'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
}