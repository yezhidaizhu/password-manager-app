class Credential {
  Credential({
    String? id,
    required this.name,
    required this.username,
    required this.password,
    this.website = '',
    this.note = '',
    this.category = '账号',
    this.favorite = false,
    this.logoAsset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;
  final String username;
  final String password;
  final String website;
  final String note;
  final String category;
  final bool favorite;
  final String? logoAsset;
  final DateTime createdAt;
  final DateTime updatedAt;

  Credential copyWith({
    String? name,
    String? username,
    String? password,
    String? website,
    String? note,
    String? category,
    bool? favorite,
    String? logoAsset,
  }) {
    return Credential(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      note: note ?? this.note,
      category: category ?? this.category,
      favorite: favorite ?? this.favorite,
      logoAsset: logoAsset ?? this.logoAsset,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'password': password,
    'website': website,
    'note': note,
    'category': category,
    'favorite': favorite,
    'logoAsset': logoAsset,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Credential.fromJson(Map<String, Object?> json) {
    return Credential(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      website: json['website'] as String? ?? '',
      note: json['note'] as String? ?? '',
      category: json['category'] as String? ?? '账号',
      favorite: json['favorite'] as bool? ?? false,
      logoAsset: json['logoAsset'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }
}
