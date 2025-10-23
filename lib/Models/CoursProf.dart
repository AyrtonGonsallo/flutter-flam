class CoursProf {
  final int coursId;
  final int utilisateurId;

  CoursProf({required this.coursId, required this.utilisateurId});

  factory CoursProf.fromJson(Map<String, dynamic> json) {
    return CoursProf(
      coursId: json['coursId'],
      utilisateurId: json['utilisateurId'],
    );
  }
}
