import 'package:flutter/material.dart';
import 'EmployerDashboardPage.dart';
import 'RedemptionRequestsPage.dart'; // Add this import

class EmployerHomePage extends StatefulWidget {
  const EmployerHomePage({super.key});

  @override
  State<EmployerHomePage> createState() => _EmployerHomePageState();
}

class _EmployerHomePageState extends State<EmployerHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    EmployerDashboardPage(),         // Tab 0: Employees & their credits
    RedemptionRequestsPage(),        // Tab 1: Admin handles pending redemptions
    Center(child: Text("Profile Page (Coming Soon)", style: TextStyle(fontSize: 18))),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employer Portal"),
        backgroundColor: Colors.purple,
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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
