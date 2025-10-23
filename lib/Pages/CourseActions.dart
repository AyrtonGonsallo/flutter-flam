import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flam/Pages/Courses.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Constants/ApiConstants.dart';
import '../Models/Cours.dart';
import 'CoursesAdherentsList.dart';
import 'CoursesCheckList.dart';
import 'Home.dart';
import 'TeacherAdherentsList.dart';

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

class _CourseActionsPageState extends State<CourseActionsPage> {
  late Future<Cours> courseFuture;
  late String apiUrl;
  late int userId;
  late int courseId;
  String searchQuery = '';
  bool sortAsc = true;
  int sortColumnIndex = 0;

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    courseId = widget.courseId;
    apiUrl = ApiConstants.baseUrl;
    courseFuture = fetchCours(widget.courseId);
  }

  Future<Cours> fetchCours(int courseId) async {
    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/dojo_cours/get_cours/$courseId"),
      );
      final data = jsonDecode(response.body);
      print(data);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Détails du cours"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey, // couleur du trait
            height: 1.0, // épaisseur du trait
          ),
        ),

        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: Image.asset('images/logo_blanc_transparent.png', height: 40),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Column(
                children: [
                  Image(image: AssetImage("images/logo_blanc_transparent.png")),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Icon(Icons.home),
                    title: Text("Accueil"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomePage(userId: userId),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.home),
                    title: Text("Mes cours"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CoursesListPage(userId: userId),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.people),
                    title: Text("Mes adhérents"),
                    onTap: (){
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_)=>TeacherAdherentsListPage(userId: userId))
                      );
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder(
        future: courseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Aucun cours trouvé.'));
          }

          final cours = snapshot.data;
          final now = DateTime.now();
          final formattedDate = formatDate(now, [dd, '/', mm, '/', yyyy]);

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  "${cours?.dojo!.nom} - ${cours?.jour} - ${cours?.heure.substring(0, 5)} - ${formattedDate}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    TextButton(
                      onPressed: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseCheckListPage(
                              userId: userId,
                              courseId: cours!.id,
                            ),
                          ),
                        ),
                      },
                      style: TextButton.styleFrom(
                        backgroundColor:
                            Color(0xFFD8BF6C), // Couleur de fond du bouton
                        padding: EdgeInsets.symmetric(
                          // Espace interne
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          // Coins arrondis (optionnel)
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),

                      child: Text(
                        'Faire l\'appel',
                        style: TextStyle(
                          color: Colors
                              .white, // ou n'importe quelle couleur de lien
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseAdherentsListPage(
                              userId: userId,
                              courseId: cours!.id,
                            ),
                          ),
                        ),
                      },
                      style: TextButton.styleFrom(
                        backgroundColor:
                            Color(0xFFD8BF6C), // Couleur de fond du bouton
                        padding: EdgeInsets.symmetric(
                          // Espace interne
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          // Coins arrondis (optionnel)
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),

                      child: Text(
                        'Voir les adhérents',
                        style: TextStyle(
                          color: Colors
                              .white, // ou n'importe quelle couleur de lien
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
