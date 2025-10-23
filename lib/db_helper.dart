import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DBHelper {
  // Mobile/Desktop
  static Database? _db;

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
}
