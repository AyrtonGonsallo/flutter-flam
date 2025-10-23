import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../Constants/ApiConstants.dart';
import '../db_helper.dart';
import 'Login.dart';
import 'Courses.dart';
import 'TeacherAdherentsList.dart';

class HomePage extends StatefulWidget {
  final int userId;
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? utilisateur;
  late int userId;
  late String apiUrl;

  @override
  void initState() {
    super.initState(); // Appelé une seule fois au début
    _chargerUtilisateur(); // Appelle ta fonction async ici
    userId = widget.userId;
    apiUrl = ApiConstants.baseUrl;
  }

  Future<void> _chargerUtilisateur() async {
    final user = await DBHelper.getUtilisateurLocal();
    setState(() {
      utilisateur = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    Future<void> logout() async {
      Fluttertoast.showToast(
        msg: "Deconnexion",
        toastLength: Toast.LENGTH_SHORT, // ou Toast.LENGTH_LONG
        gravity: ToastGravity.BOTTOM, // ou TOP, CENTER
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      await DBHelper.clearUser();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginPage(title: 'Login')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Accueil'),
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
            child: IconButton(
              iconSize: 30,
              icon: const Icon(Icons.logout),
              onPressed: logout
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        //width: double.infinity,
        child: Column(
          children: [
            Container(
              color: Colors.red,
              margin: EdgeInsets.symmetric(vertical: 20,horizontal: 70),
              child: Image.asset("images/logo_f8f9ff.png"),
            ),
            Container(
              margin: EdgeInsets.all(0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Bienvenue, ${utilisateur?['nom']} ${utilisateur?['prenom']} !',
                    ),
                  ),

                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 50,horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
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
                    onPressed: ()=>{
                      Navigator.push(context,
                      MaterialPageRoute(builder: (_)=>CoursesListPage(userId: userId))
                      )
                    },
                    child: Text(
                      "Mes cours",
                      style: TextStyle(
                        color: Colors.white,
                        backgroundColor: Color(0xFFD8BF6C),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  TextButton(
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
                    onPressed: ()=>{
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_)=>TeacherAdherentsListPage(userId: userId))
                      )
                    },
                    child: Text(
                      "Mes adhérents",
                      style: TextStyle(
                        color: Colors.white,
                        backgroundColor: Color(0xFFD8BF6C),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
