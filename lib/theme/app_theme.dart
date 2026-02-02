import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.light,
    fontFamily: "Poppins",

    // Color Scheme GLOBAL
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.dark,
      surface: Colors.white,
      onSurface: AppColors.dark,
    ),

    // Textes globaux
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.dark,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: AppColors.dark,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    ),

    // AppBar global
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    // Icônes globales
    iconTheme: IconThemeData(
      color: AppColors.dark,
      size: 22,
    ),

    // Champs Input global (TextField)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Colors.grey),
    ),


    // ListTile global
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.dark,
      textColor: AppColors.dark,
    ),

    // Boutons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStatePropertyAll(AppColors.primary),
        padding: MaterialStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 25, vertical: 18),
        ),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        elevation: MaterialStatePropertyAll(6),
        shadowColor: MaterialStatePropertyAll(
          AppColors.primary.withOpacity(0.4),
        ),
      ),
    ),
  );
}
