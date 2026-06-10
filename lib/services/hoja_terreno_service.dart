// lib/services/hoja_terreno_service.dart
// CRUD de Hojas de Terreno en Firestore.
// (El código HDT se removió por ahora; se usa el ID interno de Firestore.)

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hoja_terreno.dart';

class HojaTerrenoService {
  static final _db = FirebaseFirestore.instance;
  static CollectionReference get _col => _db.collection('hojas_terreno');

  // ─── CREAR — funciona online y offline ─────────────────────────────────────
  // Con persistencia offline, la escritura se encola localmente y se sincroniza
  // sola al recuperar conexión. Devuelve el ID del documento.
  static Future<(String?, String?)> crear({
    required String uid,
    required String nombreUsuario,
    required HojaTerreno datos,
  }) async {
    try {
      final hoja = HojaTerreno(
        id: '',
        creadaPor: uid,
        creadaPorNombre: nombreUsuario,
        creadaEn: DateTime.now(),
        modificadaEn: DateTime.now(),
        tanqueNumero:      datos.tanqueNumero,
        serieNumero:       datos.serieNumero,
        certificadoNumero: datos.certificadoNumero,
        patenteNumero:     datos.patenteNumero,
        planoNumero:       datos.planoNumero,
        cliente:           datos.cliente,
        maestranza:        datos.maestranza,
        capacidad:         datos.capacidad,
        material:          datos.material,
        tipoInspeccion:    datos.tipoInspeccion,
        certificadoAnterior: datos.certificadoAnterior,
        normaAplicada:     datos.normaAplicada,
        protocoloNumero:   datos.protocoloNumero,
        numeroChassisVin:  datos.numeroChassisVin,
        patenteVehiculo:   datos.patenteVehiculo,
        tiposTanque:       datos.tiposTanque,
      );

      // doc() genera el ID localmente sin red; set() se encola y sincroniza solo.
      final ref = _col.doc();
      ref.set(hoja.toFirestore());
      return (ref.id, null);
    } catch (e) {
      return (null, 'Error al crear la hoja: $e');
    }
  }

  // ─── LEER TODAS (Stream en tiempo real) ───────────────────────────────────
  static Stream<List<HojaTerreno>> listarTodas() {
    return _col
        .orderBy('modificadaEn', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => HojaTerreno.fromFirestore(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // ─── BUSCAR por número de tanque o cliente ────────────────────────────────
  static Future<List<HojaTerreno>> buscarPorCodigo(String query) async {
    final q = query.trim().toUpperCase();
    if (q.isEmpty) return [];

    try {
      final snap = await _col.get();
      final todas = snap.docs
          .map((d) => HojaTerreno.fromFirestore(d.data() as Map<String, dynamic>, d.id))
          .toList();

      return todas.where((h) {
        final tanque = h.tanqueNumero.toUpperCase();
        final cliente = h.cliente.toUpperCase();
        final serie = h.serieNumero.toUpperCase();
        return tanque.contains(q) || cliente.contains(q) || serie.contains(q);
      }).toList()
        ..sort((a, b) => b.creadaEn.compareTo(a.creadaEn));
    } catch (e) {
      return [];
    }
  }

  // ─── LEER UNA (Stream) ────────────────────────────────────────────────────
  static Stream<HojaTerreno?> escuchar(String id) {
    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return HojaTerreno.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  // ─── ACTUALIZAR ───────────────────────────────────────────────────────────
  static Future<String?> actualizar({required String id, required HojaTerreno datos}) async {
    try {
      final map = datos.toFirestore();
      map['modificadaEn'] = DateTime.now().millisecondsSinceEpoch;
      await _col.doc(id).update(map);
      return null;
    } catch (e) {
      return 'Error al guardar los cambios.';
    }
  }

  // ─── ELIMINAR (solo el creador) ───────────────────────────────────────────
  static Future<String?> eliminar(String id) async {
    try {
      await _col.doc(id).delete();
      return null;
    } catch (e) {
      return 'No tienes permiso para eliminar esta hoja.';
    }
  }
}
