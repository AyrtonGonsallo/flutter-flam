import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'db_helper.dart';
import 'Pages/Login.dart';
import 'Pages/Home.dart';
import 'package:flam/theme/app_colors.dart';

/*
void main() {
  runApp(const MyApp());
}*/
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final user = await DBHelper.getUser();
  print(user);
  final userId = user != null ? user['user_id'] : 0;


  runApp(MyApp(isLoggedIn: user != null,userId:userId));
}


class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final int userId;
  const MyApp({super.key, required this.isLoggedIn, required this.userId});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Flam',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: isLoggedIn
          ? HomePage(userId: userId,)
          : const LoginPage(title: 'Login'),
    );
  }
}




