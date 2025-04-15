import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminApprovalPage extends StatefulWidget {
  const AdminApprovalPage({super.key});

  @override
  State<AdminApprovalPage> createState() => _AdminApprovalPageState();
}

class _AdminApprovalPageState extends State<AdminApprovalPage> {
  final DatabaseReference usersRef = FirebaseDatabase.instance.ref("users");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending User Approvals"),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: usersRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final Map<dynamic, dynamic> data =
          Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);

          final pendingUsers = data.entries.where((entry) {
            final user = Map<String, dynamic>.from(entry.value);
            return user['approved'] == false;
          }).toList();

          if (pendingUsers.isEmpty) {
            return const Center(child: Text("No users pending approval."));
          }

          return ListView.builder(
            itemCount: pendingUsers.length,
            itemBuilder: (context, index) {
              final entry = pendingUsers[index];
              final uid = entry.key;
              final user = Map<String, dynamic>.from(entry.value);
              final name = user['name'] ?? 'Unnamed';
              final email = user['email'] ?? '';
              final role = user['role'] ?? 'unknown';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.pending, color: Colors.orange),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Email: $email\nRole: $role"),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await usersRef.child(uid).update({"approved": true});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$name approved successfully")),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Approve"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
