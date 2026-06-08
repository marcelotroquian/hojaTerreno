// lib/services/hoja_terreno_service.dart
// CRUD de Hojas de Terreno en Firestore
// Reglas de acceso:
//   - Crear:   cualquier usuario autenticado
//   - Leer:    cualquier usuario autenticado
//   - Editar:  cualquier usuario autenticado
//   - Eliminar: solo el usuario que la creó

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hoja_terreno.dart';

class HojaTerrenoService {
  static final _db = FirebaseFirestore.instance;

  // Referencia a la colección "hojas_terreno"
  static CollectionReference get _col => _db.collection('hojas_terreno');

  // ─── CREAR ─────────────────────────────────────────────────────────────────
  static Future<String?> crear({
    required String uid,
    required String nombreUsuario,
    required HojaTerreno datos,
  }) async {
    try {
      // Construimos el objeto completo con los metadatos de creación
      final hoja = HojaTerreno(
        id: '',                           // Firestore lo genera solo
        creadaPor: uid,
        creadaPorNombre: nombreUsuario,
        creadaEn: DateTime.now(),
        modificadaEn: DateTime.now(),
        tanqueNumero: datos.tanqueNumero,
        serieNumero: datos.serieNumero,
        certificadoNumero: datos.certificadoNumero,
        patenteNumero: datos.patenteNumero,
        planoNumero: datos.planoNumero,
        cliente: datos.cliente,
        capacidad: datos.capacidad,
        tipoInspeccion: datos.tipoInspeccion,
        normaAplicada: datos.normaAplicada,
        protocoloNumero: datos.protocoloNumero,
      );

      // add() genera un ID único automáticamente
      await _col.add(hoja.toFirestore());
      return null; // null = éxito ✅
    } catch (e) {
      return 'Error al crear la hoja. Intenta de nuevo.';
    }
  }

  // ─── LEER TODAS (Stream en tiempo real) ───────────────────────────────────
  // Cualquier usuario autenticado puede ver todas las hojas
  // Ordenadas por fecha de modificación (más reciente primero)
  static Stream<List<HojaTerreno>> listarTodas() {
    return _col
        .orderBy('modificadaEn', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HojaTerreno.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  // ─── LEER UNA ──────────────────────────────────────────────────────────────
  static Stream<HojaTerreno?> escuchar(String id) {
    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return HojaTerreno.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    });
  }

  // ─── ACTUALIZAR ────────────────────────────────────────────────────────────
  // Cualquier usuario autenticado puede editar (la pantalla controla permisos de UI)
  // La regla de "solo el creador elimina" se aplica en Firestore Rules
  static Future<String?> actualizar({
    required String id,
    required HojaTerreno datos,
  }) async {
    try {
      final map = datos.toFirestore();
      // Siempre actualizamos modificadaEn al guardar
      map['modificadaEn'] = DateTime.now().millisecondsSinceEpoch;

      // update() solo modifica los campos indicados
      await _col.doc(id).update(map);
      return null; // null = éxito ✅
    } catch (e) {
      return 'Error al guardar los cambios.';
    }
  }

  // ─── ELIMINAR ──────────────────────────────────────────────────────────────
  // Solo el creador puede hacerlo (también reforzado en Firestore Rules)
  static Future<String?> eliminar(String id) async {
    try {
      await _col.doc(id).delete();
      return null; // null = éxito ✅
    } catch (e) {
      return 'No tienes permiso para eliminar esta hoja.';
    }
  }
}
