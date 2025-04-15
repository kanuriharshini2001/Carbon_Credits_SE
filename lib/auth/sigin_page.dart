import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:android_uber/auth/signup_page.dart';
import 'package:android_uber/pages/employee_home_page.dart';
import 'package:android_uber/pages/employerHomepage.dart';
import 'package:android_uber/methods/global.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  loginUserNow() async {
    if (!emailController.text.contains("@")) {
      associateMethods.showsnacksBarMsg("Email is not valid", context);
      return;
    }
    if (passwordController.text.trim().length < 5) {
      associateMethods.showsnacksBarMsg("Password must be at least 5 characters", context);
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final User? currentUser = userCredential.user;

      if (currentUser != null) {
        final userRef = FirebaseDatabase.instance.ref("users/${currentUser.uid}");
        final snapshot = await userRef.get();

        if (!snapshot.exists) {
          associateMethods.showsnacksBarMsg("User not found in Realtime Database", context);
          await FirebaseAuth.instance.signOut();
          return;
        }

        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final String role = data["role"] ?? "unknown";
        final bool approved = data["approved"] == true;

        if (!approved) {
          associateMethods.showsnacksBarMsg("Your account is pending admin approval.", context);
          await FirebaseAuth.instance.signOut();
          return;
        }

        associateMethods.showsnacksBarMsg("Login successful!", context);

        if (role == "employee") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeHomePage()),
          );
        } else if (role == "employer") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EmployerHomePage()),
          );
        } else {
          associateMethods.showsnacksBarMsg("Unknown role assigned.", context);
        }
      }
    } on FirebaseAuthException catch (e) {
      associateMethods.showsnacksBarMsg("Login failed: ${e.message}", context);
    } catch (e) {
      associateMethods.showsnacksBarMsg("Something went wrong. Try again.", context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const SizedBox(height: 120),
              Image.asset(
                "assets/sigin.webp",
                width: MediaQuery.of(context).size.width * 0.65,
              ),
              const SizedBox(height: 10),
              const Text(
                "Login to Your Account",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: "Email"),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Password"),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: loginUserNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                      ),
                      child: const Text("Login", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupPage()),
                  );
                },
                child: const Text("Don't have an account? Sign up here", style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
