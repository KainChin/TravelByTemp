import 'package:flutter/material.dart';
import 'package:assignment/screens/main_shell.dart';

// ── Thêm 2 import Firebase ──
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ── Thêm thêm cho Google Sign-In ──
import 'package:firebase_auth/firebase_auth.dart';
import 'package:assignment/services/auth_service.dart';
import 'package:assignment/screens/auth/login_screen.dart';

// ── Thêm async + await Firebase.initializeApp ──
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // đảm bảo Flutter init trước
  await Firebase.initializeApp(             // khởi tạo Firebase
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── [DEBUG] Tự động đăng nhập ẩn danh để test UI ──
  // Xóa đoạn này khi build production
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VietAI Travel',
      debugShowCheckedModeBanner: false,
      // ── Tự động chuyển Login ↔ MainShell theo trạng thái đăng nhập ──
      home: StreamBuilder<User?>(
        stream: AuthService.authStateChanges,
        builder: (context, snapshot) {
          // Đang kiểm tra → hiện loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;

          // Chưa đăng nhập → màn hình login
          if (!snapshot.hasData || user == null) {
            return const LoginScreen();
          }

          // Đã đăng nhập → vào app, truyền tên người dùng cho MainShell.
          // displayName sẽ null với tài khoản ẩn danh (anonymous) hoặc một số
          // tài khoản email/password chưa cập nhật hồ sơ — fallback sang
          // phần trước @ của email, cuối cùng là "Bạn".
          final currentUserName = user.displayName?.trim().isNotEmpty == true
              ? user.displayName!
              : (user.email?.split('@').first ?? 'Bạn');

          return MainShell(currentUserName: currentUserName);
        },
      ),
    );
  }
}