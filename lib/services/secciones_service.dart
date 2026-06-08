// lib/services/secciones_service.dart
// Guarda y carga las secciones de la hoja de terreno en Firestore.
// Ruta: hojas_terreno/{hojaId}/secciones/{radiografica|fabricacion|hermeticidad|recubrimiento}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inspeccion_radiografica.dart';
import '../models/inspeccion_fabricacion.dart';
import '../models/prueba_hermeticidad.dart';
import '../models/inspeccion_recubrimiento.dart';
import '../models/verificacion_accesorios.dart';
import '../models/placa_identificacion.dart';

class SeccionesService {
  static final _db = FirebaseFirestore.instance;

  static DocumentReference _doc(String hojaId, String seccion) => _db
      .collection('hojas_terreno').doc(hojaId)
      .collection('secciones').doc(seccion);

  // ── 1. RADIOGRÁFICA ─────────────────────────────────────────────────────────
  static Future<InspeccionRadiografica> cargarRadiografica(String hojaId) async {
    try {
      final doc = await _doc(hojaId, 'radiografica').get();
      if (!doc.exists) return const InspeccionRadiografica();
      return InspeccionRadiografica.fromMap(doc.data() as Map<String, dynamic>);
    } catch (_) { return const InspeccionRadiografica(); }
  }

  static Future<String?> guardarRadiografica(String hojaId, InspeccionRadiografica d) async {
    try { await _doc(hojaId, 'radiografica').set(d.toMap()); return null; }
    catch (e) { return 'Error al guardar la inspección radiográfica.'; }
  }

  // ── 2. FABRICACIÓN ────────────────────────────────────────────────────────────
  static Future<InspeccionFabricacion> cargarFabricacion(String hojaId) async {
    try {
      final doc = await _doc(hojaId, 'fabricacion').get();
      if (!doc.exists) return const InspeccionFabricacion();
      return InspeccionFabricacion.fromMap(doc.data() as Map<String, dynamic>);
    } catch (_) { return const InspeccionFabricacion(); }
  }

  static Future<String?> guardarFabricacion(String hojaId, InspeccionFabricacion d) async {
    try { await _doc(hojaId, 'fabricacion').set(d.toMap()); return null; }
    catch (e) { return 'Error al guardar la inspección de fabricación.'; }
  }

  // ── 3. HERMETICIDAD ───────────────────────────────────────────────────────────
  static Future<PruebaHermeticidad> cargarHermeticidad(String hojaId) async {
    try {
      final doc = await _doc(hojaId, 'hermeticidad').get();
      if (!doc.exists) return const PruebaHermeticidad();
      return PruebaHermeticidad.fromMap(doc.data() as Map<String, dynamic>);
    } catch (_) { return const PruebaHermeticidad(); }
  }

  static Future<String?> guardarHermeticidad(String hojaId, PruebaHermeticidad d) async {
    try { await _doc(hojaId, 'hermeticidad').set(d.toMap()); return null; }
    catch (e) { return 'Error al guardar la prueba de hermeticidad.'; }
  }

  // ── 4. RECUBRIMIENTO ──────────────────────────────────────────────────────────
  static Future<InspeccionRecubrimiento> cargarRecubrimiento(String hojaId) async {
    try {
      final doc = await _doc(hojaId, 'recubrimiento').get();
      if (!doc.exists) return const InspeccionRecubrimiento();
      return InspeccionRecubrimiento.fromMap(doc.data() as Map<String, dynamic>);
    } catch (_) { return const InspeccionRecubrimiento(); }
  }

  static Future<String?> guardarRecubrimiento(String hojaId, InspeccionRecubrimiento d) async {
    try { await _doc(hojaId, 'recubrimiento').set(d.toMap()); return null; }
    catch (e) { return 'Error al guardar la inspección de recubrimiento.'; }
  }

  // ── 5. VERIFICACIÓN ACCESORIOS ─────────────────────────────────────────────────
  static Future<VerificacionAccesorios> cargarAccesorios(String hojaId) async {
    try {
      final doc = await _doc(hojaId, 'accesorios').get();
      if (!doc.exists) return const VerificacionAccesorios();
      return VerificacionAccesorios.fromMap(doc.data() as Map<String, dynamic>);
    } catch (_) { return const VerificacionAccesorios(); }
  }

  static Future<String?> guardarAccesorios(String hojaId, VerificacionAccesorios d) async {
    try { await _doc(hojaId, 'accesorios').set(d.toMap()); return null; }
    catch (e) { return 'Error al guardar la verificación de accesorios.'; }
  }

  // ── 6. PLACA DE IDENTIFICACIÓN ──────────────────────────────────────────────────
  static Future<PlacaIdentificacion> cargarPlaca(String hojaId) async {
    try {
      final doc = await _doc(hojaId, 'placa').get();
      if (!doc.exists) return const PlacaIdentificacion();
      return PlacaIdentificacion.fromMap(doc.data() as Map<String, dynamic>);
    } catch (_) { return const PlacaIdentificacion(); }
  }

  static Future<String?> guardarPlaca(String hojaId, PlacaIdentificacion d) async {
    try { await _doc(hojaId, 'placa').set(d.toMap()); return null; }
    catch (e) { return 'Error al guardar la placa de identificación.'; }
  }

  // ── GUARDAR TODAS (modo creación) ─────────────────────────────────────────────
  static Future<void> guardarTodas({
    required String hojaId,
    required InspeccionRadiografica radiografica,
    required InspeccionFabricacion fabricacion,
    required PruebaHermeticidad hermeticidad,
    required InspeccionRecubrimiento recubrimiento,
    required VerificacionAccesorios accesorios,
    required PlacaIdentificacion placa,
  }) async {
    await Future.wait([
      if (radiografica.tieneContenido)  guardarRadiografica(hojaId, radiografica),
      if (fabricacion.tieneContenido)   guardarFabricacion(hojaId, fabricacion),
      if (hermeticidad.tieneContenido)  guardarHermeticidad(hojaId, hermeticidad),
      if (recubrimiento.tieneContenido) guardarRecubrimiento(hojaId, recubrimiento),
      if (accesorios.tieneContenido)    guardarAccesorios(hojaId, accesorios),
      if (placa.tieneContenido)         guardarPlaca(hojaId, placa),
    ]);
  }
}
