import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;

  const AddTaskScreen({Key? key, this.task}) : super(key: key);

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late DateTime _selectedDateTime;
  late bool _enableReminder;
  late String _reminderType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task?.name ?? '');
    _locationController = TextEditingController(text: widget.task?.location ?? '');
    _selectedDateTime = widget.task?.dateTime ?? DateTime.now().add(const Duration(hours: 1));
    _enableReminder = widget.task?.enableReminder ?? false;
    _reminderType = widget.task?.reminderType ?? 'notification';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        dateTime: _selectedDateTime,
        location: _locationController.text.trim(),
        enableReminder: _enableReminder,
        reminderType: _reminderType,
        isCompleted: widget.task?.isCompleted ?? false,
      );

      Navigator.pop(context, task);
    }
  }

  Widget _buildReminderOption(String value, String title, String subtitle, IconData icon) {
    final isSelected = _reminderType == value;
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue[50] : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue[900] : Colors.black87,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Radio<String>(
          value: value,
          groupValue: _reminderType,
          onChanged: (newValue) {
            setState(() {
              _reminderType = newValue!;
            });
          },
        ),
        onTap: () {
          setState(() {
            _reminderType = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Thêm công việc' : 'Sửa công việc'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên công việc *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên công việc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Thời gian *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(_selectedDateTime),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Địa điểm *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập địa điểm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Bật nhắc việc'),
                subtitle: const Text('Nhắc trước 15 phút'),
                value: _enableReminder,
                onChanged: (value) {
                  setState(() {
                    _enableReminder = value;
                  });
                },
                secondary: const Icon(Icons.notifications_active),
              ),
              if (_enableReminder) ...[
                const SizedBox(height: 16),
                const Text(
                  'Loại nhắc việc:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildReminderOption(
                  'notification',
                  'Thông báo',
                  'Hiển thị thông báo trên màn hình',
                  Icons.notifications,
                ),
                _buildReminderOption(
                  'alarm',
                  'Chuông điện thoại',
                  'Phát âm thanh chuông báo',
                  Icons.alarm,
                ),
                _buildReminderOption(
                  'email',
                  'Email',
                  'Gửi email nhắc việc',
                  Icons.email,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.task == null ? 'Thêm công việc' : 'Cập nhật',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
