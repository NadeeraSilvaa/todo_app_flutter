import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/colors.dart';
import '../utils/validators.dart';
import '../widgets/common/common_text_field.dart';
import '../widgets/common/common_gradient_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController();
  String? _currentName;
  String? _profilePictureUrl;
  bool _isDarkMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _currentName = doc.data()?['displayName'] ?? user.displayName ?? '';
        _nameController.text = _currentName!;
        _profilePictureUrl = doc.data()?['profilePicture'] ?? '';
        _isDarkMode = doc.data()?['themeMode'] == 'dark';
      });
    }
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
        'displayName': userDoc.data()?['displayName'] ?? user.displayName ?? 'User',
        'email': userDoc.data()?['email'] ?? user.email ?? '',
        'profilePicture': userDoc.data()?['profilePicture'] ?? '',
        'totalTasks': total,
        'completedTasks': completed,
      };
    });
  }

  Future<void> _pickAndUploadImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Please log in to update profile picture';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        // Validate image size (max 5MB)
        if (await imageFile.length() > 5 * 1024 * 1024) {
          setState(() {
            _errorMessage = 'Image size must be less than 5MB';
          });
          return;
        }
        // Validate image type
        if (!['.jpg', '.jpeg', '.png'].contains(pickedFile.path.toLowerCase().substring(pickedFile.path.length - 4))) {
          setState(() {
            _errorMessage = 'Only JPG or PNG images are allowed';
          });
          return;
        }

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${user.uid}.jpg');
        await storageRef.putFile(imageFile);
        final downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profilePicture': downloadUrl,
          'displayName': _currentName ?? user.displayName ?? '',
          'email': user.email,
          'themeMode': _isDarkMode ? 'dark' : 'light',
        }, SetOptions(merge: true));

        setState(() {
          _profilePictureUrl = downloadUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload image: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateName() async {
    if (Validators.validateName(_nameController.text.trim()) != null) {
      setState(() {
        _errorMessage = Validators.validateName(_nameController.text.trim());
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': _nameController.text.trim(),
          'email': user.email,
          'profilePicture': _profilePictureUrl ?? '',
          'themeMode': _isDarkMode ? 'dark' : 'light',
        }, SetOptions(merge: true));
        setState(() {
          _currentName = _nameController.text.trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated')),
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to update name: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleTheme(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'themeMode': value ? 'dark' : 'light',
          'displayName': _currentName ?? user.displayName ?? '',
          'email': user.email,
          'profilePicture': _profilePictureUrl ?? '',
        }, SetOptions(merge: true));
        setState(() {
          _isDarkMode = value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Theme set to ${_isDarkMode ? 'Dark' : 'Light'}')),
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to update theme: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to log out: $e';
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
            _nameController.text = profile['displayName'] ?? '';
            _profilePictureUrl = profile['profilePicture'] ?? '';

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
                        'Settings',
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
                          Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _isLoading ? null : _pickAndUploadImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                                      ? NetworkImage(_profilePictureUrl!)
                                      : const AssetImage('assets/default_profile.jpg') as ImageProvider,
                                  onBackgroundImageError: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
                                      ? (_, __) => const Icon(Icons.error)
                                      : null,
                                  child: _profilePictureUrl == null || _profilePictureUrl!.isEmpty
                                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                                      : null,
                                ),
                                if (_isLoading)
                                  const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to change profile picture',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 200,
                            child: CommonTextField(
                              controller: _nameController,
                              label: 'Display Name',
                              type: TextInputType.name,
                              validator: Validators.validateName,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Email: ${profile['email']}',
                            style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          CommonGradientButton(
                            text: 'Update Name',
                            onPressed: _updateName,
                            isLoading: _isLoading,
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
                            'Appearance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Dark Mode',
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: 16),
                              Switch(
                                value: _isDarkMode,
                                activeColor: AppColors.accent,
                                onChanged: _isLoading ? null : _toggleTheme,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    CommonGradientButton(
                      text: 'Logout',
                      onPressed: _logout,
                      gradient: LinearGradient(
                        colors: [AppColors.urgentCategory, AppColors.urgentCategory.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      isLoading: _isLoading,
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