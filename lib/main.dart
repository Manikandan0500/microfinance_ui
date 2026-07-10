import 'package:flutter/material.dart';
import 'mainshell/main_shell.dart';

void main() {
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
      home: const MainShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
