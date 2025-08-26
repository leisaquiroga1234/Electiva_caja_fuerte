import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'services/lock_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Prevent screenshots / recents preview on Android
  try {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  } catch (_) {}
  await LockManager.instance.init();
  runApp(const CajaSeguraApp());
}

class CajaSeguraApp extends StatefulWidget {
  const CajaSeguraApp({super.key});

  @override
  State<CajaSeguraApp> createState() => _CajaSeguraAppState();
}

class _CajaSeguraAppState extends State<CajaSeguraApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caja Segura',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: '/lock',
      routes: {
        '/lock': (_) => const LockScreen(),
        '/home': (_) => const HomeScreen(),
      },
    );
  }
}