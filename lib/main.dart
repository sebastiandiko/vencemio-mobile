import 'package:flutter/material.dart';
import 'package:vencemio/src/home.dart';
import 'package:vencemio/src/map_page.dart';
import 'package:vencemio/src/notification_config.dart';
import 'package:vencemio/src/user_preferences.dart';
import 'src/login.dart';
import 'package:firebase_core/firebase_core.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // inicializar Firebase
  await Firebase.initializeApp(); // Inicializa Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Ocultar la bandera de debug
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const LoginPage(),
    );
  }
}
 