// lib/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/features/auth/presentation/bloc/auth_bloc.dart';
import '/features/auth/presentation/bloc/auth_event.dart';
import '/features/auth/presentation/bloc/auth_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    // 1) Dispara el evento de logout
    context.read<AuthBloc>().add(AuthLogoutRequested());
    // 2) Limpia storage y prefs
    final secure = const FlutterSecureStorage();
    await secure.delete(key: 'token');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('keepSignedIn');
    // 3) Navega a login
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthUnauthenticated) {
          Navigator.pushReplacementNamed(ctx, '/');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inicio'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: const Center(
          child: Text(
            '¡Bienvenido a tu HomePage!',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
