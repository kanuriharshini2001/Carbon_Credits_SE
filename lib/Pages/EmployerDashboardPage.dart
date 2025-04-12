import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'employee_commute_details_page.dart'; // For showing individual commute logs

class EmployerDashboardPage extends StatefulWidget {
  const EmployerDashboardPage({super.key});

  @override
  State<EmployerDashboardPage> createState() => _EmployerDashboardPageState();
}

class _EmployerDashboardPageState extends State<EmployerDashboardPage> {
  final DatabaseReference usersRef = FirebaseDatabase.instance.ref("users");

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: usersRef.onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final Map<dynamic, dynamic> data =
        Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);

        final employees = data.entries.where((entry) {
          final user = Map<String, dynamic>.from(entry.value);
          return user['role'] == 'employee' && user['approved'] == true;
        }).toList();

        if (employees.isEmpty) {
          return const Center(child: Text("No approved employees found."));
        }

        return ListView.builder(
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final entry = employees[index];
            final userId = entry.key;
            final user = Map<String, dynamic>.from(entry.value);
            final name = user['name'] ?? 'Unnamed';
            final email = user['email'] ?? '';
            final credits = user['credits'] ?? 0;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.purple),
                title: Text(name),
                subtitle: Text("Email: $email\nCredits: $credits"),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeeCommuteDetailsPage(uid: userId, name: name),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
