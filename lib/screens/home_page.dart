import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCategory = 'All';
  int _currentIndex = 0;

  Stream<List<Map<String, dynamic>>> getTasksStream() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .orderBy('dueDate', descending: false);

    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'title': doc['title']?.toString() ?? 'Untitled',
          'description': doc['description']?.toString() ?? '',
          'category': doc['category']?.toString() ?? 'Personal',
          'dueDate': (doc['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
        return AppColors.textSecondary;
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
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Tasks'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {}, // Prototype reminder badge
              ),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: getTasksStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final overdueCount = snapshot.data!
                      .where((task) => !task['isCompleted'] && task['dueDate'].isBefore(DateTime.now()))
                      .length;
                  if (overdueCount == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$overdueCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {}, // Prototype search functionality
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 100),
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
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getTasksStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppColors.textPrimary)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No tasks available', style: TextStyle(color: AppColors.textPrimary)));
                }

                final tasks = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isOverdue = !task['isCompleted'] && task['dueDate'].isBefore(DateTime.now());
                    return Dismissible(
                      key: Key(task['id']),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        FirebaseFirestore.instance.collection('tasks').doc(task['id']).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Task deleted')),
                        );
                      },
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
                              color: isOverdue ? Colors.red : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${task['category']} | Due: ${DateFormat('MMM dd, yyyy').format(task['dueDate'])}',
                                style: TextStyle(color: AppColors.textSecondary),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.cardBackground,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Task'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Summary'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) Navigator.pushNamed(context, '/home');
          if (index == 1) Navigator.pushNamed(context, '/add_task');
          if (index == 2) Navigator.pushNamed(context, '/summary');
          if (index == 3) Navigator.pushNamed(context, '/profile');
        },
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
          boxShadow: [AppColors.buttonShadow],
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