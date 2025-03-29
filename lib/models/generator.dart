class Generator {
  final int? id;
  final String name;
  final DateTime createdAt;

  Generator({
    this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Generator.fromMap(Map<String, dynamic> map) {
    return Generator(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
