// lib/features/auth/presentation/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../data/models/user_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl   = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();

  bool _obscurePassword = true;
  bool _keepSignedIn    = false;
  bool _shownSnack      = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_shownSnack) {
      final msg = ModalRoute.of(context)?.settings.arguments;
      if (msg is String) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        });
        _shownSnack = true;
      }
    }
  }

  Future<void> _onLoginSuccess(UserModel user) async {
    // Persistir token y preferencia al vuelo
    await _secureStorage.write(key: 'token', value: user.token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keepSignedIn', _keepSignedIn);
    debugPrint('✅ Saved -> keepSignedIn=$_keepSignedIn; token=${user.token}');
    // Navegar a Home y limpiar stack
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
        automaticallyImplyLeading: false,  // ← quita la flecha
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (ctx, state) {
          if (state is AuthAuthenticated) {
            _onLoginSuccess(state.user as UserModel);
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(ctx)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (ctx, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _userCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Usuario o correo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Mantener sesión iniciada'),
                  value: _keepSignedIn,
                  onChanged: (v) => setState(() => _keepSignedIn = v!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(
                          AuthLoginRequested(
                            _userCtrl.text,
                            _passCtrl.text,
                          ),
                        );
                  },
                  child: const Text('Entrar'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
