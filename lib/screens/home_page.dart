import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../widgets/common/common_text_field.dart';
import '../widgets/common/common_dropdown.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCategory = 'All';
  String _selectedSort = 'Due Date';
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> getTasksStream() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: uid);

    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    if (_searchQuery.isNotEmpty) {
      query = query
          .where('title', isGreaterThanOrEqualTo: _searchQuery)
          .where('title', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
          .orderBy('title');
    } else {
      switch (_selectedSort) {
        case 'Due Date':
          query = query.orderBy('dueDate', descending: false);
          break;
        case 'Priority':
          query = query.orderBy('priority', descending: true);
          break;
        case 'Title':
          query = query.orderBy('title', descending: false);
          break;
      }
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'title': doc['title']?.toString() ?? 'Untitled',
          'description': doc['description']?.toString() ?? '',
          'notes': doc['notes']?.toString() ?? '',
          'category': doc['category']?.toString() ?? 'Personal',
          'dueDate': (doc['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'reminder': doc['reminder'] != null ? (doc['reminder'] as Timestamp).toDate() : null,
          'isCompleted': doc['isCompleted'] ?? false,
          'priority': doc['priority']?.toString() ?? 'Low',
        };
      }).toList();
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Work':
        return AppColors.workCategory;
      case 'Personal':
        return AppColors.personalCategory;
      case 'Urgent':
        return AppColors.urgentCategory;
      default:
        return AppColors.textPrimary;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return AppColors.priorityLow;
      case 'Medium':
        return AppColors.priorityMedium;
      case 'High':
        return AppColors.priorityHigh;
      default:
        return AppColors.textPrimary;
    }
  }

  Color _getTaskTitleColor(Map<String, dynamic> task) {
    if (task['isCompleted']) {
      return Colors.grey;
    }
    final isOverdue = !task['isCompleted'] && task['dueDate'].isBefore(DateTime.now());
    return isOverdue ? Colors.red : AppColors.textPrimary;
  }

  String _getTimeLeft(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    }

    final days = difference.inDays;
    final hours = difference.inHours;
    final minutes = difference.inMinutes;

    if (days > 0) {
      return '$days day${days == 1 ? '' : 's'} left';
    } else if (hours > 0) {
      return '$hours hour${hours == 1 ? '' : 's'} left';
    } else {
      return '$minutes minute${minutes == 1 ? '' : 's'} left';
    }
  }

  Future<void> _deleteTask(String taskId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete task: $e')),
      );
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
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'My Tasks',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CommonTextField(
                    controller: _searchController,
                    label: 'Search tasks...',
                    type: TextInputType.text,
                    icon: Icons.search,
                    maxLines: 1,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFilterButton('All'),
                      _buildFilterButton('Work'),
                      _buildFilterButton('Personal'),
                      _buildFilterButton('Urgent'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CommonDropdown(
                    label: 'Sort By',
                    value: _selectedSort,
                    items: ['Due Date', 'Priority', 'Title'],
                    onChanged: (value) => setState(() => _selectedSort = value!),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: getTasksStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'No tasks available',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        );
                      }

                      final tasks = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Dismissible(
                            key: Key(task['id']),
                            background: Container(
                              color: AppColors.urgentCategory,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) => _deleteTask(task['id']),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [AppColors.cardShadow],
                              ),
                              child: ListTile(
                                leading: Checkbox(
                                  value: task['isCompleted'],
                                  activeColor: AppColors.accent,
                                  onChanged: (value) {
                                    FirebaseFirestore.instance
                                        .collection('tasks')
                                        .doc(task['id'])
                                        .update({'isCompleted': value});
                                  },
                                ),
                                title: Text(
                                  task['title'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: task['isCompleted'] ? TextDecoration.lineThrough : null,
                                    color: _getTaskTitleColor(task),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${task['category']} | Due: ${DateFormat('MMM dd, yyyy').format(task['dueDate'])}',
                                      style: TextStyle(color: AppColors.textPrimary),
                                    ),
                                    if (task['notes'].isNotEmpty)
                                      Text(
                                        'Notes: ${task['notes']}',
                                        style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                                      ),
                                    if (task['reminder'] != null)
                                      Text(
                                        'Reminder: ${DateFormat('MMM dd, yyyy HH:mm').format(task['reminder'])}',
                                        style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                                      ),
                                    Text(
                                      _getTimeLeft(task['dueDate']),
                                      style: TextStyle(
                                        color: task['isCompleted'] ? Colors.grey : AppColors.textPrimary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(task['priority']).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Priority: ${task['priority']}',
                                        style: TextStyle(
                                          color: _getPriorityColor(task['priority']),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  width: 10,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(task['category']),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pushNamed(context, '/edit_task', arguments: task);
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String category) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedCategory == category ? AppColors.accent : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [AppColors.cardShadow],
        ),
        child: Text(
          category,
          style: TextStyle(
            color: _selectedCategory == category ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}