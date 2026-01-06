import 'package:contact_app/provider/contact_provider.dart';
import 'package:contact_app/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1E88E5);
    const Color lightGreyBg = Color(0xFFEFEFEF);
    const Color cardWhite = Colors.white;
    const Color textBlack = Colors.black;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContactProvider()),
      ],
      child: MaterialApp(
        title: 'Contacts App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryBlue,
            primary: primaryBlue,
            secondary: primaryBlue,
            surface: cardWhite,
            background: lightGreyBg,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: lightGreyBg,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
                color: textBlack,
                fontSize: 20,
                fontWeight: FontWeight.bold
            ),
            iconTheme: IconThemeData(color: textBlack),
            actionsIconTheme: IconThemeData(color: primaryBlue),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: cardWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryBlue, width: 2),
            ),
            labelStyle: TextStyle(color: Colors.grey.shade600),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
