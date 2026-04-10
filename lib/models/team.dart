class Team {
  final String id;
  final String name;
  final String city;
  final String logoColor;
  final DateTime createdAt;

  const Team({
    required this.id,
    required this.name,
    required this.city,
    required this.logoColor,
    required this.createdAt,
  });

  Team copyWith({
    String? id,
    String? name,
    String? city,
    String? logoColor,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      logoColor: logoColor ?? this.logoColor,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'logoColor': logoColor,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      name: map['name'] as String,
      city: map['city'] as String,
      logoColor: map['logoColor'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  String get fullName => city.isEmpty ? name : '$city $name';

  @override
  String toString() => fullName;
}
