import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'log_commute_page.dart';
import 'RedeemCreditsPage.dart';
import 'MonthlySummarypage.dart';
import 'package:android_uber/auth/sigin_page.dart';

class EmployeeHomePage extends StatefulWidget {
  const EmployeeHomePage({super.key});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  int _selectedIndex = 0;
  int totalCredits = 0;

  @override
  void initState() {
    super.initState();
    fetchTotalCredits();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void fetchTotalCredits() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref("users/${user.uid}/credits");
    final snapshot = await ref.get();

    setState(() {
      totalCredits = (snapshot.value as int?) ?? 0;
    });
  }

  Widget _dashboardTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Total Credits: $totalCredits",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildResponsiveActionButton(
              text: "Log Commute",
              color: Colors.blue,
              icon: Icons.add_location_alt,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LogCommutePage()),
                );
                fetchTotalCredits();
              },
            ),
            const SizedBox(height: 10),
            _buildResponsiveActionButton(
              text: "Redeem Credits",
              color: Colors.green,
              icon: Icons.card_giftcard,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RedeemCreditsPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildResponsiveActionButton(
              text: "Monthly Summary",
              color: Colors.blueGrey,
              icon: Icons.bar_chart,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MonthlySummaryPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveActionButton({
    required String text,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;

    // Responsive values
    double iconSize = screenWidth < 600 ? 18 : 24;
    double fontSize = screenWidth < 600 ? 13 : 16;
    double buttonHeight = screenWidth < 600 ? 44 : 54;
    double maxWidth = screenWidth < 600 ? 260 : 320;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          height: buttonHeight,
          child: ElevatedButton.icon(
            icon: Icon(icon, size: iconSize),
            label: Text(text, style: TextStyle(fontSize: fontSize)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 3,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }

  Widget _creditsLogTab() {
    final user = FirebaseAuth.instance.currentUser;
    final ref = FirebaseDatabase.instance.ref("commutes/${user?.uid}");

    return StreamBuilder(
      stream: ref.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: Text("No commute records found."));
        }

        final Map data = snapshot.data!.snapshot.value as Map;
        final entries = data.entries.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final commute = entries[index].value;
            final miles = commute["miles"];
            final credits = commute["credits"];
            final mode = commute["mode"];

            String formattedDate = "Unknown";
            final rawTimestamp = commute["timestamp"];
            if (rawTimestamp is int) {
              final dt = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
              formattedDate =
              "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
            }

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              child: ListTile(
                leading: const Icon(Icons.directions_bus, color: Colors.purple),
                title: Text("$mode - $credits credits"),
                subtitle: Text("Miles: ${miles?.toStringAsFixed(2) ?? "N/A"}"),
                trailing: Text(formattedDate),
              ),
            );
          },
        );
      },
    );
  }

  Widget _profileTab() {
    final user = FirebaseAuth.instance.currentUser;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text("Logged in as", style: TextStyle(fontSize: 16)),
            Text(
              user?.email ?? "No email",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),
            _buildResponsiveActionButton(
              text: "Logout",
              color: Colors.deepPurple,
              icon: Icons.logout,
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInPage()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [_dashboardTab(), _creditsLogTab(), _profileTab()];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FE),
      appBar: AppBar(
        title: const Text("Employee Portal"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 2,
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco),
            label: "Credits Log",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
