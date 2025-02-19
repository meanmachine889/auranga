import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<List<String>> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedDataString = prefs.getString('storedData');
    return storedDataString != null ? List<String>.from(jsonDecode(storedDataString)) : [];
  }

  static Future<void> saveData(List<String> storedData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storedData', jsonEncode(storedData));
  }
}
