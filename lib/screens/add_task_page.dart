import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../utils/validators.dart';
import '../widgets/common/common_text_field.dart';
import '../widgets/common/common_gradient_button.dart';
import '../widgets/common/common_dropdown.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _reminderController = TextEditingController();
  String _selectedCategory = 'Personal';
  String _selectedPriority = 'Low';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedReminderTime = TimeOfDay.now();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.accent),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectReminderTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedReminderTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.accent),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedReminderTime) {
      setState(() {
        _selectedReminderTime = picked;
        _reminderController.text = picked.format(context);
      });
    }
  }

  Future<void> _addTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please log in to add a task';
      });
      return;
    }

    try {
      final reminderDateTime = _reminderController.text.isNotEmpty
          ? DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedReminderTime.hour,
        _selectedReminderTime.minute,
      )
          : null;

      await FirebaseFirestore.instance.collection('tasks').add({
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'notes': _notesController.text.trim(),
        'category': _selectedCategory,
        'dueDate': Timestamp.fromDate(_selectedDate),
        'reminder': reminderDateTime != null ? Timestamp.fromDate(reminderDateTime) : null,
        'isCompleted': false,
        'priority': _selectedPriority,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to add task: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'New Task',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CommonTextField(
                    controller: _titleController,
                    label: 'Task Title',
                    type: TextInputType.text,
                    validator: Validators.validateTitle,
                  ),
                  const SizedBox(height: 16),
                  CommonTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    type: TextInputType.multiline,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  CommonTextField(
                    controller: _notesController,
                    label: 'Notes',
                    type: TextInputType.multiline,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  CommonDropdown(
                    label: 'Category',
                    value: _selectedCategory,
                    items: ['Work', 'Personal', 'Urgent'],
                    onChanged: (value) => setState(() => _selectedCategory = value!),
                  ),
                  const SizedBox(height: 16),
                  CommonDropdown(
                    label: 'Priority',
                    value: _selectedPriority,
                    items: ['Low', 'Medium', 'High'],
                    onChanged: (value) => setState(() => _selectedPriority = value!),
                  ),
                  const SizedBox(height: 16),
                  _buildDatePicker(),
                  const SizedBox(height: 16),
                  _buildReminderPicker(),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Center(
                    child: CommonGradientButton(
                      text: 'Add Task',
                      onPressed: _addTask,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [AppColors.cardShadow],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Due Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const Icon(Icons.calendar_today, color: AppColors.accent),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderPicker() {
    return GestureDetector(
      onTap: () => _selectReminderTime(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [AppColors.cardShadow],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _reminderController.text.isEmpty
                  ? 'Set Reminder (Optional)'
                  : 'Reminder: ${_reminderController.text}',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const Icon(Icons.alarm, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}