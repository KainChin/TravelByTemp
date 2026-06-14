import 'package:flutter/material.dart';
import 'widgets/form_section.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl     = TextEditingController(text: 'Thu Duc');
  final _usernameCtrl = TextEditingController(text: 'thuduc_98');
  final _bioCtrl      = TextEditingController(text: 'Collect moments, not things.\nTravel • Explore • Memories');
  final _emailCtrl    = TextEditingController(text: 'thuduc.nguyen@gmail.com');
  final _phoneCtrl    = TextEditingController(text: '+84 912 345 678');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildAvatarHero(),
            const SizedBox(height: 10),
            FormSection(
              icon: Icons.person_outline,
              title: 'Personal Information',
              fields: [
                FormFieldData(label: 'Full Name',  controller: _nameCtrl),
                FormFieldData(label: 'Username',   controller: _usernameCtrl),
                FormFieldData(label: 'Bio',        controller: _bioCtrl, maxLines: 3, maxLength: 150),
              ],
              trailing: _buildLocationRow(),
            ),
            FormSection(
              icon: Icons.email_outlined,
              title: 'Contact Information',
              fields: [
                FormFieldData(label: 'Email',        controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
                FormFieldData(label: 'Phone Number', controller: _phoneCtrl, keyboardType: TextInputType.phone),
              ],
            ),
            _buildPreferencesSection(),
            _buildSaveButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF5F7F8), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
      title: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF3A7D5A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarHero() {
    return Container(
      height: 140,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB8D8E8), Color(0xFFD4E8D4), Color(0xFFA8C8B8)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A7D5A),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.image_outlined, size: 14, color: Color(0xFF3A7D5A)),
              label: const Text('Change Photo', style: TextStyle(fontSize: 12, color: Color(0xFF3A7D5A))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF3A7D5A)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Location', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF3A7D5A)),
              SizedBox(width: 8),
              Expanded(child: Text('Hanoi, Vietnam', style: TextStyle(fontSize: 14))),
              Icon(Icons.keyboard_arrow_down, color: Color(0xFF888888)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings_outlined, color: Color(0xFF3A7D5A)),
              SizedBox(width: 8),
              Text('Preferences', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          _buildPrefRow(Icons.language, 'Language', 'English'),
          _buildPrefRow(Icons.notifications_outlined, 'Notification', ''),
        ],
      ),
    );
  }

  Widget _buildPrefRow(IconData icon, String label, String value) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF3A7D5A)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            if (value.isNotEmpty) Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF888888)),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.save_outlined, color: Colors.white),
          label: const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3A7D5A),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}