import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flam/Pages/Courses.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../Constants/ApiConstants.dart';
import '../Models/Cours.dart';
import 'CoursesAdherentsList.dart';
import 'CoursesCheckList.dart';
import 'Home.dart';
import 'TeacherAdherentsList.dart';
import '../theme/app_colors.dart';

class CourseActionsPage extends StatefulWidget {
  final int userId;
  final int courseId;

  const CourseActionsPage({
    super.key,
    required this.userId,
    required this.courseId,
  });

  @override
  _CourseActionsPageState createState() => _CourseActionsPageState();
}
class CoursDate {
  final String date;

  CoursDate({required this.date});

  factory CoursDate.fromJson(Map<String, dynamic> json) {
    return CoursDate(date: json['date']);
  }
}
class _CourseActionsPageState extends State<CourseActionsPage> {
  late Future<Cours> courseFuture;
  late String apiUrl;
  late int userId;
  late int courseId;
  late Future<CoursDate> coursDateFuture;

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    courseId = widget.courseId;
    apiUrl = ApiConstants.baseUrl;
    courseFuture = fetchCours(widget.courseId);
    coursDateFuture = fetchCoursDate(widget.courseId);
  }

  Future<Cours> fetchCours(int courseId) async {
    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/dojo_cours/get_cours/$courseId"),
      );
      final data = jsonDecode(response.body);
      return Cours.fromJson(data);
    } on SocketException {
      throw Exception("Pas de connexion Internet.");
    } on TimeoutException {
      throw Exception("Le serveur met trop de temps à répondre.");
    } on FormatException {
      throw Exception("Réponse invalide du serveur.");
    } catch (e) {
      throw Exception("Erreur inattendue : $e");
    }
  }

  Future<CoursDate> fetchCoursDate(int courseId) async {
    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/adherents/get_course_date/$courseId"),
      );
      final data = jsonDecode(response.body);
      return CoursDate.fromJson(data);
    } catch (e) {
      throw Exception("Erreur fetchCoursDate : $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text("Détails du cours"),
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: Divider(color: Colors.transparent),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Image.asset('images/logo_blanc_transparent.png', height: 30),
          ),
        ],
      ),

      // ===== Drawer modernisé =====
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    "images/logo_blanc_transparent.png",
                    height: 50,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    _buildDrawerItem(
                      icon: Icons.home,
                      text: "Accueil",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomePage(userId: userId),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.class_,
                      text: "Mes cours",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CoursesListPage(userId: userId),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.group,
                      text: "Mes adhérents",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeacherAdherentsListPage(userId: userId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      body: FutureBuilder<Cours>(
        future: courseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Aucun cours trouvé.'));
          }

          final cours = snapshot.data!;
          final now = DateTime.now();
          final formattedDate = formatDate(now, [dd, '/', mm, '/', yyyy]);

          return Column(
            children: [

              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(29),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          FutureBuilder<CoursDate>(
                            future: coursDateFuture,
                            builder: (context, dateSnap) {
                              if (dateSnap.connectionState == ConnectionState.waiting) {
                                return const Text("Chargement date...");
                              } else if (dateSnap.hasError) {
                                return Text("Date indisponible");
                              } else if (!dateSnap.hasData) {
                                return const Text("Aucune date");
                              }
                              String humanDate(String d) {
                                final date = DateTime.parse(d);
                                return DateFormat('dd/MM/yyyy').format(date);
                              }

                              final date = dateSnap.data!.date;  // "2025-12-01"

                              return Text(
                                "${cours.dojo!.nom} - ${cours.jour} - ${cours.heure.substring(0, 5)} - ${humanDate(date)}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.dark,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _styledTileButton(
                                label: "Faire l'appel",
                                icon: Icons.check,
                                iconColor: AppColors.secondary,
                                backgroundColor: Colors.white,
                                textColor: AppColors.dark,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CourseCheckListPage(
                                        userId: userId,
                                        courseId: cours.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              _styledTileButton(
                                label: "Voir les adhérents",
                                icon: Icons.group,
                                iconColor: AppColors.secondary,
                                backgroundColor: Colors.white,
                                textColor: AppColors.dark,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CourseAdherentsListPage(
                                        userId: userId,
                                        courseId: cours.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _styledTileButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        padding: const EdgeInsets.symmetric(vertical: 26),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(
                icon,
                size: 28,
                color: iconColor,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Helper pour drawer items =====
  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        splashColor: Colors.black12,
        highlightColor: Colors.black12,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: Icon(icon, color: Colors.black87),
            title: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ),
      ),
    );
  }
}
