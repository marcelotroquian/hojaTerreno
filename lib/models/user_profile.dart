// lib/models/user_profile.dart
// Modelo que representa el perfil de un usuario en Firestore

class UserProfile {
  final String uid;         // ID único del usuario (viene de Firebase Auth)
  final String name;        // Nombre completo
  final String email;       // Correo electrónico
  final String bio;         // Descripción personal
  final String? photoUrl;   // URL de la foto (null si no tiene)
  final DateTime createdAt; // Fecha de creación del perfil

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.bio,
    required this.createdAt,
    this.photoUrl,
  });

  // ─── Crear desde un documento de Firestore ──────────────────────────────
  // Firestore devuelve un Map<String, dynamic>, este factory lo convierte
  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      bio: data['bio'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  // ─── Convertir a Map para guardar en Firestore ───────────────────────────
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'bio': bio,
      'photoUrl': photoUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // ─── Crear una copia con campos modificados ──────────────────────────────
  // Útil para actualizar solo algunos campos sin tocar los demás
  UserProfile copyWith({
    String? name,
    String? bio,
    String? photoUrl,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      createdAt: createdAt,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
