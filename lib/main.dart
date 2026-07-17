import 'package:flutter/material.dart';
import 'mainshell/main_shell.dart';
import 'Login/screens/login_page 1.dart';
import 'am_masters/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.getInstance();
  runApp(const MicroFinanceApp());
}

class MicroFinanceApp extends StatelessWidget {
  const MicroFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Micro Finance',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E2640)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/dashboard': (context) => const MainShell(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
