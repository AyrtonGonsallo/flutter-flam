import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flam/Pages/Courses.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../Constants/ApiConstants.dart';
import '../Models/Utilisateur.dart';
import 'Home.dart';

class TeacherAdherentsListPage extends StatefulWidget {
  final int userId;

  const TeacherAdherentsListPage({
    super.key,
    required this.userId,
  });

  @override
  _TeacherAdherentsListPageState createState() =>
      _TeacherAdherentsListPageState();
}

class _TeacherAdherentsListPageState extends State<TeacherAdherentsListPage> {
  late Future<List<Utilisateur>> adherentsFuture;
  late String apiUrl;
  late int userId;
  String searchQuery = '';
  bool sortAsc = true;
  int sortColumnIndex = 0;

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    apiUrl = ApiConstants.baseUrl;
    adherentsFuture = fetchAdherents(apiUrl, widget.userId);
  }

  Future<List<Utilisateur>> fetchAdherents(String apiUrl, int userId) async {
    final response = await http.get(
      Uri.parse("$apiUrl/api/adherents/adherents_by_teacher/$userId"),
    );
    if (response.body.isNotEmpty) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Utilisateur.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ===== AppBar =====
      appBar: AppBar(
        title: const Text(
          "Mes adhérents",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: SizedBox(),
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
              // Header
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

              // Menu Items
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ===== Body =====
      body: FutureBuilder<List<Utilisateur>>(
        future: adherentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun adhérent trouvé.'));
          }

          final adherents = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ========= SEARCH FIELD =========
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un adhérent',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10,
                    ),
                    isDense: true,
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

                // ========= TABLE (header fixe + body scroll) =========
                Expanded(
                  child: Builder(
                    builder: (context) {
                      List<Utilisateur> filteredList = adherents
                          .where((item) =>
                      item.nom.toLowerCase().contains(searchQuery) ||
                          item.prenom.toLowerCase().contains(searchQuery))
                          .toList();

                      return Container(
                        margin: const EdgeInsets.all(8),
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
                            // ------- HEADER FIXE --------
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
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
                                  Expanded(
                                      child: Text('Dojo',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),

                            // ------- BODY SCROLLABLE --------
                            Expanded(
                              child: ListView.builder(
                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  final adherent = filteredList[index];

                                  return InkWell(
                                    onTap: () {},
                                    onLongPress: () => showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        var formattedDate = "";
                                        if (adherent.date_inscription != null) {
                                          final date = DateTime.parse(
                                              adherent.date_inscription!);
                                          formattedDate =
                                              DateFormat('dd/MM/yyyy')
                                                  .format(date);
                                        }

                                        return AlertDialog(
                                          title: const Text(
                                              "Détails de l’adhérent"),
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
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 8),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(child: Text(adherent.nom)),
                                          Expanded(child: Text(adherent.prenom)),
                                          Expanded(
                                              child: Text(adherent.dojos?[0].nom ?? "")),
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
