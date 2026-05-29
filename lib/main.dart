import 'package:flutter/material.dart';
import 'package:assignment/core/theme/app_theme.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/screens/auth/login_screen.dart';
import 'package:assignment/screens/main_shell.dart';
import 'package:assignment/services/app_session.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TravelApp());
}

class TravelApp extends StatefulWidget {
  const TravelApp({super.key});

  @override
  State<TravelApp> createState() => _TravelAppState();
}

class _TravelAppState extends State<TravelApp> {
  final _session = AppSession();
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _session.restore();
    if (_session.isLoggedIn) {
      await _session.refreshLocationAndWeather();
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return VietaiScope(
      session: _session,
      child: ListenableBuilder(
        listenable: _session,
        builder: (context, _) {
          return MaterialApp(
            title: 'VietAI Travel',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: _session.isLoggedIn
                ? const MainShell()
                : LoginScreen(session: _session),
          );
        },
      ),
    );
  }
}
