// lib/services/profile_service.dart
// Servicio para leer y escribir el perfil del usuario en Firestore

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_profile.dart';

class ProfileService {
  // Instancias de Firestore y Storage
  static final _db = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  // Referencia a la colección "users" en Firestore
  // Estructura: users/{uid}/  → documento del perfil
  static CollectionReference get _usersCol => _db.collection('users');

  // ─── CREAR perfil al registrarse ──────────────────────────────────────────
  // Se llama una sola vez cuando el usuario se registra por primera vez
  static Future<void> createProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    final profile = UserProfile(
      uid: uid,
      name: name,
      email: email,
      bio: '',
      createdAt: DateTime.now(),
    );

    // set() crea el documento si no existe, o lo sobreescribe si ya existe
    await _usersCol.doc(uid).set(profile.toFirestore());
  }

  // ─── LEER perfil ──────────────────────────────────────────────────────────
  // Retorna null si el perfil no existe aún
  static Future<UserProfile?> getProfile(String uid) async {
    final doc = await _usersCol.doc(uid).get();

    if (!doc.exists) return null;

    return UserProfile.fromFirestore(
      doc.data() as Map<String, dynamic>,
      uid,
    );
  }

  // ─── ESCUCHAR perfil en tiempo real (Stream) ──────────────────────────────
  // Se actualiza automáticamente cuando cambian los datos en Firestore
  static Stream<UserProfile?> profileStream(String uid) {
    return _usersCol.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(
        doc.data() as Map<String, dynamic>,
        uid,
      );
    });
  }

  // ─── ACTUALIZAR nombre y bio ──────────────────────────────────────────────
  // update() solo modifica los campos indicados, no toca el resto
  static Future<String?> updateProfile({
    required String uid,
    required String name,
    required String bio,
  }) async {
    try {
      await _usersCol.doc(uid).update({
        'name': name.trim(),
        'bio': bio.trim(),
      });
      return null; // null = éxito ✅
    } catch (e) {
      return 'Error al actualizar el perfil. Intenta de nuevo.';
    }
  }

  // ─── SUBIR foto de perfil ─────────────────────────────────────────────────
  // 1. Sube la imagen a Firebase Storage
  // 2. Obtiene la URL pública
  // 3. Guarda la URL en Firestore
  static Future<String?> uploadProfilePhoto({
    required String uid,
    required Uint8List bytes,
  }) async {
    try {
      // Referencia en Storage: profile_photos/{uid}.jpg
      final ref = _storage.ref().child('profile_photos/$uid.jpg');

      // putData funciona en Web y móvil (a diferencia de putFile)
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Obtener URL de descarga pública
      final downloadUrl = await ref.getDownloadURL();

      // Guardar URL en el documento de Firestore
      await _usersCol.doc(uid).update({'photoUrl': downloadUrl});

      return null; // null = éxito ✅
    } catch (e) {
      return 'Error al subir la foto: $e';
    }
  }
}
