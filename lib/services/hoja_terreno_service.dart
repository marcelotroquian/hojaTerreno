// lib/services/hoja_terreno_service.dart
// CRUD de Hojas de Terreno en Firestore + generación de código HDT correlativo.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hoja_terreno.dart';

class HojaTerrenoService {
  static final _db = FirebaseFirestore.instance;
  static CollectionReference get _col => _db.collection('hojas_terreno');

  // Documento que guarda los contadores por año: contadores/hdt
  // Estructura: { "2026": 5, "2025": 120, ... }
  static DocumentReference get _contadorDoc =>
      _db.collection('contadores').doc('hdt');

  // ─── Generar el siguiente código HDT con transacción atómica ──────────────
  // Usa una transacción para que dos usuarios creando a la vez NO obtengan
  // el mismo número. Formato: HDT-2026-0001
  static Future<String> _generarCodigo() async {
    final anio = DateTime.now().year.toString();

    final codigo = await _db.runTransaction<String>((tx) async {
      final snap = await tx.get(_contadorDoc);

      int actual = 0;
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        actual = (data[anio] ?? 0) as int;
      }

      final siguiente = actual + 1;

      // Guardar el contador actualizado (merge para no borrar otros años)
      tx.set(_contadorDoc, {anio: siguiente}, SetOptions(merge: true));

      // Formatear: HDT-2026-0001 (4 dígitos con ceros a la izquierda)
      final numero = siguiente.toString().padLeft(4, '0');
      return 'HDT-$anio-$numero';
    });

    return codigo;
  }

  // ─── CREAR — genera código HDT y devuelve el ID del documento ─────────────
  // Retorna (hojaId, codigoHDT) si OK, o (null, mensajeError) si falla.
  static Future<(String?, String?)> crear({
    required String uid,
    required String nombreUsuario,
    required HojaTerreno datos,
  }) async {
    try {
      // 1. Generar código correlativo
      final codigo = await _generarCodigo();

      // 2. Construir la hoja con el código incluido
      final hoja = HojaTerreno(
        id: '',
        codigoHDT: codigo,
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

      // 3. Crear el documento; add() genera el ID
      final ref = await _col.add(hoja.toFirestore());
      return (ref.id, codigo); // devolvemos id real + código legible
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

  // ─── BUSCAR por código HDT ────────────────────────────────────────────────
  // Busca coincidencia exacta o parcial (insensible a mayúsculas).
  static Future<List<HojaTerreno>> buscarPorCodigo(String query) async {
    final q = query.trim().toUpperCase();
    if (q.isEmpty) return [];

    try {
      // Traemos todas y filtramos en cliente (la colección no es enorme).
      // Para colecciones muy grandes convendría un índice, pero así es simple y flexible.
      final snap = await _col.get();
      final todas = snap.docs
          .map((d) => HojaTerreno.fromFirestore(d.data() as Map<String, dynamic>, d.id))
          .toList();

      return todas.where((h) {
        final codigo = h.codigoHDT.toUpperCase();
        final tanque = h.tanqueNumero.toUpperCase();
        final cliente = h.cliente.toUpperCase();
        // Coincide si el código, el tanque o el cliente contienen la búsqueda
        return codigo.contains(q) || tanque.contains(q) || cliente.contains(q);
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
