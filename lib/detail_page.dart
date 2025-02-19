import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  final String data;

  const DetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(data)), // Display the same name in the heading
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Details for: $data", style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            // Add any other details you want to show here
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }
}
