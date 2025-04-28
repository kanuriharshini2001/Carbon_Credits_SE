import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:android_uber/auth/sigin_page.dart';
import 'package:android_uber/pages/log_commute_page.dart'; // ⬅️ Import this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "removed it as we made git public",
        authDomain: "inempolyeecredit.firebaseapp.com",
        projectId: "inempolyeecredit",
        storageBucket: "inempolyeecredit.firebasestorage.app",
        messagingSenderId: "170519962252",
        appId: "1:170519962252:web:fa9db38fccaab1491851a9",
        measurementId: "G-MP46GCJWYV",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Users App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SignInPage(),
      routes: {
        '/logCommute': (context) => const LogCommutePage(), // ✅ ADD THIS
      },
    );
  }
}

