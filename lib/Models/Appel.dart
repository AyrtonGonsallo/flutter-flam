class Appel {
  final int id;
   bool status;
  final String date;
  final int adherentId;
  final int coursId;

  Appel({
    required this.id,
    required this.status,
    required this.date,
    required this.adherentId,
    required this.coursId,
  });

  factory Appel.fromJson(Map<String, dynamic> json) {
    return Appel(
      id: json['id'],
      status: json['status'],
      date: json['date'],
      adherentId: json['adherentId'],
      coursId: json['coursId'],
    );
  }
}
