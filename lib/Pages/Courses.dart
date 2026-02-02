import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flam/Models/Utilisateur.dart';
import 'package:flam/Pages/Home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Constants/ApiConstants.dart';
import '../Models/Cours.dart';
import '../widgets/CoursWidget.dart';
import 'TeacherAdherentsList.dart';
import '../theme/app_colors.dart';

class CoursesListPage extends StatefulWidget {
  final int userId;

  const CoursesListPage({super.key, required this.userId});

  @override
  _CoursesListPageState createState() => _CoursesListPageState();
}

class _CoursesListPageState extends State<CoursesListPage> {
  late Future<Utilisateur> userFuture;
  late String apiUrl;
  late int userId;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    apiUrl = ApiConstants.baseUrl;
    userFuture = fetchUtilisateur(apiUrl, widget.userId);
  }

  Future<Utilisateur> fetchUtilisateur(String apiUrl, int userId) async {
    try {
      final response =
      await http.get(Uri.parse("$apiUrl/api/auth/get_all_teacher_datas/$userId"));
      final data = jsonDecode(response.body);
      return Utilisateur.fromJson(data);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Mes cours",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey,
            height: 1.0,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Image.asset('images/logo_blanc_transparent.png', height: 40),
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
                  color: Colors.black87,
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
                      icon: Icons.people,
                      text: "Mes adhérents",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TeacherAdherentsListPage(userId: userId)),
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

      body: FutureBuilder<Utilisateur>(
        future: userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.cours!.isEmpty) {
            return const Center(child: Text("Aucun cours trouvé."));
          }

          final user = snapshot.data!;
          final coursList = user.cours!;

          // filtrage simple par recherche
          final filteredCoursList = coursList.where((cours) {
            return cours.jour.toLowerCase().contains(searchQuery.toLowerCase()) ||
                cours.heure.contains(searchQuery) ||
                cours.categorieAge.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Center(
                  child: Text(
                    user.dojos![0].nom,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  decoration: InputDecoration(
                    hintText: "Rechercher un cours",
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    itemCount: filteredCoursList.length,
                    itemBuilder: (context, index) {
                      final cours = filteredCoursList[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding:
                        const EdgeInsets.symmetric(vertical: 1, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: DefaultTextStyle(
                                style: const TextStyle(color: Colors.black),
                                child: CoursItem(cours: cours, userID: user.id),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===== Helper Method for Drawer Items =====
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
