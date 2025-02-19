import 'package:flutter/material.dart';
import './bluetooth_scan_modal.dart';
import './data_input_dialog.dart';
import './storage_service.dart';
import './user_info.dart';  // Import the UserInfo component
import './detail_page.dart';  // Import the DetailPage component

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> storedData = [];
  String username = "John Doe"; // Replace this with your dynamic username

  @override
  void initState() {
    super.initState();
    _loadStoredData();
  }

  void _loadStoredData() async {
    List<String> data = await StorageService.loadData();
    setState(() {
      storedData = data;
    });
  }

  void _addData(String newData) {
    setState(() {
      storedData.add(newData);
    });
    StorageService.saveData(storedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea( // SafeArea prevents overlap with the status bar
        child: Column(
          children: [
            UserInfo(username: username), // User info component
            Expanded(
              child: ListView.builder(
                itemCount: storedData.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(storedData[index], style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      // Navigate to the DetailPage with the selected item
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(data: storedData[index]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () => showDataInputForm(context, _addData),
                child: const Text("Add Data"),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => showScanModal(context),
      ),
    );
  }
}
