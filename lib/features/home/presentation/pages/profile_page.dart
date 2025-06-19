import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    print('🔔 [ProfilePage] Logout iniciado');
    // borra el token de storage
    await const FlutterSecureStorage().delete(key: 'token');
    // dispara evento de logout para limpiar estado
    context.read<AuthBloc>().add(const AuthLogoutRequested());
    // navega a login
    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    // podrías leer aquí de storage o de tu BLoC más datos del usuario
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ejemplo: muestra el username y el id desde el estado BLoC
            BlocBuilder<AuthBloc, dynamic>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Usuario: ${state.user.username}',
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('ID: ${state.user.id}',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
