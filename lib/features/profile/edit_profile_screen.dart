import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/core/models/user_model.dart';
import 'package:formulandsocialapp/core/services/auth_service.dart';
import 'dart:typed_data';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _teamCtrl;

  bool _saving = false;
  Uint8List? _newAvatarBytes;
  String? _avatarError;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.user.username);
    _bioCtrl = TextEditingController(text: widget.user.bio);
    _teamCtrl = TextEditingController(text: widget.user.favouriteTeam);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _teamCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final sizeInMb = (file.size ?? 0) / (1024 * 1024);

        if (sizeInMb > 5) {
          setState(() => _avatarError = 'Image must be less than 5MB');
          return;
        }

        setState(() {
          _newAvatarBytes = file.bytes;
          _avatarError = null;
        });
      }
    } catch (e) {
      setState(() => _avatarError = 'Failed to pick image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (_usernameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username cannot be empty'),
          backgroundColor: AppStyles.accentRed,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Update user document in Firestore
      final updatedUser = widget.user.copyWith(
        username: _usernameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        favouriteTeam: _teamCtrl.text.trim(),
      );

      // TODO: Upload new avatar if selected and update user document
      final firestore = AuthService.instance.firestoreDb;
      await firestore
          .collection('users')
          .doc(widget.user.uid)
          .update(updatedUser.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppStyles.accentRed,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate profile was updated
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppStyles.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppStyles.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppStyles.textMain,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar section
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppStyles.surface,
                          border: Border.all(
                            color: AppStyles.accentRed.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: _newAvatarBytes != null
                            ? ClipOval(
                                child: Image.memory(
                                  _newAvatarBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : widget.user.avatarUrl.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      widget.user.avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          _getInitials(widget.user.username),
                                          style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900,
                                            color: AppStyles.textMain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _getInitials(widget.user.username),
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        color: AppStyles.textMain,
                                      ),
                                    ),
                                  ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppStyles.accentRed,
                          border: Border.all(color: AppStyles.background, width: 2),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _pickAvatar,
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_avatarError != null)
                    Text(
                      _avatarError!,
                      style: const TextStyle(
                        color: AppStyles.accentRed,
                        fontSize: 12,
                      ),
                    ),
                  if (_newAvatarBytes != null)
                    const Text(
                      'Image selected',
                      style: TextStyle(
                        color: AppStyles.accentRed,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Username field
            Text(
              'USERNAME',
              style: AppStyles.label.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameCtrl,
              style: const TextStyle(color: AppStyles.textMain),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: const TextStyle(color: AppStyles.textSub),
                filled: true,
                fillColor: AppStyles.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppStyles.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppStyles.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppStyles.accentRed, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Bio field
            Text(
              'BIO',
              style: AppStyles.label.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioCtrl,
              style: const TextStyle(color: AppStyles.textMain),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell us about yourself',
                hintStyle: const TextStyle(color: AppStyles.textSub),
                filled: true,
                fillColor: AppStyles.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppStyles.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppStyles.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppStyles.accentRed, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Favorite Team field
            Text(
              'FAVORITE TEAM',
              style: AppStyles.label.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _teamCtrl,
              style: const TextStyle(color: AppStyles.textMain),
              decoration: InputDecoration(
                hintText: 'e.g., Ferrari, McLaren, Red Bull',
                hintStyle: const TextStyle(color: AppStyles.textSub),
                filled: true,
                fillColor: AppStyles.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppStyles.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppStyles.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppStyles.accentRed, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppStyles.accentRed, Color(0xFFAA0400)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _saving ? null : _saveProfile,
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  color: AppStyles.surface,
                  border: Border.all(color: AppStyles.borderColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: const Center(
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppStyles.textMain,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join('');
  }
}
