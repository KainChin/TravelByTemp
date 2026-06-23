import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/firebase_options.dart';
import 'package:assignment/screens/auth/login_screen.dart';
import 'package:assignment/screens/main_shell.dart';
import 'package:assignment/services/app_session.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final session = AppSession();
  await session.restore();

  runApp(
    VietaiScope(
      session: session,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = VietaiScope.of(context);
    final user = session.auth?.user;

    return MaterialApp(
      title: 'VietAI Travel',
      debugShowCheckedModeBanner: false,
      home: user == null
          ? const LoginScreen()
          : MainShell(currentUserName: user.fullName),
    );
  }
}
