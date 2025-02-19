import 'package:flutter/material.dart';

void showDataInputForm(BuildContext context, Function(String) onSave) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DataInputPage(onSave: onSave),
    ),
  );
}

class DataInputPage extends StatefulWidget {
  final Function(String) onSave;

  const DataInputPage({super.key, required this.onSave});

  @override
  _DataInputPageState createState() => _DataInputPageState();
}

class _DataInputPageState extends State<DataInputPage> {
  final TextEditingController dataController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Data to Store")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: dataController,
              decoration: const InputDecoration(hintText: "Enter your data"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (dataController.text.isNotEmpty) {
                  widget.onSave(dataController.text);
                  Navigator.pop(context); // Close the page after saving
                }
              },
              child: const Text("Save"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context), // Close the page without saving
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}
