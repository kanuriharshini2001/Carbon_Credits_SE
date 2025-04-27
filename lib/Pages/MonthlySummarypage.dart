import 'package:flutter/material.dart';
import 'carbon_credit_calculator.dart';

class MonthlySummaryPage extends StatefulWidget {
  const MonthlySummaryPage({super.key});

  @override
  State<MonthlySummaryPage> createState() => _MonthlySummaryPageState();
}

class _MonthlySummaryPageState extends State<MonthlySummaryPage> {
  double carbonCredits = 0.0;
  double carpoolMiles = 0.0;
  double publicMiles = 0.0;
  double wfhMiles = 0.0;

  final int expectedMiles = 1000;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCredits();
  }

  Future<void> loadCredits() async {
    final result = await calculateCarbonCreditsWithModes(); // <-- updated function
    setState(() {
      carbonCredits = result["total"] ?? 0.0;
      carpoolMiles = result["carpool"] ?? 0.0;
      publicMiles = result["public"] ?? 0.0;
      wfhMiles = result["wfh"] ?? 0.0;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (carbonCredits / expectedMiles).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Monthly Carbon Summary"),
        backgroundColor: Colors.green,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(20),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco, size: 48, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    "Carbon Credit Summary",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  buildRow("Expected Miles:", "$expectedMiles mi"),
                  buildRow("Saved (Carpool/Remote):", "${carbonCredits.toStringAsFixed(1)} mi"),
                  buildRow("Carbon Credits Earned:", "${carbonCredits.toStringAsFixed(1)} pts", isHighlight: true),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    color: Colors.green,
                    minHeight: 10,
                  ),
                  const SizedBox(height: 10),
                  Text("${(progress * 100).toStringAsFixed(1)}% of $expectedMiles miles saved"),
                  const Divider(height: 32, thickness: 1),
                  const Text("Mode-wise Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  buildModeRow("🚗 Carpool miles:", carpoolMiles),
                  buildModeRow("🚌 Public Transport miles:", publicMiles),
                  buildModeRow("🏠 Work From Home miles:", wfhMiles),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildModeRow(String label, double miles) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text("${miles.toStringAsFixed(1)} mi", style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
