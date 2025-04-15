import 'package:android_uber/auth/sigin_page.dart';
import 'package:android_uber/methods/global.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController userPhoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController homeAddressController = TextEditingController();
  final TextEditingController officeLocationController = TextEditingController();

  String selectedRole = 'employee'; // Default role

  validatesgnupForm() {
    if (userNameController.text.trim().length < 3) {
      associateMethods.showsnacksBarMsg("Name must be at least 3 characters", context);
    } else if (userPhoneController.text.trim().length < 7) {
      associateMethods.showsnacksBarMsg("Phone number must be at least 7 digits", context);
    } else if (!emailController.text.contains("@")) {
      associateMethods.showsnacksBarMsg("Email is not valid", context);
    } else if (passwordController.text.trim().length < 5) {
      associateMethods.showsnacksBarMsg("Password must be at least 5 characters", context);
    } else if (homeAddressController.text.trim().isEmpty || officeLocationController.text.trim().isEmpty) {
      associateMethods.showsnacksBarMsg("Please enter both home and office addresses", context);
    } else {
      signUserNow();
    }
  }

  signUserNow() async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        Map<String, dynamic> userDataMap = {
          "uid": firebaseUser.uid,
          "name": userNameController.text.trim(),
          "phone": userPhoneController.text.trim(),
          "email": emailController.text.trim(),
          "role": selectedRole,
          "homeAddress": homeAddressController.text.trim(),
          "officeLocation": officeLocationController.text.trim(),
<<<<<<< HEAD
          "approved": false,
=======
          "approved": true,
>>>>>>> master
          "credits": 0,
        };

        // ✅ Save to Firestore
        await FirebaseFirestore.instance
            .collection("users")
            .doc(firebaseUser.uid)
            .set(userDataMap);

        // ✅ Save to Realtime Database
        await FirebaseDatabase.instance
            .ref("users/${firebaseUser.uid}")
            .set(userDataMap);

        associateMethods.showsnacksBarMsg("Account created successfully!", context);

        // Sign out and navigate to login
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignInPage()));
      }
    } on FirebaseAuthException catch (e) {
      associateMethods.showsnacksBarMsg("Error: ${e.message}", context);
    } catch (e) {
      associateMethods.showsnacksBarMsg("Unexpected error occurred", context);
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
              const SizedBox(height: 80),
              Image.asset(
                "assets/signup.webp",
                width: MediaQuery.of(context).size.width * 0.65,
              ),
              const SizedBox(height: 10),
              const Text(
                "Register New Account",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    TextField(
                      controller: userNameController,
                      decoration: const InputDecoration(labelText: "Full Name"),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: userPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: "Phone Number"),
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: "Registering as"),
                      items: const [
                        DropdownMenuItem(value: 'employee', child: Text("Employee")),
                        DropdownMenuItem(value: 'employer', child: Text("Employer")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: homeAddressController,
                      decoration: const InputDecoration(labelText: "Home Address"),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: officeLocationController,
                      decoration: const InputDecoration(labelText: "Office Location"),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: validatesgnupForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                      ),
                      child: const Text("Sign Up", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInPage()),
                  );
                },
                child: const Text(
                  "Already have an Account? Login here",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
