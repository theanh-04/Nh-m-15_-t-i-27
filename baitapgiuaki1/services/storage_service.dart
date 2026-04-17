import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class StorageService {
  static const String _tasksKey = 'tasks';

  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString(_tasksKey);
    
    if (tasksJson == null) return [];
    
    final List<dynamic> decoded = json.decode(tasksJson);
    return decoded.map((item) => Task.fromJson(item)).toList();
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_tasksKey, encoded);
  }
}
