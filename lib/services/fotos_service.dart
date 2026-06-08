// lib/services/fotos_service.dart
// Sube, carga y elimina fotos de una Hoja de Terreno.
// MULTIPLATAFORMA: funciona en Web y en móvil (Android/iOS).
//
// En móvil: comprime con flutter_image_compress antes de subir.
// En Web: sube los bytes directamente (la compresión nativa no existe en navegador).
//
// Estructura en Storage: hoja_fotos/{hojaId}/foto_0.jpg ... foto_5.jpg
// URLs guardadas en Firestore: hojas_terreno/{hojaId} → campo "fotos": [...]

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FotosService {
  static const int maxFotos = 6;
  static const int maxKilobytes = 200;

  static final _db      = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static DocumentReference _hojaDoc(String hojaId) =>
      _db.collection('hojas_terreno').doc(hojaId);

  // ─── Obtener URLs actuales ──────────────────────────────────────────────────
  static Future<List<String>> obtenerUrls(String hojaId) async {
    final doc = await _hojaDoc(hojaId).get();
    if (!doc.exists) return [];
    final data = doc.data() as Map<String, dynamic>;
    final lista = data['fotos'] as List<dynamic>? ?? [];
    return lista.cast<String>();
  }

  static Stream<List<String>> urlsStream(String hojaId) {
    return _hojaDoc(hojaId).snapshots().map((doc) {
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>;
      return (data['fotos'] as List<dynamic>? ?? []).cast<String>();
    });
  }

  // ─── SUBIR una foto (recibe BYTES, no File) ────────────────────────────────
  // Trabajar con bytes funciona igual en Web y móvil.
  static Future<String?> subirFoto({
    required String hojaId,
    required Uint8List bytes,
    required int indice, // 0..5
  }) async {
    try {
      // Comprimir solo en móvil; en Web subimos los bytes tal cual
      Uint8List aSubir = bytes;
      if (!kIsWeb) {
        try {
          final comprimida = await FlutterImageCompress.compressWithList(
            bytes,
            quality: 70,
            minWidth: 1024,
            minHeight: 1024,
            format: CompressFormat.jpeg,
          );
          // Si el resultado es válido y más pequeño, lo usamos
          if (comprimida.isNotEmpty) aSubir = comprimida;
        } catch (_) {
          aSubir = bytes; // fallback: subir sin comprimir
        }
      }

      // Subir a Storage con putData (funciona en Web y móvil)
      final ref = _storage.ref().child('hoja_fotos/$hojaId/foto_$indice.jpg');
      await ref.putData(
        aSubir,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await ref.getDownloadURL();

      // Actualizar lista de URLs en Firestore
      final urls = await obtenerUrls(hojaId);
      while (urls.length <= indice) urls.add('');
      urls[indice] = url;
      await _hojaDoc(hojaId).update({'fotos': urls});

      return null; // ✅ éxito
    } catch (e) {
      return 'Error al subir la foto: $e';
    }
  }

  // ─── ELIMINAR una foto ──────────────────────────────────────────────────────
  static Future<String?> eliminarFoto({
    required String hojaId,
    required int indice,
  }) async {
    try {
      final ref = _storage.ref().child('hoja_fotos/$hojaId/foto_$indice.jpg');
      await ref.delete().catchError((_) {});

      final urls = await obtenerUrls(hojaId);
      if (indice < urls.length) {
        urls.removeAt(indice);
        await _hojaDoc(hojaId).update({'fotos': urls});
      }
      return null;
    } catch (e) {
      return 'Error al eliminar la foto: $e';
    }
  }
}
