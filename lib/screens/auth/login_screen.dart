import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:flutter/material.dart';

import 'login_screen_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'traveler');
  final _passwordController = TextEditingController(text: 'Traveler@123');

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await VietaiScope.of(context).login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dang nhap that bai. Hay kiem tra backend va tai khoan.\n$e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chuc nang nay chua duoc ket noi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginScreenStyles.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: LoginScreenStyles.horizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildTitleSection(),
              const SizedBox(height: LoginScreenStyles.sectionSpacing),
              _buildForm(),
              const SizedBox(height: 24),
              _buildLoginButton(),
              const SizedBox(height: 24),
              _buildDivider(),
              const SizedBox(height: 24),
              _buildSocialButtons(),
              const SizedBox(height: 24),
              _buildFooter(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back),
              color: LoginScreenStyles.textPrimary,
            ),
            TextButton.icon(
              onPressed: _showComingSoon,
              icon: const Icon(
                Icons.language,
                size: 18,
                color: LoginScreenStyles.textPrimary,
              ),
              label: const Text(
                'Tieng Viet',
                style: TextStyle(color: LoginScreenStyles.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTitleSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chao mung tro lai!', style: LoginScreenStyles.title),
        SizedBox(height: 6),
        Text(
          'Dang nhap de tiep tuc kham pha VietAI Travel.',
          style: LoginScreenStyles.subtitle,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ten dang nhap', style: LoginScreenStyles.inputLabel),
          const SizedBox(height: 8),
          TextFormField(
            controller: _usernameController,
            textInputAction: TextInputAction.next,
            decoration: LoginScreenStyles.inputDecoration(
              hint: 'Vi du: traveler',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui long nhap ten dang nhap';
              }
              return null;
            },
          ),
          const SizedBox(height: LoginScreenStyles.fieldSpacing),
          const Text('Mat khau', style: LoginScreenStyles.inputLabel),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            onFieldSubmitted: (_) => _isLoading ? null : _handleLogin(),
            decoration: LoginScreenStyles.inputDecoration(
              hint: 'Nhap mat khau',
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: LoginScreenStyles.textSecondary,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui long nhap mat khau';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showComingSoon,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text(
                'Quen mat khau?',
                style: LoginScreenStyles.linkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: LoginScreenStyles.primaryButtonStyle,
      child: _isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : const Text(
              'Dang nhap',
              style: LoginScreenStyles.primaryButtonText,
            ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: LoginScreenStyles.inputBorder)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('hoac', style: LoginScreenStyles.dividerText),
        ),
        Expanded(child: Divider(color: LoginScreenStyles.inputBorder)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialButton(icon: Icons.g_mobiledata, onTap: _showComingSoon),
        const SizedBox(width: 20),
        _socialButton(icon: Icons.facebook, onTap: _showComingSoon),
        const SizedBox(width: 20),
        _socialButton(icon: Icons.apple, onTap: _showComingSoon),
      ],
    );
  }

  Widget _socialButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        LoginScreenStyles.socialButtonRadius,
      ),
      child: Container(
        width: 52,
        height: 52,
        decoration: LoginScreenStyles.socialButtonDecoration,
        child: Icon(icon, color: LoginScreenStyles.textPrimary, size: 26),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Chua co tai khoan? ',
            style: LoginScreenStyles.footerText,
          ),
          GestureDetector(
            onTap: _showComingSoon,
            child: const Text(
              'Dang ky ngay',
              style: LoginScreenStyles.footerLink,
            ),
          ),
        ],
      ),
    );
  }
}
