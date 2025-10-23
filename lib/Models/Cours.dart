import 'CoursProf.dart';
import 'Dojo.dart';

class Cours {
  final int id;
  final String jour;
  final String heure;
  final String categorieAge;
  final int dojoId;
  final Dojo? dojo;
  final CoursProf? coursProf;

  Cours({
    required this.id,
    required this.jour,
    required this.heure,
    required this.categorieAge,
    required this.dojoId,
    this.dojo,

     this.coursProf,
  });

  factory Cours.fromJson(Map<String, dynamic> json) {
    return Cours(
      id: json['id'],
      jour: json['jour'],
      heure: json['heure'],
      categorieAge: json['categorie_age'],
      dojoId: json['dojoId'],
      dojo: json['Dojo'] != null ? Dojo.fromJson(json['Dojo']) : null,
      coursProf: json['CoursProf'] !=null ? CoursProf.fromJson(json['CoursProf']) :null,
    );
  }
}
