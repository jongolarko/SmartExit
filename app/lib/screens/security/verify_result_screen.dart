import 'package:flutter/material.dart';

class VerifyResultScreen extends StatelessWidget {
  final Map<String, dynamic>? result;

  const VerifyResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result == null || result!["valid"] != true) {
      return Scaffold(
        appBar: AppBar(title: const Text("Invalid QR")),
        body: const Center(
          child: Text(
            "❌ INVALID OR EXPIRED QR",
            style: TextStyle(fontSize: 22, color: Colors.red),
          ),
        ),
      );
    }

    final user = result!["user"];
    final order = result!["order"];

    return Scaffold(
      appBar: AppBar(title: const Text("Verify Exit")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.verified, size: 80, color: Colors.green),
            const SizedBox(height: 16),

            infoTile("Customer", user["name"]),
            infoTile("Phone", user["phone"]),
            infoTile("Amount", "₹${order["amount"]}"),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("ALLOW EXIT"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("DENY"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text("$label: ",
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
