import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/hojas_list_screen.dart';
import 'screens/hoja_terreno_form_screen.dart';
import 'screens/croquis_screen.dart';
import 'screens/buscar_hojas_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── Persistencia offline de Firestore ──────────────────────────────────────
  // El inspector puede leer, crear y editar hojas sin conexión; Firestore
  // sincroniza automáticamente cuando vuelve el internet.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
      ),
      home: const AuthGate(),
      routes: {
        '/login':         (context) => const LoginScreen(),
        '/register':      (context) => const RegisterScreen(),
        '/home':          (context) => const HomeScreen(),
        '/profile':       (context) => const ProfileScreen(),
        '/hojas':         (context) => const HojasListScreen(),
        '/buscar':        (context) => const BuscarHojasScreen(),
        '/hojas/nueva':   (context) => const HojaTerrenoFormScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 64, color: Color(0xFF6C63FF)),
            SizedBox(height: 24),
            SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
