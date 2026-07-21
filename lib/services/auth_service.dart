// lib/services/auth_service.dart
// Servicio de autenticación con Firebase Auth + crea perfil en Firestore

import 'package:firebase_auth/firebase_auth.dart';
import 'profile_service.dart'; // ← nuevo import

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── REGISTRO ─────────────────────────────────────────────────────────────
  static Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Crear usuario en Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 2. Guardar nombre en el perfil de Auth
      await credential.user?.updateDisplayName(name.trim());

      // 3. Crear documento en Firestore con los datos del perfil
      //    Esto es lo nuevo: guardamos en la colección "users"
      if (credential.user != null) {
        await ProfileService.createProfile(
          uid: credential.user!.uid,
          name: name.trim(),
          email: email.trim(),
        );
      }

      // 4. Enviar email de verificación
      await credential.user?.sendEmailVerification();

      return null; // null = éxito

    } on FirebaseAuthException catch (e) {
      return _traducirError(e.code);
    } catch (e) {
      return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
  }

  // ─── LOGIN ────────────────────────────────────────────────────────────────
  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _traducirError(e.code);
    } catch (e) {
      return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
  }

  // ─── CERRAR SESIÓN ────────────────────────────────────────────────────────
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ─── RECUPERAR CONTRASEÑA ─────────────────────────────────────────────────
  static Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _traducirError(e.code);
    }
  }

  // ─── Traducir códigos de error de Firebase al español ─────────────────────
  static String _traducirError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'invalid-email':
        return 'El formato del correo es inválido.';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Espera un momento.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red.';
      default:
        return 'Error: $code. Intenta de nuevo.';
    }
  }
}
