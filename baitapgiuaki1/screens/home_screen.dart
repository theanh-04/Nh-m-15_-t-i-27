import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/task_card.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  List<Task> _tasks = [];
  String _filter = 'all'; // 'all', 'pending', 'completed'
  String _sortBy = 'date'; // 'date', 'name'

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _storageService.loadTasks();
    setState(() {
      _tasks = tasks;
      _sortTasks();
    });
  }

  Future<void> _saveTasks() async {
    await _storageService.saveTasks(_tasks);
  }

  void _sortTasks() {
    if (_sortBy == 'date') {
      _tasks.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } else {
      _tasks.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  List<Task> get _filteredTasks {
    switch (_filter) {
      case 'pending':
        return _tasks.where((task) => !task.isCompleted).toList();
      case 'completed':
        return _tasks.where((task) => task.isCompleted).toList();
      default:
        return _tasks;
    }
  }

  Future<void> _addOrEditTask([Task? task]) async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(task: task),
      ),
    );

    if (result != null) {
      setState(() {
        if (task == null) {
          _tasks.add(result);
        } else {
          final index = _tasks.indexWhere((t) => t.id == task.id);
          if (index != -1) {
            _tasks[index] = result;
          }
        }
        _sortTasks();
      });
      await _saveTasks();
      
      if (result.enableReminder) {
        await NotificationService.scheduleReminder(result);
      }
    }
  }

  Future<void> _toggleTask(Task task) async {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
    await _saveTasks();
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa công việc "${task.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _tasks.removeWhere((t) => t.id == task.id);
      });
      await _saveTasks();
      await NotificationService.cancelReminder(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;
    final pendingCount = _tasks.where((t) => !t.isCompleted).length;
    final completedCount = _tasks.where((t) => t.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhắc việc'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Test thông báo',
            onPressed: () async {
              await NotificationService.showTestNotification();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã gửi thông báo test! Kiểm tra thanh thông báo.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortTasks();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Text('Sắp xếp theo thời gian'),
              ),
              const PopupMenuItem(
                value: 'name',
                child: Text('Sắp xếp theo tên'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Tất cả', _tasks.length, Colors.blue),
                _buildStatCard('Chưa xong', pendingCount, Colors.orange),
                _buildStatCard('Hoàn thành', completedCount, Colors.green),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('Tất cả'), icon: Icon(Icons.list)),
                ButtonSegment(value: 'pending', label: Text('Chưa xong'), icon: Icon(Icons.pending)),
                ButtonSegment(value: 'completed', label: Text('Hoàn thành'), icon: Icon(Icons.check_circle)),
              ],
              selected: {_filter},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _filter = newSelection.first;
                });
              },
            ),
          ),
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'all' 
                              ? 'Chưa có công việc nào'
                              : _filter == 'pending'
                                  ? 'Không có công việc chưa hoàn thành'
                                  : 'Không có công việc đã hoàn thành',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return TaskCard(
                        task: task,
                        onToggle: () => _toggleTask(task),
                        onDelete: () => _deleteTask(task),
                        onEdit: () => _addOrEditTask(task),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditTask(),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm việc'),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
