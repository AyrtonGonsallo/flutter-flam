import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flam/Pages/Courses.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../Constants/ApiConstants.dart';
import '../Models/Appel.dart';
import '../Models/Cours.dart';
import '../Models/AdherentAvecAppel.dart';
import 'Home.dart';
import 'ScannerPage.dart';
import 'TeacherAdherentsList.dart';

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
  }

  void loadData() {
    userId = widget.userId;
    courseId = widget.courseId;
    apiUrl = ApiConstants.baseUrl;
    setState(() {
      combinedFuture = Future.wait([
        fetchAdherents(courseId),
        fetchCours(courseId),
      ]);
    });
  }
// 🔹 Recherche avec debounce
  void _onSearchChanged(String query) {
    print("-> _onSearchChanged appelé avec query='$query'");

    if (_debounce?.isActive ?? false) {
      print("   -> debounce annulé");
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      print("   -> timer fini, longueur query = ${query.length}");

      if (query.length >= 3) {
        print("   -> query >= 3 caractères, appel _fetchAdherents");
        _fetchAdherents(query);
      } else {
        print("   -> query < 3 caractères, reset _results et _isLoading");
        if (!mounted) return;
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _fetchAdherents(String query) async {
    print("-> _fetchAdherents appelé avec query='$query'");
    if (!mounted) {
      print("   -> widget démonté, return");
      return;
    }

    setState(() {
      _isLoading = true;
      print("   -> _isLoading = $_isLoading");
    });

    try {
      final response = await http.get(
        Uri.parse("$apiUrl/api/adherents/search_adherents?q=$query"),
      );

      print("   -> réponse reçue statusCode=${response.statusCode}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("   -> data reçue: $data");

        setState(() {
          _results = data;
          print("   -> _results mis à jour: $_results");
        });
      } else {
        print("   -> statusCode != 200, reset _results");
        setState(() => _results = []);
      }
    } catch (e) {
      print("   -> erreur catch: $e");
      if (!mounted) return;
      setState(() => _results = []);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        print("   -> finally: _isLoading = $_isLoading, _results.isEmpty = ${_results.isEmpty}");
      });
    }
  }






  Future<List<AdherentAvecAppel>> fetchAdherents(int courseId) async {
    final response = await http.get(
      Uri.parse(
        "$apiUrl/api/adherents/adherents_by_cours_with_appels/$courseId",
      ),
    );
    if (response.body.length > 0) {
      final data = jsonDecode(response.body) as List;
      print(data);
      return data.map((e) => AdherentAvecAppel.fromJson(e)).toList();
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

  Future<void> updateorCreateAppelStatus(
    int adherentId,
    int coursId,
    bool status,
  ) async {
    try {
      // Exemple, adapte selon ton API
      final response = await http.post(
        Uri.parse('$apiUrl/api/adherents/upsert_appel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status,
          'adherentId': adherentId,
          'coursId': coursId,
        }),
      );
      print("mise a jour appel");
      print(response.body);
      if (response.statusCode != 200) {
        throw Exception('Erreur API');
      }
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




  // 👉 La pop-up (dialogue)
  void _showPonctuelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        List<dynamic> dialogResults = [];
        bool dialogLoading = false;
        TextEditingController dialogController = TextEditingController();
        Timer? dialogDebounce;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Fonction de recherche locale pour le dialog
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

            return AlertDialog(
              title: const Text('Ajouter une présence ponctuelle'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dialogController,
                      decoration: const InputDecoration(
                        labelText: 'Rechercher un adhérent',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: searchAdherents,
                    ),
                    const SizedBox(height: 10),
                    dialogLoading
                        ? const Center(child: CircularProgressIndicator())
                        : dialogResults.isEmpty
                        ? const Text('Aucun résultat')
                        : Expanded(
                      child: ListView.builder(
                        itemCount: dialogResults.length,
                        itemBuilder: (context, index) {
                          final adherent = dialogResults[index];
                          return ListTile(
                            title: Text(
                                '${adherent['nom']} ${adherent['prenom'] ?? ''}'),
                            onTap: () async {
                              // Appel ponctuel
                              final response = await http.post(
                                Uri.parse(
                                    "$apiUrl/api/adherents/add_appel_ponctuel"),
                                headers: {
                                  'Content-Type': 'application/json'
                                },
                                body: json.encode({
                                  'status': true,
                                  'coursId': courseId,
                                  'adhrerent_id': adherent['id'],
                                }),
                              );

                              if (response.statusCode == 201) {
                                // Succès
                                if (!mounted) return;
                                Navigator.of(context).pop(); // ferme le dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Présence ponctuelle ajoutée ✅'),
                                      backgroundColor: Colors.green,
                                  ),
                                );
                              } else if (response.statusCode == 409) {
                                // Appel déjà existant
                                if (!mounted) return;
                                Navigator.of(context).pop(); // ferme le dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      json.decode(response.body)['message'] ??
                                          'Appel déjà enregistré ❌',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [

                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Appel"),
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

          final adherents_avec_appels =
              snapshot.data![0] as List<AdherentAvecAppel>;
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
                TextButton(
                  onPressed: () async {

                    final refresh = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ScannerPage(coursId: courseId)),
                    );

                    if (refresh == true) {
                      // 🔁 Recharger les données
                      loadData(); // ta fonction pour mettre à jour l’affichage
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFFD8BF6C), // Couleur de fond du bouton
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
                    'Scanner les QR codes',
                    style: TextStyle(
                      color: Colors.white, // ou n'importe quelle couleur de lien
                    ),
                  ),
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
                        List<AdherentAvecAppel> filteredList =
                            adherents_avec_appels.where((item) {
                              final nom = item.adherent.nom.toLowerCase();
                              final prenom = item.adherent.prenom.toLowerCase();
                              return nom.contains(searchQuery) ||
                                  prenom.contains(searchQuery);
                            }).toList();

                        filteredList.sort((a, b) {
                          final aVal = sortColumnIndex == 0
                              ? a.adherent.nom
                              : a.adherent.prenom;
                          final bVal = sortColumnIndex == 0
                              ? b.adherent.nom
                              : b.adherent.prenom;
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
                              DataColumn(
                                label: Text(
                                  'Action',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                            rows: filteredList.map((adherent_avec_appel) {
                              return DataRow(
                                cells: <DataCell>[
                                  DataCell(
                                    Text(adherent_avec_appel.adherent.nom),
                                  ),
                                  DataCell(
                                    Text(adherent_avec_appel.adherent.prenom),
                                  ),
                                  DataCell(
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            adherent_avec_appel.appel != null &&
                                                    adherent_avec_appel
                                                        .appel!
                                                        .status
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color:
                                                adherent_avec_appel.appel !=
                                                        null &&
                                                    adherent_avec_appel
                                                        .appel!
                                                        .status
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          onPressed: () async {
                                            final ancienStatus =
                                                adherent_avec_appel
                                                    .appel
                                                    ?.status ??
                                                false;
                                            final bool nouveauStatus =
                                                !ancienStatus;

                                            setState(() {
                                              if (adherent_avec_appel.appel ==
                                                  null) {
                                                // Si pas encore d'appel → création locale temporaire
                                                adherent_avec_appel
                                                    .appel = Appel(
                                                  id: 0, // ou null si non requis par ton modèle
                                                  status: nouveauStatus,
                                                  adherentId:
                                                      adherent_avec_appel
                                                          .adherent
                                                          .id,
                                                  coursId: cours[0].id,
                                                  date: DateTime.now()
                                                      .toIso8601String(), // si utile
                                                );
                                              } else {
                                                // Toggle si appel déjà existant
                                                adherent_avec_appel
                                                        .appel!
                                                        .status =
                                                    nouveauStatus;
                                              }
                                            });

                                            try {
                                              // Appel API qui gère création ou update selon existence
                                              await updateorCreateAppelStatus(
                                                adherent_avec_appel.adherent.id,
                                                cours[0].id,
                                                nouveauStatus,
                                              );
                                            } catch (e) {
                                              // Revert en cas d'erreur
                                              setState(() {
                                                adherent_avec_appel
                                                        .appel
                                                        ?.status =
                                                    ancienStatus;
                                              });

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Erreur lors de la mise à jour',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                onPressed: _showPonctuelDialog,
                style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFD8BF6C),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                'Présence ponctuelle',
                style: TextStyle(color: Colors.white),
                ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
