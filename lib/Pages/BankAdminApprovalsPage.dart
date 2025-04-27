import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class BankAdminApprovalsPage extends StatefulWidget {
  const BankAdminApprovalsPage({super.key});

  @override
  State<BankAdminApprovalsPage> createState() => _BankAdminApprovalsPageState();
}

class _BankAdminApprovalsPageState extends State<BankAdminApprovalsPage> {
  final DatabaseReference usersRef = FirebaseDatabase.instance.ref("users");

  bool isBankAdmin = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    checkBankAdmin();
  }

  Future<void> checkBankAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref("users/${user.uid}/role");
    final snapshot = await ref.get();

    setState(() {
      isBankAdmin = snapshot.value == "bank";
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!isBankAdmin) {
      return const Scaffold(
        body: Center(child: Text("Access Denied. You must be a bank admin.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bank Approval Panel"),
        backgroundColor: Colors.grey,
      ),
      body: StreamBuilder(
        stream: usersRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No employer records found."));
          }

          final Map<dynamic, dynamic> data =
          Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);

          // ✳️ Pending Employers (approved by admin but not bank-approved)
          final pendingEmployers = data.entries.where((entry) {
            final user = Map<String, dynamic>.from(entry.value);
            return user['role'] == 'employer' &&
                user['approved'] == true &&
                user['bankApproved'] != true;
          }).toList();

          // 📋 Already Approved Employers
          final approvedEmployers = data.entries.where((entry) {
            final user = Map<String, dynamic>.from(entry.value);
            return user['role'] == 'employer' &&
                user['approved'] == true &&
                user['bankApproved'] == true;
          }).toList();

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "Pending Employer Approvals",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (pendingEmployers.isEmpty)
                const ListTile(
                    title: Text("No pending bank approvals.", textAlign: TextAlign.center))
              else
                ...pendingEmployers.map((entry) {
                  final uid = entry.key;
                  final user = Map<String, dynamic>.from(entry.value);
                  final name = user['name'] ?? 'Unnamed';
                  final email = user['email'] ?? 'No email';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text(email),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          await usersRef.child(uid).update({"bankApproved": true});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Approved $name successfully!")),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text("Approve"),
                      ),
                    ),
                  );
                }),

              const Divider(thickness: 1),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "📋 Approved Employers",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (approvedEmployers.isEmpty)
                const ListTile(
                    title: Text("No approved employers yet.", textAlign: TextAlign.center))
              else
                ...approvedEmployers.map((entry) {
                  final user = Map<String, dynamic>.from(entry.value);
                  final name = user['name'] ?? 'Unnamed';
                  final email = user['email'] ?? 'No email';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text(email),
                      trailing: const Icon(Icons.verified, color: Colors.green),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  } 
}
