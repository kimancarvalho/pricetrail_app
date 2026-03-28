import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PriceTrailApp());
}

class PriceTrailApp extends StatelessWidget {
  const PriceTrailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PriceTrail',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      // StreamBuilder ouve o estado de autenticação do Firebase
      // e decide qual ecrã mostrar automaticamente
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Firebase ainda a inicializar
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Utilizador autenticado → vai para a app
          if (snapshot.hasData) {
            return const MainScreen();
          }

          // Utilizador não autenticado → vai para o login
          return const LoginScreen();
        },
      ),
    );
  }
}
