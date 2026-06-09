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
  // Requiere conexión (la transacción contacta el servidor). Si no hay conexión,
  // lanza una excepción que el llamador captura para usar un código BORRADOR.
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
      tx.set(_contadorDoc, {anio: siguiente}, SetOptions(merge: true));

      final numero = siguiente.toString().padLeft(4, '0');
      return 'HDT-$anio-$numero';
    }).timeout(
      // Si en 8s no responde el servidor, asumimos que no hay conexión
      const Duration(seconds: 8),
    );

    return codigo;
  }

  // ─── CREAR — funciona online y offline ─────────────────────────────────────
  // Online:  genera HDT-2026-xxxx real y sincronizada=true.
  // Offline: usa código BORRADOR-{timestamp} y sincronizada=false; el código
  //          real se asigna después con sincronizarPendientes().
  // Retorna (hojaId, codigoHDT) siempre (nunca falla por falta de conexión).
  static Future<(String?, String?)> crear({
    required String uid,
    required String nombreUsuario,
    required HojaTerreno datos,
  }) async {
    // Intentamos generar el código real; si no hay conexión, usamos BORRADOR
    String codigo;
    bool sincronizada;
    try {
      codigo = await _generarCodigo();
      sincronizada = true;
    } catch (_) {
      // Sin conexión (o timeout): código temporal local
      codigo = 'BORRADOR-${DateTime.now().millisecondsSinceEpoch}';
      sincronizada = false;
    }

    final hoja = HojaTerreno(
      id: '',
      codigoHDT: codigo,
      sincronizada: sincronizada,
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

    // IMPORTANTE: con persistencia offline, NO usamos await en el add cuando
    // estamos offline (nunca completa). Usamos el DocumentReference que se crea
    // inmediatamente en la caché local, y dejamos que Firestore sincronice solo.
    try {
      final ref = _col.doc(); // genera ID localmente, sin red
      // No hacemos await: la escritura se encola y se sincroniza sola.
      // En la caché local queda disponible al instante.
      ref.set(hoja.toFirestore());
      return (ref.id, codigo);
    } catch (e) {
      return (null, 'Error al crear la hoja: $e');
    }
  }

  // ─── SINCRONIZAR hojas en BORRADOR ─────────────────────────────────────────
  // Recorre las hojas con sincronizada=false y les asigna el código HDT real.
  // Llamar cuando se detecte conexión (al abrir la app, al entrar a la lista).
  // Devuelve cuántas hojas sincronizó.
  static Future<int> sincronizarPendientes() async {
    try {
      // Buscamos pendientes desde el SERVIDOR (no caché) para confirmar conexión
      final snap = await _col
          .where('sincronizada', isEqualTo: false)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 8));

      int contador = 0;
      for (final doc in snap.docs) {
        try {
          final codigoReal = await _generarCodigo();
          await doc.reference.update({
            'codigoHDT': codigoReal,
            'sincronizada': true,
          });
          contador++;
        } catch (_) {
          // Si falla una, seguimos con las demás
        }
      }
      return contador;
    } catch (_) {
      // Sin conexión: no hay nada que sincronizar ahora
      return 0;
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
