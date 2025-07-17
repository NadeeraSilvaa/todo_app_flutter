import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  Stream<Map<String, dynamic>> getTaskSummary() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value({});

    return FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      int completed = 0;
      int pending = 0;
      Map<String, int> categoryCounts = {'Work': 0, 'Personal': 0, 'Urgent': 0};

      for (var doc in snapshot.docs) {
        final isCompleted = doc['isCompleted'] ?? false;
        final category = doc['category']?.toString() ?? 'Personal';
        if (isCompleted) {
          completed++;
        } else {
          pending++;
        }
        if (categoryCounts.containsKey(category)) {
          categoryCounts[category] = categoryCounts[category]! + 1;
        }
      }

      return {
        'completed': completed,
        'pending': pending,
        'categoryCounts': categoryCounts,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Summary'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: getTaskSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppColors.textPrimary)));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('No tasks available', style: TextStyle(color: AppColors.textPrimary)));
          }

          final summary = snapshot.data!;
          final completed = summary['completed'] ?? 0;
          final pending = summary['pending'] ?? 0;
          final categoryCounts = summary['categoryCounts'] as Map<String, int>;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Statistics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [AppColors.cardShadow],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Completed Tasks: $completed',
                          style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pending Tasks: $pending',
                          style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [AppColors.cardShadow],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Task Distribution',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: categoryCounts['Work']?.toDouble() ?? 0,
                                  title: 'Work',
                                  color: AppColors.workCategory,
                                  radius: 80,
                                  titleStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                ),
                                PieChartSectionData(
                                  value: categoryCounts['Personal']?.toDouble() ?? 0,
                                  title: 'Personal',
                                  color: AppColors.personalCategory,
                                  radius: 80,
                                  titleStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                ),
                                PieChartSectionData(
                                  value: categoryCounts['Urgent']?.toDouble() ?? 0,
                                  title: 'Urgent',
                                  color: AppColors.urgentCategory,
                                  radius: 80,
                                  titleStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                ),
                              ],
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}