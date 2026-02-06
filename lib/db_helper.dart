import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'Constants/ApiConstants.dart';


class DBHelper {
  // Mobile/Desktop
  static Database? _db;

  static String get API_URL {
    final url = ApiConstants.baseUrl;;

    if (url == null || url.isEmpty) {
      return "http://localhost:3000";
    }

    return url;
  }


  static Future<void> init() async {
    if (!kIsWeb) {
      _db ??= await _getDatabase();
    }
  }

  static Future<Database> _getDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'user.db');
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE utilisateur (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nom TEXT,
          prenom TEXT,
          email TEXT,
          role TEXT,
          token TEXT,
          user_id INTEGER
        )
      ''');
    });
  }

  static Future<void> insertUser(Map<String, dynamic> user) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('utilisateur', jsonEncode(user));
    } else {
      final db = _db ?? await _getDatabase();
      await db.insert('utilisateur', user, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  static Future<Map<String, dynamic>?> getUser() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('utilisateur');
      if (userString != null) {
        return jsonDecode(userString);
      }
      return null;
    } else {
      final db = _db ?? await _getDatabase();
      final List<Map<String, dynamic>> result = await db.query('utilisateur', limit: 1);
      return result.isNotEmpty ? result.first : null;
    }
  }

  static Future<Map<String, dynamic>?> getUtilisateurLocal() async {
    if (kIsWeb) {
      // Web : utilise SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('utilisateur');
      if (userString != null) {
        return jsonDecode(userString);
      }
      return null;
    } else {
      // Mobile/Desktop : sqflite
      final db = _db ?? await _getDatabase();
      final List<Map<String, dynamic>> result =
      await db.query('utilisateur', limit: 1);
      if (result.isNotEmpty) {
        return result.first;
      } else {
        return null;
      }
    }
  }

  static Future<void> clearUser() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('utilisateur');
    } else {
      final db = _db ?? await _getDatabase();
      await db.delete('utilisateur');
    }
  }

  // ============================================================
  // NOUVELLES MÉTHODES POUR LE DASHBOARD DYNAMIQUE
  // ============================================================

  /// Récupère les données de présence de la semaine de travail
  static Future<Map<String, dynamic>?> getPresenceSemaineTravail() async {
    try {
      final user = await getUtilisateurLocal();
      if (user == null || user['token'] == null) {
        print('Aucun utilisateur connecté');
        return null;
      }

      // Appel API
      final response = await http.get(
        Uri.parse('$API_URL/api/statistiques/presence_semaine_travail'),
        headers: {
          'Authorization': 'Bearer ${user['token']}',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout lors de la récupération des présences');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ======== LOGIQUE IDENTIQUE À FLASK ========

        final presencesTotal = data['presencesTotal'] ?? 0;
        final judokasTotal = data['judokasDistinctsTotal'] ?? 0;

        double presencesParJudoka = 0;

        if (judokasTotal > 0) {
          presencesParJudoka =
              double.parse((presencesTotal / judokasTotal).toStringAsFixed(1));
        }

        return {
          'semaineTravail': data['semaineTravail'],

          'pourcentageSemaine': data['pourcentageSemaine'] ?? 0,

          'pourcentageTotal': data['pourcentageTotal'] ?? 0,

          'presences_par_judokas': presencesParJudoka,
        };

      } else if (response.statusCode == 401) {
        print('Token expiré ou invalide');
        return null;

      } else {
        print('Erreur API: ${response.statusCode}');
        return null;
      }

    } catch (e) {
      print('Erreur getPresenceSemaineTravail: $e');

      // Données par défaut
      return {
        'semaineTravail': null,
        'pourcentageSemaine': 0,
        'pourcentageTotal': 0,
        'presences_par_judokas': 0,
      };
    }
  }



  /// Récupère les présences par dojo et par catégorie d'âge
  static Future<List<Map<String, dynamic>>> getPresenceParDojo() async {
    try {
      final user = await getUtilisateurLocal();
      if (user == null || user['token'] == null) {
        print('Aucun utilisateur connecté');
        return [];
      }
      final dojoId = user['dojo_id'];
      print('recherche : $API_URL/api/statistiques/presences_par_dojo/$dojoId');

      // Appel API
      final response = await http.get(
        Uri.parse('$API_URL/api/statistiques/presences_par_dojo/$dojoId'),
        headers: {
          'Authorization': 'Bearer ${user['token']}',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout lors de la récupération des présences par dojo');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return data.map((dojo) {
            final categories = dojo['categories'] ?? [];
            return {
              'dojoName': dojo['dojoName'] ?? '',
              'categories': (categories as List).map((cat) {
                return {
                  'categorie_age': cat['categorie_age'] ?? '',
                  'pourcentage': cat['pourcentage'] ?? 0,
                };
              }).toList(),
            };
          }).toList().cast<Map<String, dynamic>>();
        }
        return [];
      } else if (response.statusCode == 401) {
        print('Token expiré ou invalide');
        return [];
      } else {
        print('Erreur API: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erreur getPresenceParDojo: $e');
      return [];
    }
  }

  // ============================================================
  // MÉTHODES UTILITAIRES
  // ============================================================

  /// Vérifie si le token de l'utilisateur est encore valide
  static Future<bool> isTokenValid() async {
    try {
      final user = await getUtilisateurLocal();
      if (user == null || user['token'] == null) {
        return false;
      }

      // Vous pouvez ajouter une vérification API ici
      final response = await http.get(
        Uri.parse('$API_URL/api/auth/verify'),
        headers: {
          'Authorization': 'Bearer ${user['token']}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la vérification du token: $e');
      return false;
    }
  }

  /// Rafraîchit le token de l'utilisateur
  static Future<bool> refreshToken() async {
    try {
      final user = await getUtilisateurLocal();
      if (user == null || user['token'] == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$API_URL/api/auth/refresh'),
        headers: {
          'Authorization': 'Bearer ${user['token']}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['token'] != null) {
          user['token'] = data['token'];
          await insertUser(user);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Erreur lors du rafraîchissement du token: $e');
      return false;
    }
  }


  // ============================================================
// 🔥 STATS GLOBALES PROF (semaine actuelle + précédente)
// ============================================================

  static Future<Map<String, dynamic>?> getStatsProfGlobal(int profId) async {
    try {
      final user = await getUtilisateurLocal();

      if (user == null || user['token'] == null) {
        print('Aucun utilisateur connecté');
        return null;
      }

      final uri = Uri.parse(
          '$API_URL/api/statistiques/get_stats_profs/$profId/global'
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${user['token']}',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout récupération stats globales');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      if (response.statusCode == 401) {
        print('Token invalide / expiré');
        return null;
      }

      print('Erreur API stats: ${response.statusCode}');
      return null;

    } catch (e) {
      print('Erreur getStatsProfGlobal: $e');
      return null;
    }
  }

}