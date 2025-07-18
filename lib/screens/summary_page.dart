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
      Map<String, int> priorityCounts = {'Low': 0, 'Medium': 0, 'High': 0};

      for (var doc in snapshot.docs) {
        final isCompleted = doc['isCompleted'] ?? false;
        if (isCompleted) {
          completed++;
        } else {
          pending++;
        }
        final category = doc['category']?.toString() ?? 'Personal';
        final priority = doc['priority']?.toString() ?? 'Low';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;
      }

      return {
        'completed': completed,
        'pending': pending,
        'categoryCounts': categoryCounts,
        'priorityCounts': priorityCounts,
      };
    });
  }

  List<PieChartSectionData> _getPieChartSections(Map<String, int> counts, Map<String, Color> colorMap) {
    final total = counts.values.fold(0, (sum, value) => sum + value);
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: 'No Data',
          color: Colors.grey,
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryDark,
          ),
        ),
      ];
    }

    return counts.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
        color: colorMap[entry.key] ?? Colors.grey,
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: StreamBuilder<Map<String, dynamic>>(
              stream: getTaskSummary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No tasks available',
                      style: TextStyle(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final summary = snapshot.data!;
                final categoryCounts = summary['categoryCounts'] as Map<String, int>;
                final priorityCounts = summary['priorityCounts'] as Map<String, int>;

                final categoryColors = {
                  'Work': AppColors.workCategory,
                  'Personal': AppColors.personalCategory,
                  'Urgent': AppColors.urgentCategory,
                };

                final priorityColors = {
                  'Low': AppColors.priorityLow,
                  'Medium': AppColors.priorityMedium,
                  'High': AppColors.priorityHigh,
                };

                return Column(
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
                        'Task Summary',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryDark,
                        ),
                        textAlign: TextAlign.center,
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Task Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: _getPieChartSections(
                                  {
                                    'Completed': summary['completed'],
                                    'Pending': summary['pending'],
                                  },
                                  {
                                    'Completed': AppColors.accent,
                                    'Pending': Colors.grey,
                                  },
                                ),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Completed: ${summary['completed']}',
                            style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Pending: ${summary['pending']}',
                            style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Tasks by Category',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: _getPieChartSections(categoryCounts, categoryColors),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...categoryCounts.entries.map((entry) {
                            return Text(
                              '${entry.key}: ${entry.value}',
                              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                              textAlign: TextAlign.center,
                            );
                          }).toList(),
                        ],
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Tasks by Priority',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: _getPieChartSections(priorityCounts, priorityColors),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...priorityCounts.entries.map((entry) {
                            return Text(
                              '${entry.key}: ${entry.value}',
                              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                              textAlign: TextAlign.center,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}