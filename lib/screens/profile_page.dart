import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Stream<Map<String, dynamic>> getUserProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value({});

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .get();
      int completed = tasksSnapshot.docs.where((doc) => doc['isCompleted'] == true).length;
      int total = tasksSnapshot.docs.length;

      return {
        'displayName': userDoc['displayName'] ?? 'User',
        'email': userDoc['email'] ?? user.email,
        'totalTasks': total,
        'completedTasks': completed,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: AppColors.textPrimary)));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('No profile data', style: TextStyle(color: AppColors.textPrimary)));
          }

          final profile = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Profile',
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name: ${profile['displayName']}',
                          style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Email: ${profile['email']}',
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Statistics',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Tasks: ${profile['totalTasks']}',
                          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Completed Tasks: ${profile['completedTasks']}',
                          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Pending Tasks: ${profile['totalTasks'] - profile['completedTasks']}',
                          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
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