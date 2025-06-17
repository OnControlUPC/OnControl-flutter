// lib/features/auth/presentation/pages/splash_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final keep  = prefs.getBool('keepSignedIn') ?? false;
    final token = await _secureStorage.read(key: 'token');

    debugPrint('🔍 keepSignedIn=$keep, token=$token');

    if (keep && token != null && token.isNotEmpty) {
      // → Va a Home y elimina TODO el historial de navegación
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      // → Va a Login y elimina TODO el historial de navegación
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
