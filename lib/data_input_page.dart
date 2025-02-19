import 'package:flutter/material.dart';

class DataInputPage extends StatefulWidget {
  const DataInputPage({super.key});

  @override
  _DataInputPageState createState() => _DataInputPageState();
}

class _DataInputPageState extends State<DataInputPage> {
  final TextEditingController dataController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Data")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: dataController,
              decoration: const InputDecoration(
                hintText: "Enter your data",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (dataController.text.isNotEmpty) {
                  Navigator.pop(context, dataController.text); // Return the entered data
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
