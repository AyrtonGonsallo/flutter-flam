import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flam/Pages/Courses.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../Constants/ApiConstants.dart';
import '../Models/Appel.dart';
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
    if (response.body.length > 0) {
      final data = jsonDecode(response.body) as List;
      print(data);
      return data.map((e) => Utilisateur.fromJson(e)).toList();
    } else {
      final data = jsonDecode(response.body);
      print(data);
      return [];
    }
  }

  Future<List<Cours>> fetchCours(int courseId) async {
    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/dojo_cours/get_cours/$courseId"),
      );
      final data = jsonDecode(response.body);
      print(data);
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
      appBar: AppBar(
        title: Text("Adhérents"),
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

          final adherents_avec_appels = snapshot.data![0] as List<Utilisateur>;
          final cours = snapshot.data![1] as List<Cours>;
          final now = DateTime.now();

          final formattedDate = formatDate(now, [dd, '/', mm, '/', yyyy]);
          // ou autre format : DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(now);

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${cours[0].dojo!.nom} - ${cours[0].jour} - ${cours[0].heure.substring(0, 5)} - ${formattedDate}",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Rechercher un adhérent',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFFD8BF6C),
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                      print(searchQuery);
                    });
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Builder(
                      builder: (context) {
                        List<Utilisateur> filteredList = adherents_avec_appels
                            .where((item) {
                              final nom = item.nom.toLowerCase();
                              final prenom = item.prenom.toLowerCase();
                              return nom.contains(searchQuery) ||
                                  prenom.contains(searchQuery);
                            })
                            .toList();

                        filteredList.sort((a, b) {
                          final aVal = sortColumnIndex == 0 ? a.nom : a.prenom;
                          final bVal = sortColumnIndex == 0 ? b.nom : b.prenom;
                          return sortAsc
                              ? aVal.compareTo(bVal)
                              : bVal.compareTo(aVal);
                        });
                        return SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: DataTable(
                            headingRowColor: WidgetStateColor.resolveWith(
                              (states) => Color(0xFFD8BF6C),
                            ),
                            dataRowColor: WidgetStateColor.resolveWith(
                              (states) => Colors.grey.shade200,
                            ),
                            columnSpacing: 0,
                            sortColumnIndex: sortColumnIndex,
                            sortAscending: sortAsc,
                            columns: [
                              DataColumn(
                                label: Text(
                                  'Nom',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                                onSort: (columnIndex, ascending) {
                                  setState(() {
                                    sortColumnIndex = columnIndex;
                                    sortAsc = ascending;
                                  });
                                },
                              ),
                              DataColumn(
                                label: Text(
                                  'Prénom',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                                onSort: (columnIndex, ascending) {
                                  setState(() {
                                    sortColumnIndex = columnIndex;
                                    sortAsc = ascending;
                                  });
                                },
                              ),
                            ],
                            rows: filteredList.map((adherent) {
                              return DataRow(
                                onLongPress: () => {

                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      var formattedDate="";

                                      if(adherent.date_inscription != null){
                                        final date = DateTime.parse(adherent.date_inscription!); // "2024-10-04"
                                         formattedDate = DateFormat('dd/MM/yyyy').format(date);
                                      }

                                      return AlertDialog(
                                        title: Text("Détails de l’adhérent"),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("Nom : ${adherent.nom}"),
                                              Text("Prénom : ${adherent.prenom}"),
                                              Text("Catégorie d'âge : ${adherent.categorie_age}"),
                                              Text("Email : ${adherent.email}"),
                                              Text("Date d'inscription : $formattedDate"),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            child: Text("Fermer"),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                },
                                cells: <DataCell>[
                                  DataCell(Text(adherent.nom)),
                                  DataCell(Text(adherent.prenom)),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
