class Contact {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String avatar;
  final bool isFavorite;

  Contact({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.avatar,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'avatar': avatar,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map){
    return Contact(
        id: map['id'],
        name: map['name'],
        phone: map['phone'],
        email: map['email'],
        address: map['address'],
        avatar: map['avatar'] ?? '',
        isFavorite: map['isFavorite'] == 1
    );
  }

  Contact copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? avatar,
    bool? isFavorite,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      avatar: avatar ?? this.avatar,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}