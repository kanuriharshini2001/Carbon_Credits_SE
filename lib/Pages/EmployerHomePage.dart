import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:android_uber/auth/sigin_page.dart';

import 'EmployerDashboardPage.dart';
import 'RedemptionRequestsPage.dart';
import 'EmployerMarketplace.dart';

class EmployerHomePage extends StatefulWidget {
  const EmployerHomePage({super.key});

  @override
  State<EmployerHomePage> createState() => _EmployerHomePageState();
}

class _EmployerHomePageState extends State<EmployerHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    EmployerDashboardPage(),
    RedemptionRequestsPage(),
    EmployerMarketplacePage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employer Portal"),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Employees',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.redeem),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Marketplace',
          ),
        ],
      ),
    );
  }
}
