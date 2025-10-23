import 'package:flam/Models/Utilisateur.dart';

import 'Appel.dart';

class AdherentAvecAppel {
  final Utilisateur adherent;
   Appel? appel;

  AdherentAvecAppel({
    required this.adherent,
    this.appel,
  });

  factory AdherentAvecAppel.fromJson(Map<String, dynamic> json) {
    return AdherentAvecAppel(
      adherent: Utilisateur.fromJson(json['adherent']),
      appel: json['appel'] != null ? Appel.fromJson(json['appel']) : null,
    );
  }
}
