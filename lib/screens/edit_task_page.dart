import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../utils/validators.dart';
import '../widgets/common/common_text_field.dart';
import '../widgets/common/common_gradient_button.dart';
import '../widgets/common/common_dropdown.dart';

class EditTaskPage extends StatefulWidget {
  const EditTaskPage({super.key});

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _reminderController;
  late String _selectedCategory;
  late String _selectedPriority;
  late DateTime _selectedDate;
  late TimeOfDay _selectedReminderTime;
  late String _taskId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _notesController = TextEditingController();
    _reminderController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final task = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _taskId = task['id'];
    _titleController.text = task['title'];
    _descriptionController.text = task['description'];
    _notesController.text = task['notes'] ?? '';
    _selectedCategory = task['category'];
    _selectedPriority = task['priority'];
    _selectedDate = task['dueDate'];
    if (task['reminder'] != null) {
      final reminderDateTime = (task['reminder'] as Timestamp).toDate();
      _selectedReminderTime = TimeOfDay.fromDateTime(reminderDateTime);
      _reminderController.text = _selectedReminderTime.format(context);
    } else {
      _selectedReminderTime = TimeOfDay.now();
    }
  }

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

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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

      await FirebaseFirestore.instance.collection('tasks').doc(_taskId).update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'notes': _notesController.text.trim(),
        'category': _selectedCategory,
        'dueDate': Timestamp.fromDate(_selectedDate),
        'reminder': reminderDateTime != null ? Timestamp.fromDate(reminderDateTime) : null,
        'priority': _selectedPriority,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to update task: $e';
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.appBarGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Edit Task',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                      ),
                      textAlign: TextAlign.center,
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
                  CommonGradientButton(
                    text: 'Update Task',
                    onPressed: _updateTask,
                    isLoading: _isLoading,
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
            Flexible(
              child: Text(
                'Due Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                style: TextStyle(color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
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
            Flexible(
              child: Text(
                _reminderController.text.isEmpty
                    ? 'Set Reminder (Optional)'
                    : 'Reminder: ${_reminderController.text}',
                style: TextStyle(color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.alarm, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}