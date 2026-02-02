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

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    _navigationStack.add(_currentIndex);
    _chargerUtilisateur();
  }

  Future<void> _chargerUtilisateur() async {
    final user = await DBHelper.getUtilisateurLocal();
    setState(() {
      utilisateur = user;
    });
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
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            onTap: (index) {
              if (index == 3) {
                // Flèche retour
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
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Accueil"),
              const BottomNavigationBarItem(icon: Icon(Icons.class_), label: "Cours"),
              const BottomNavigationBarItem(icon: Icon(Icons.group), label: "Adhérents"),
              BottomNavigationBarItem(icon: Icon(Icons.arrow_back), label: "Retour"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeContent() {
    return Stack(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Texte Bienvenue
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 30, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Bienvenue,", style: TextStyle(color: Colors.white, fontSize: 16)),
                            Text(
                              "${utilisateur?['nom'] ?? ''} ${utilisateur?['prenom'] ?? ''}",
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Bouton de déconnexion
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
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          child: Image.asset("images/logo-flam.webp", width: 150),
                        ),
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
                        Container(
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
                            children: const [
                              Text("Statistiques", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: 0.7,
                                backgroundColor: Color(0xFFE0E0E0),
                                color: Color(0xFFD8BF6C),
                              ),
                              SizedBox(height: 5),
                              Text("Cours complétés: 70%"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Container(
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
                            children: const [
                              Text("Prochains événements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              SizedBox(height: 10),
                              Text("Vous avez 3 cours programmés cette semaine.", style: TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _styledTileButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return TextButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(const Color(0xFFD8BF6C)),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 18, horizontal: 20)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
        elevation: MaterialStateProperty.all(4),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }
}
