import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profilePictureController = TextEditingController();
  String? _profilePictureUrl;

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
        'profilePicture': userDoc['profilePicture'] ?? '',
        'totalTasks': total,
        'completedTasks': completed,
      };
    });
  }

  Future<void> _updateProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profilePicture': _profilePictureController.text.trim(),
      });
      setState(() {
        _profilePictureUrl = _profilePictureController.text.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<Map<String, dynamic>>(
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
          _profilePictureController.text = profile['profilePicture'] ?? '';
          _profilePictureUrl = profile['profilePicture'];

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
                        if (_profilePictureUrl != null && _profilePictureUrl!.isNotEmpty)
                          Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(_profilePictureUrl!),
                              onBackgroundImageError: (_, __) => const Icon(Icons.error),
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _profilePictureController,
                          decoration: InputDecoration(
                            labelText: 'Profile Picture URL',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildGradientButton('Update Picture', _updateProfilePicture),
                        const SizedBox(height: 16),
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

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppColors.cardShadow],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}