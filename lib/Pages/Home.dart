import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../db_helper.dart';
import 'Login.dart';
import 'Courses.dart';
import 'TeacherAdherentsList.dart';
import '../theme/app_colors.dart';

class HomePage extends StatefulWidget {
  final int userId;
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? utilisateur;
  late int userId;
  int _currentIndex = 0;
  final List<int> _navigationStack = [];

  // ==============================
  // 🔥 NOUVELLES DONNÉES STATS
  // ==============================
  Map<String, dynamic>? statsGlobal;

  // Anciennes sections conservées
  List<Map<String, dynamic>> presenceParDojo = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    _navigationStack.add(_currentIndex);

    _chargerUtilisateur();
    _chargerDonneesDashboard();
  }

  Future<void> _chargerUtilisateur() async {
    final user = await DBHelper.getUtilisateurLocal();
    setState(() {
      utilisateur = user;
    });
  }

  Future<void> _chargerDonneesDashboard() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 🔥 NOUVEL APPEL STATS
      final global = await DBHelper.getStatsProfGlobal(userId);

      final presenceDojo = await DBHelper.getPresenceParDojo();

      setState(() {
        statsGlobal = global;

        presenceParDojo = presenceDojo;

        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    Fluttertoast.showToast(
      msg: "Déconnexion",
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    await DBHelper.clearUser();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage(title: 'Login')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _homeContent(),
      CoursesListPage(userId: userId),
      TeacherAdherentsListPage(userId: userId),
      Center(child: Text("Paramètres", style: TextStyle(fontSize: 22))),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_navigationStack.length > 1) {
          setState(() {
            _navigationStack.removeLast();
            _currentIndex = _navigationStack.last;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: pages[_currentIndex],
        bottomNavigationBar: _bottomNav(),
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (index) {
          if (index == 3) {
            if (_navigationStack.length > 1) {
              setState(() {
                _navigationStack.removeLast();
                _currentIndex = _navigationStack.last;
              });
            }
          } else if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
              _navigationStack.add(index);
            });
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.class_), label: "Cours"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Adhérents"),
          BottomNavigationBarItem(icon: Icon(Icons.arrow_back), label: "Retour"),
        ],
      ),
    );
  }

  Widget _homeContent() {
    return RefreshIndicator(
      onRefresh: _chargerDonneesDashboard,
      child: Stack(
        children: [
          Container(
            height: 220,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/background-flam.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(height: 220, color: Colors.black.withOpacity(0.4)),

          Column(
            children: [
              const SizedBox(height: 40),

              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 30, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Bienvenue,", style: TextStyle(color: Colors.white)),
                                Text(
                                  "${utilisateur?['nom'] ?? ''} ${utilisateur?['prenom'] ?? ''}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: logout,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30)),
                  ),

                  child: isLoading
                      ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : Padding(
                    padding: const EdgeInsets.all(20),

                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Center(
                            child: Image.asset("images/logo-flam.webp", width: 150),
                          ),

                          // ==============================
                          // 🔥 SECTION STATS ADAPTÉE
                          // ==============================
                          _buildStatsGlobalSection(),

                          const SizedBox(height: 30),

                          Row(
                            children: [
                              Expanded(
                                child: _styledTileButton(
                                  label: "Mes cours",
                                  icon: Icons.class_,
                                  onTap: () {
                                    setState(() {
                                      _currentIndex = 1;
                                      _navigationStack.add(1);
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(width: 16),

                              Expanded(
                                child: _styledTileButton(
                                  label: "Mes adhérents",
                                  icon: Icons.group,
                                  onTap: () {
                                    setState(() {
                                      _currentIndex = 2;
                                      _navigationStack.add(2);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),


                          const SizedBox(height: 30),

                          _buildPresenceParDojoSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🔥 NOUVEL AFFICHAGE STATS API
  // ==========================================================
  Widget _buildStatsGlobalSection() {
    if (statsGlobal == null || statsGlobal!['tauxGlobal'] == null) {
      return const Text("Aucune donnée de présence");
    }

    final g = statsGlobal!['tauxGlobal'];

    final actuelle = g['semaineActuelle'];
    final precedente = g['semainePrecedente'];
    final evolution = g['evolution'];

    Color evoColor = evolution >= 0 ? Colors.green : Colors.red;
    String evoText = evolution >= 0 ? "+$evolution%" : "$evolution%";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Statistiques Présence",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          Text("Semaine en cours"),
          LinearProgressIndicator(
            value: actuelle['pourcentage'] / 100,
            color: AppColors.primary,
          ),

          Text(
            "${actuelle['presences']} / ${actuelle['total']}  → ${actuelle['pourcentage']}%",
          ),

          const SizedBox(height: 16),

          Text("Semaine précédente"),
          LinearProgressIndicator(
            value: precedente['pourcentage'] / 100,
            color: Colors.grey,
          ),

          Text(
            "${precedente['presences']} / ${precedente['total']}  → ${precedente['pourcentage']}%",
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Text("Évolution : "),
              Text(
                evoText,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: evoColor),
              )
            ],
          )
        ],
      ),
    );
  }



  Widget _buildPresenceParDojoSection() {
    if (presenceParDojo.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Présence tranches d'âges",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: presenceParDojo.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final dojo = presenceParDojo[index];
            final dojoName = dojo['dojoName'] ?? '';
            final categories = dojo['categories'] as List? ?? [];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dojoName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    separatorBuilder: (context, idx) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final cat = categories[idx];
                      final categorieAge = cat['categorie_age'] ?? '';
                      final pourcentage = cat['pourcentage'] ?? 0;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            categorieAge,
                            style: const TextStyle(fontSize: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "$pourcentage%",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _styledTileButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return TextButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(const Color(0xFFD8BF6C)),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 18, horizontal: 4)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
        elevation: MaterialStateProperty.all(4),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}