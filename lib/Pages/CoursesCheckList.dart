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
import '../Models/AdherentAvecAppel.dart';
import 'Home.dart';
import 'ScannerPage.dart';
import 'TeacherAdherentsList.dart';

class CoursDate {
  final String date;

  CoursDate({required this.date});

  factory CoursDate.fromJson(Map<String, dynamic> json) {
    return CoursDate(date: json['date']);
  }
}

class CourseCheckListPage extends StatefulWidget {
  final int userId;
  final int courseId;

  const CourseCheckListPage({
    super.key,
    required this.userId,
    required this.courseId,
  });

  @override
  _CourseCheckListPageState createState() => _CourseCheckListPageState();
}

class _CourseCheckListPageState extends State<CourseCheckListPage> {
  late Future<List<dynamic>> combinedFuture = Future.value([]);
  late String apiUrl;
  late int userId;
  late int courseId;
  late Future<CoursDate> coursDateFuture;
  String searchQuery = '';
  bool sortAsc = true;
  int sortColumnIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _results = [];
  bool _isLoading = false;

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
    coursDateFuture = fetchCoursDate(widget.courseId);
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
  void loadData() {
    setState(() {
      combinedFuture = Future.wait([
        fetchAdherents(courseId),
        fetchCours(courseId),
      ]);
    });
  }

  // Recherche avec debounce
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.length >= 3) {
        _fetchAdherents(query);
      } else {
        if (!mounted) return;
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _fetchAdherents(String query) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/adherents/search_adherents?q=$query"),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _results = data;
        });
      } else {
        setState(() => _results = []);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _results = []);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<List<AdherentAvecAppel>> fetchAdherents(int courseId) async {
    final response = await http.get(
      Uri.parse(
        "$apiUrl/api/adherents/adherents_by_cours_with_appels/$courseId",
      ),
    );
    if (response.body.isNotEmpty) {
      final data = jsonDecode(response.body) as List;
      //print(data);
      return data.map((e) => AdherentAvecAppel.fromJson(e)).toList();
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

  Future<void> updateorCreateAppelStatus(
      int adherentId,
      int coursId,
      bool status,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/adherents/upsert_appel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          'adherentId': adherentId,
          'coursId': coursId,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Erreur API');
      }
    } catch (e) {
      throw Exception("Erreur inattendue : $e");
    }
  }

  void _showPonctuelDialog() {
    final dialogController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    List<dynamic> dialogResults = [];
    bool dialogLoading = false;
    Timer? dialogDebounce;

    showDialog(
      context: context,
      barrierDismissible: false, // empêche fermer en cliquant dehors
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void searchAdherents(String query) {
              if (dialogDebounce?.isActive ?? false) dialogDebounce!.cancel();

              dialogDebounce = Timer(const Duration(milliseconds: 400), () async {
                if (query.length < 3) {
                  setStateDialog(() {
                    dialogResults = [];
                    dialogLoading = false;
                  });
                  return;
                }

                setStateDialog(() => dialogLoading = true);

                try {
                  final response = await http.get(
                    Uri.parse("$apiUrl/api/adherents/search_adherents?q=$query"),
                  );

                  if (response.statusCode == 200) {
                    final data = json.decode(response.body);
                    setStateDialog(() => dialogResults = data);
                  } else {
                    setStateDialog(() => dialogResults = []);
                  }
                } catch (e) {
                  setStateDialog(() => dialogResults = []);
                } finally {
                  setStateDialog(() => dialogLoading = false);
                }
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// TITRE
                    Text(
                      'Ajouter une présence ponctuelle',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 20),

                    /// CHAMP DE RECHERCHE
                    Form(
                      key: formKey,
                      child: TextFormField(
                        controller: dialogController,
                        decoration: InputDecoration(
                          labelText: 'Rechercher un adhérent',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          labelStyle: TextStyle(color: Colors.black87),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Color(0xFFD8BF6C), width: 1),
                          ),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: searchAdherents,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Veuillez entrer un nom';
                          return null;
                        },
                      ),
                    ),

                    SizedBox(height: 20),

                    /// LISTE DES RÉSULTATS
                    dialogLoading
                        ? Center(child: CircularProgressIndicator())
                        : dialogResults.isEmpty
                        ? Text('Aucun résultat')
                        : Container(
                      height: 200, // ajuste selon besoin
                      child: ListView.builder(
                        itemCount: dialogResults.length,
                        itemBuilder: (context, index) {
                          final adherent = dialogResults[index];
                          return ListTile(
                            title: Text('${adherent['nom']} ${adherent['prenom'] ?? ''}'),
                            onTap: () async {
                              final response = await http.post(
                                Uri.parse("$apiUrl/api/adherents/add_appel_ponctuel"),
                                headers: {'Content-Type': 'application/json'},
                                body: json.encode({
                                  'status': true,
                                  'coursId': courseId,
                                  'adhrerent_id': adherent['id'],
                                }),
                              );

                              Navigator.of(context).pop();

                              if (response.statusCode == 201) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Présence ponctuelle ajoutée ✅'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                loadData();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(json.decode(response.body)['message'] ?? 'Appel déjà enregistré ❌'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 24),

                    /// BOUTON FERMER
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFD8BF6C),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Fermer',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // fond blanc pour le body
      appBar: AppBar(
        title: const Text("Appel"),
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
            print(snapshot);
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun adhérent trouvé.'));
          }

          final adherents_avec_appels = snapshot.data![0] as List<AdherentAvecAppel>;
          final cours = snapshot.data![1] as List<Cours>;
          final now = DateTime.now();
          final formattedDate = formatDate(now, [dd, '/', mm, '/', yyyy]);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: FutureBuilder<CoursDate>(
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
                        "${cours[0].dojo!.nom} - ${cours[0].jour} - ${cours[0].heure.substring(0, 5)} - ${humanDate(date)}",
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
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // ===== Search Field =====
                TextField(
                  controller: _searchController,
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

                // ===== Boutons Scanner et Présence =====
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final refresh = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ScannerPage(coursId: courseId),
                            ),
                          );
                          if (refresh == true) loadData();
                        },
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                        label: const Text('Scanner', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD8BF6C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showPonctuelDialog,
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        label: const Text('Ponctuel', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD8BF6C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ===== Liste adhérents avec header fixe =====
                Expanded(
                  child: Builder(
                    builder: (context) {
                      List<AdherentAvecAppel> filteredList =
                      adherents_avec_appels.where((item) {
                        final nom = item.adherent.nom.toLowerCase();
                        final prenom = item.adherent.prenom.toLowerCase();
                        return nom.contains(searchQuery) ||
                            prenom.contains(searchQuery);
                      }).toList();

                      filteredList.sort((a, b) {
                        final aVal =
                        sortColumnIndex == 0 ? a.adherent.nom : a.adherent.prenom;
                        final bVal =
                        sortColumnIndex == 0 ? b.adherent.nom : b.adherent.prenom;
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
                            // Header fixe
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
                                  Expanded(
                                      child: Text('Présence',
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
                                      if (adherent.appel?.date != null) {
                                        final date =
                                        DateTime.parse(adherent.appel!.date!);
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
                                                Text("Nom : ${adherent.adherent.nom}"),
                                                Text("Prénom : ${adherent.adherent.prenom}"),
                                                Text(
                                                    "Catégorie d'âge : ${adherent.adherent.categorie_age}"),
                                                Text(
                                                    "Présence : ${adherent.appel?.status == true ? 'Oui' : 'Non'}"),
                                                Text("Date : $formattedDate"),
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
                                          Expanded(child: Text(adherent.adherent.nom)),
                                          Expanded(child: Text(adherent.adherent.prenom)),
                                          Expanded(
                                            child: IconButton(
                                              icon: Icon(
                                                adherent.appel != null &&
                                                    adherent.appel!.status
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                color: adherent.appel != null &&
                                                    adherent.appel!.status
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                              onPressed: () async {
                                                final ancienStatus =
                                                    adherent.appel?.status ?? false;
                                                final nouveauStatus = !ancienStatus;

                                                setState(() {
                                                  if (adherent.appel == null) {
                                                    adherent.appel = Appel(
                                                      id: 0,
                                                      status: nouveauStatus,
                                                      adherentId: adherent.adherent.id,
                                                      coursId: cours[0].id,
                                                      date: DateTime.now()
                                                          .toIso8601String(),
                                                    );
                                                  } else {
                                                    adherent.appel!.status =
                                                        nouveauStatus;
                                                  }
                                                });

                                                try {
                                                  await updateorCreateAppelStatus(
                                                    adherent.adherent.id,
                                                    cours[0].id,
                                                    nouveauStatus,
                                                  );
                                                } catch (_) {
                                                  setState(() {
                                                    adherent.appel!.status = ancienStatus;
                                                  });
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Erreur lors de la mise à jour'),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
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
