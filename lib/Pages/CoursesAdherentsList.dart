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
import '../Models/Utilisateur.dart';
import 'Home.dart';
import 'TeacherAdherentsList.dart';

class CourseAdherentsListPage extends StatefulWidget {
  final int userId;
  final int courseId;

  const CourseAdherentsListPage({
    super.key,
    required this.userId,
    required this.courseId,
  });

  @override
  _CourseAdherentsListPageState createState() =>
      _CourseAdherentsListPageState();
}

class _CourseAdherentsListPageState extends State<CourseAdherentsListPage> {
  late Future<List<dynamic>> combinedFuture = Future.value([]);
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
    combinedFuture = Future.wait([
      fetchAdherents(widget.courseId),
      fetchCours(widget.courseId),
    ]);
  }

  Future<List<Utilisateur>> fetchAdherents(int courseId) async {
    final response = await http.get(
      Uri.parse("$apiUrl/api/adherents/adherents_by_cours/$courseId"),
    );
    if (response.body.isNotEmpty) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Utilisateur.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  Future<List<Cours>> fetchCours(int courseId) async {
    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/dojo_cours/get_cours/$courseId"),
      );
      final data = jsonDecode(response.body);
      return [Cours.fromJson(data)];
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
        title: const Text("Adhérents"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1, color: Colors.grey),
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
                      icon: Icons.article,
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
                      icon: Icons.people,
                      text: "Mes adhérents",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TeacherAdherentsListPage(userId: userId),
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

      body: FutureBuilder<List<dynamic>>(
        future: combinedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun adhérent trouvé.'));
          }

          final adherentsList = snapshot.data![0] as List<Utilisateur>;
          final cours = snapshot.data![1] as List<Cours>;
          final now = DateTime.now();
          final formattedDate = formatDate(now, [dd, '/', mm, '/', yyyy]);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "${cours[0].dojo!.nom} - ${cours[0].jour} - ${cours[0].heure.substring(0, 5)} ",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      shadows: [
                        Shadow(
                          offset: Offset(1.5, 1.5),
                          blurRadius: 3,
                          color: Colors.grey.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ===== Search Field =====
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un adhérent',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    isDense: true,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 10),

                // ===== Table with fixed header =====
                Expanded(
                  child: Builder(
                    builder: (context) {
                      List<Utilisateur> filteredList = adherentsList
                          .where((item) =>
                      item.nom.toLowerCase().contains(searchQuery) ||
                          item.prenom.toLowerCase().contains(searchQuery))
                          .toList();

                      filteredList.sort((a, b) {
                        final aVal = sortColumnIndex == 0 ? a.nom : a.prenom;
                        final bVal = sortColumnIndex == 0 ? b.nom : b.prenom;
                        return sortAsc ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
                      });

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header fixed
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 20),
                              child: const Row(
                                children: [
                                  Expanded(
                                      child: Text('Nom',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      child: Text('Prénom',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),
                            // Body scrollable
                            Expanded(
                              child: ListView.builder(
                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  final adherent = filteredList[index];

                                  return InkWell(
                                    onLongPress: () {
                                      var formattedDate = "";
                                      if (adherent.date_inscription != null) {
                                        final date =
                                        DateTime.parse(adherent.date_inscription!);
                                        formattedDate =
                                            DateFormat('dd/MM/yyyy').format(date);
                                      }

                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title:
                                            const Text("Détails de l’adhérent"),
                                            content: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text("Nom : ${adherent.nom}"),
                                                Text("Prénom : ${adherent.prenom}"),
                                                Text(
                                                    "Catégorie d'âge : ${adherent.categorie_age}"),
                                                Text("Email : ${adherent.email}"),
                                                Text(
                                                    "Date d'inscription : $formattedDate"),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                child: const Text("Fermer"),
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 20),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              color: Colors.grey.shade200),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(child: Text(adherent.nom)),
                                          Expanded(child: Text(adherent.prenom)),
                                        ],
                                      ),
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
