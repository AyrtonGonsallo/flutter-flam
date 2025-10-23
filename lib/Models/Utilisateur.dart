import 'Cours.dart';
import 'Dojo.dart';
import 'Role.dart';

class Utilisateur {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String? categorie_age;
  final String? date_inscription;
  final String? telephone;

  final int? roleId;
  final int dojoId;
  final Role? role;
  final Dojo? dojo;
  final List<Cours>? cours;

  Utilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.categorie_age,
    this.date_inscription,
    this.telephone,
    this.roleId,
    required this.dojoId,
    this.role,
    this.dojo,
    this.cours,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      categorie_age: json['categorie_age'], // nullable → ok si null ou absent
      date_inscription: json['date_inscription'],
      telephone: json['telephone'],
      roleId: json['roleId'],
      dojoId: json['dojoId'] ?? 0,
      role: json['Role'] != null ? Role.fromJson(json['Role']) : null,
      dojo: json['Dojo'] != null ? Dojo.fromJson(json['Dojo']) : null,
      cours: json['Cours'] != null
          ? (json['Cours'] as List)
          .map((e) => Cours.fromJson(e))
          .toList()
          : null,
    );
  }
}

