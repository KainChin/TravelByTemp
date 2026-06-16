import 'package:flutter/material.dart';
import 'package:assignment/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final user = await AuthService.signInWithGoogle();
    if (mounted && user == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập thất bại, thử lại nhé!')),
      );
    }
    // Nếu thành công → StreamBuilder trong main.dart tự chuyển sang MainShell
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB8D8E8), Color(0xFFD4E8D4), Color(0xFFA8C8B8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.travel_explore, size: 50, color: Color(0xFF3A7D5A)),
                  ),
                  const SizedBox(height: 24),

                  // Tên app
                  const Text(
                    'TravelByTemp',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lưu giữ mọi khoảnh khắc du lịch',
                    style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
                  ),
                  const SizedBox(height: 48),

                  // Nút Google Sign-In
                  _isLoading
                      ? const CircularProgressIndicator(color: Color(0xFF3A7D5A))
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      icon: Image.network(
                        'https://www.google.com/favicon.ico',
                        width: 20, height: 20,
                        errorBuilder: (_, __, ___) => const Icon(Icons.login, size: 20),
                      ),
                      label: const Text(
                        'Đăng nhập bằng Google',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
