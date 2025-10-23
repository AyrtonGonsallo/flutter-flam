class Dojo {
  final int id;
  final String nom;

  Dojo({required this.id, required this.nom});

  factory Dojo.fromJson(Map<String, dynamic> json) {
    return Dojo(
      id: json['id'],
      nom: json['nom'],
    );
  }
}
