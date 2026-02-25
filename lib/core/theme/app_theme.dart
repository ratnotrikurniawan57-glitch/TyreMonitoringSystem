import 'package:flutter/material.dart';

class AppTheme {
  static const Color waGreen = Color(0xFF075E54);
  static const Color pastelBg = Color(0xFFF0F4F8);
  static const Color softBlue = Color(0xFFBDE0FE);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: pastelBg,

      // Mengubah gaya kotak input (NRP & Password)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), // Bikin melengkung
          borderSide: BorderSide.none,
        ),
        prefixIconColor: waGreen,
      ),

      // Mengubah gaya tombol LOGIN
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: softBlue,
          foregroundColor: waGreen,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
      ),
    );
  }
}
