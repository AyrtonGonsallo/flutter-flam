class Role {
  final int id;
  final String titre;

  Role({required this.id, required this.titre});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      titre: json['titre'],
    );
  }
}
