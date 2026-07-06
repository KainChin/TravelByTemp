// ignore_for_file: unnecessary_library_name
library edit_profile_screen;

import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/core/widgets/safe_network_image.dart';
import 'package:flutter/material.dart';

part 'edit_profile/edit_profile_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _avatarUrlCtrl = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final user = VietaiScope.of(context).auth?.user;
    _nameCtrl.text = user?.fullName ?? '';
    _usernameCtrl.text = user?.username ?? '';
    _emailCtrl.text = user?.email ?? '';
    _bioCtrl.text = user?.bio ?? '';
    _phoneCtrl.text = user?.phone ?? '';
    _avatarUrlCtrl.text = user?.avatarUrl ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _avatarUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final bio = _bioCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final avatarUrl = _avatarUrlCtrl.text.trim();

    if (name.isEmpty || username.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await VietaiScope.of(context).updateProfile(
        username: username,
        email: email,
        fullName: name,
        bio: bio.isEmpty ? null : bio,
        phone: phone.isEmpty ? null : phone,
        avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot update profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = VietaiScope.of(context).locationName;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF3A7D5A),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _AvatarHero(name: _nameCtrl.text, avatarUrl: _avatarUrlCtrl.text),
          const SizedBox(height: 12),
          _Section(
            icon: Icons.person_outline,
            title: 'Personal information',
            children: [
              _ProfileField(label: 'Full name', controller: _nameCtrl),
              _ProfileField(label: 'Username', controller: _usernameCtrl),
              _ProfileField(
                label: 'Bio',
                controller: _bioCtrl,
                maxLines: 3,
                maxLength: 300,
              ),
            ],
          ),
          _Section(
            icon: Icons.email_outlined,
            title: 'Contact information',
            children: [
              _ProfileField(
                label: 'Email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              _ProfileField(
                label: 'Phone number',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 30,
              ),
              _ProfileField(
                label: 'Avatar image URL',
                controller: _avatarUrlCtrl,
                keyboardType: TextInputType.url,
                maxLength: 500,
              ),
            ],
          ),
          _Section(
            icon: Icons.location_on_outlined,
            title: 'Current location',
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(location),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            label: Text(
              _isSaving ? 'Saving...' : 'Save Changes',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A7D5A),
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
