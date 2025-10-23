import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import '../Constants/ApiConstants.dart';
import '../db_helper.dart';

import 'Home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late String apiUrl;

  @override
  void initState() {
    super.initState();
    apiUrl = ApiConstants.baseUrl;
  }

  void showPasswordResetDialog(BuildContext context) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mot de passe oublié', style: TextStyle(fontSize: 20)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un email';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Envoyer'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final email = emailController.text;

                  try {
                    final response = await http.post(
                      Uri.parse(
                        '$apiUrl/api/auth/recuperer_utilisateur',
                      ),
                      headers: {'Content-Type': 'application/json'},
                      body: '{"email": "$email"}',
                    );
                    final parsedResponse = jsonDecode(response.body);

                    if (response.statusCode == 200) {
                      Navigator.of(context).pop();
                      showDialog<String>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Text(
                            'Mot de passe oublié',
                            style: TextStyle(fontSize: 20),
                          ),
                          content: Text("${parsedResponse['message']}"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'OK'),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      ); // Ferme la popup
                    } else {
                      final parsedResponse = jsonDecode(response.body);
                      showDialog<String>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Text(
                            'Mot de passe oublié',
                            style: TextStyle(fontSize: 20),
                          ),
                          content: Text("${parsedResponse['message']}"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'OK'),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur réseau : $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    Future<void> login() async {
      final email = emailController.text.trim();
      final password = passwordController.text;
      if (email.isEmpty || password.isEmpty) {
        Fluttertoast.showToast(
          msg: "Données incompletes",
          toastLength: Toast.LENGTH_SHORT, // ou Toast.LENGTH_LONG
          gravity: ToastGravity.BOTTOM, // ou TOP, CENTER
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        print("Infos de connexion :$email $password");
        final url = Uri.parse(
          '$apiUrl/api/auth/login',
        );

        try {
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            Fluttertoast.showToast(
              msg:
                  "Connexion réussie :  ${data['nom']} ${data['prenom']} (${data['role']})",
              toastLength: Toast.LENGTH_SHORT, // ou Toast.LENGTH_LONG
              gravity: ToastGravity.BOTTOM, // ou TOP, CENTER
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0,
            );
            print("Connexion réussie !");
            print(data);
            await DBHelper.insertUser({
              'nom': data['nom'],
              'prenom': data['prenom'],
              'email': data['email'],
              'role': data['role'], // si tu veux vraiment stocker le hash
              'token': data['token'],
              'user_id': data['id'],

            });
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage(userId:data['id'])),
            );
          } else {
            final data = jsonDecode(response.body);
            Fluttertoast.showToast(
              msg: "Erreur : ${data['message']}",
              toastLength: Toast.LENGTH_SHORT, // ou Toast.LENGTH_LONG
              gravity: ToastGravity.BOTTOM, // ou TOP, CENTER
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0,
            );

            print("Erreur : ${response.statusCode}");
            print(data);
          }
        } catch (e) {
          print("Échec de la connexion: $e");
          Fluttertoast.showToast(
            msg: "Échec de la connexion: $e",
            toastLength: Toast.LENGTH_SHORT, // ou Toast.LENGTH_LONG
            gravity: ToastGravity.BOTTOM, // ou TOP, CENTER
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      }
    }

    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
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
              height: 300,
              margin: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Identifiant',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Mot de passe',
                      ),
                    ),
                  ),
                  Container(
                    child: Column(
                      children: [
                        TextButton(
                          onPressed: () => showPasswordResetDialog(context),
                          child: Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(
                              color: Color(0xFFD8BF6C), // ou n'importe quelle couleur de lien
                              decoration:
                                  TextDecoration.underline, // pour souligner
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: login,
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
                            'Se connecter',
                            style: TextStyle(
                              color: Colors.white,
                              backgroundColor: Color(0xFFD8BF6C),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
