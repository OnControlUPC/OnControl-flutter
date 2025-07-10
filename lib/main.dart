import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/http_client.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/signup_page.dart';
import 'features/patients/presentation/pages/profile_creation_page.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final secureStorage = FlutterSecureStorage();
  final client = createHttpClient();

  final authDS = AuthRemoteDataSourceImpl(
    client: client,
    secureStorage: secureStorage,
  );
  final authRepo = AuthRepositoryImpl(
    remoteDataSource: authDS,
    secureStorage: secureStorage,
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(authRepo)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashPage(),
        '/': (_) => BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                print('▶️ [MyApp] AuthState: $state');
                if (state is AuthLoading) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                } else if (state is AuthAuthenticated) {
                  return const HomePage();
                }
                return const LoginPage();
              },
            ),
        '/signup': (_) => const SignUpPage(),
        '/profile-creation': (ctx) {
          final args =
              ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
          print('▶️ [Router] profile-creation args=$args');
          return ProfileCreationPage(
            userId: args['userId'] as int,
            email: args['email'] as String,
            token: args['token'] as String?,
          );
        },
        '/home': (_) => BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return const HomePage();
            } else {
              return const LoginPage();
            }
          },
        ),
      },
    );
  }
}
