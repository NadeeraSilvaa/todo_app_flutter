import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../utils/validators.dart';
import '../widgets/common/common_text_field.dart';
import '../widgets/common/common_gradient_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profilePictureController = TextEditingController();
  String? _profilePictureUrl;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _profilePictureController.dispose();
    super.dispose();
  }

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
    if (Validators.validateUrl(_profilePictureController.text.trim()) != null) {
      setState(() {
        _errorMessage = 'Invalid profile picture URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profilePicture': _profilePictureController.text.trim(),
        });
        setState(() {
          _profilePictureUrl = _profilePictureController.text.trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to update profile picture: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: getUserProfile(),
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
            if (!snapshot.hasData) {
              return Center(
                child: Text(
                  'No profile data',
                  style: TextStyle(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final profile = snapshot.data!;
            _profilePictureController.text = profile['profilePicture'] ?? '';
            _profilePictureUrl = profile['profilePicture'];

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                        'User Profile',
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
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [AppColors.cardShadow],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_profilePictureUrl != null && _profilePictureUrl!.isNotEmpty)
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(_profilePictureUrl!),
                              onBackgroundImageError: (_, __) => const Icon(Icons.error),
                            ),
                          const SizedBox(height: 16),
                          CommonTextField(
                            controller: _profilePictureController,
                            label: 'Profile Picture URL (Optional)',
                            type: TextInputType.url,
                            validator: Validators.validateUrl,
                          ),
                          const SizedBox(height: 16),
                          CommonGradientButton(
                            text: 'Update Picture',
                            onPressed: _updateProfilePicture,
                            isLoading: _isLoading,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Name: ${profile['displayName']}',
                            style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email: ${profile['email']}',
                            style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
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
                            'Task Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total Tasks: ${profile['totalTasks']}',
                            style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Completed Tasks: ${profile['completedTasks']}',
                            style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Pending Tasks: ${profile['totalTasks'] - profile['completedTasks']}',
                            style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                            textAlign: TextAlign.center,
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
      ),
    );
  }
}