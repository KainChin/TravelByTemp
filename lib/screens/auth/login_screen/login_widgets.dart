// ignore_for_file: use_string_in_part_of_directives
part of login_screen;

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.onLanguageTap});

  final VoidCallback onLanguageTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B4D8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.travel_explore, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'VietAI Travel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.language, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Tiếng Việt',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF007BFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  'Powered by AI',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Title
          const Text('Khám phá\nthế giới', style: LoginScreenStyles.heroTitle),
          const Text('cùng AI thông minh', style: LoginScreenStyles.heroTitleAccent),
          const SizedBox(height: 16),
          // Subtitle
          const Text(
            'VietAI Travel đồng hành cùng bạn\ntrên mọi hành trình, mang đến trải nghiệm\ndu lịch thông minh, cá nhân hóa và\nđầy cảm hứng.',
            style: LoginScreenStyles.heroSubtitle,
          ),
          const SizedBox(height: 32),
          // Features
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildFeatureItem(Icons.location_on_outlined, 'Gợi ý thông minh', 'Cá nhân hóa hành trình')),
                    Expanded(child: _buildFeatureItem(Icons.language, 'Khám phá toàn cầu', 'Hàng ngàn điểm đến')),
                    Expanded(child: _buildFeatureItem(Icons.shield_outlined, 'An toàn & Tin cậy', 'Bảo mật tuyệt đối')),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
      ],
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onRegister,
    required this.onForgotPassword,
    required this.onSocialTap,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;
  final VoidCallback onSocialTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Chào mừng trở lại! 👋', style: LoginScreenStyles.panelTitle, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Đăng nhập để tiếp tục hành trình khám phá thế giới\ncùng VietAI Travel.',
              style: LoginScreenStyles.panelSubtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Username (chấp nhận username, email hoặc số điện thoại)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Tên đăng nhập', style: LoginScreenStyles.inputLabel),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: usernameController,
              decoration: LoginScreenStyles.inputDecoration(
                hint: 'Nhập tên đăng nhập, email hoặc số điện thoại',
                prefixIcon: Icons.person_outline,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập thông tin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Password
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('Mật khẩu', style: LoginScreenStyles.inputLabel),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              onFieldSubmitted: (_) => isLoading ? null : onLogin(),
              decoration: LoginScreenStyles.inputDecoration(
                hint: 'Nhập mật khẩu',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94A3B8)),
                  onPressed: onTogglePassword,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('Quên mật khẩu?', style: TextStyle(color: Color(0xFF007BFF), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 24),
            // Login Button
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: LoginScreenStyles.buttonGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Đăng nhập', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            // Divider
            Row(
              children: const [
                Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('hoặc tiếp tục với', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ),
                Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              ],
            ),
            const SizedBox(height: 24),
            // Socials
            OutlinedButton(
              onPressed: onSocialTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png', height: 20),
                  const SizedBox(width: 12),
                  const Text('Tiếp tục với Google', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onSocialTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 24),
                  const SizedBox(width: 12),
                  const Text('Tiếp tục với Facebook', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600, fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Chưa có tài khoản? ', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                GestureDetector(
                  onTap: onRegister,
                  child: const Text('Đăng ký ngay', style: TextStyle(color: Color(0xFF007BFF), fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dialogs remain unchanged
// ─────────────────────────────────────────────────────────────────────────────
class _AuthDialogShell extends StatelessWidget {
  const _AuthDialogShell({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.isSubmitting,
    required this.onSubmit,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: LoginScreenStyles.panelTitle)),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: LoginScreenStyles.panelSubtitle),
              const SizedBox(height: 18),
              child,
              const SizedBox(height: 20),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: isSubmitting
                      ? const LinearGradient(colors: [Color(0xFFB0C4DE), Color(0xFFB0C4DE)])
                      : LoginScreenStyles.buttonGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isSubmitting ? null : onSubmit,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              actionLabel,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: LoginScreenStyles.inputLabel),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction:
              onFieldSubmitted == null ? TextInputAction.next : TextInputAction.done,
          onFieldSubmitted: onFieldSubmitted,
          decoration: LoginScreenStyles.inputDecoration(
            hint: hint,
            prefixIcon: icon,
          ),
          validator: validator,
        ),
      ],
    );
  }
}
