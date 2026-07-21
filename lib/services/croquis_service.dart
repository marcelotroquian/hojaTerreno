// lib/services/croquis_service.dart
// Guarda y carga el croquis completo en Firestore: trazos + datos de cabecera/pie
// Ruta: hojas_terreno/{hojaId}/croquis/data

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/canvas_element.dart';
import '../models/croquis_datos.dart';

class CroquisService {
  static final _db = FirebaseFirestore.instance;

  static DocumentReference _doc(String hojaId) => _db
      .collection('hojas_terreno')
      .doc(hojaId)
      .collection('croquis')
      .doc('data');

  // ─── GUARDAR elementos + datos ────────────────────────────────────────────
  static Future<String?> guardar({
    required String hojaId,
    required List<ElementoCanvas> elementos,
    CroquisDatos? datos,
  }) async {
    try {
      await _doc(hojaId).set({
        'elementos': elementos.map((e) => e.toMap()).toList(),
        if (datos != null) 'datos': datos.toMap(),
        'actualizadoEn': DateTime.now().millisecondsSinceEpoch,
      });
      return null; // null = éxito
    } catch (e) {
      // Mostramos el detalle real para diagnosticar
      return 'Error al guardar el croquis: $e';
    }
  }

  // ─── CARGAR elementos ──────────────────────────────────────────────────────
  static Future<List<ElementoCanvas>> cargar(String hojaId) async {
    try {
      final doc = await _doc(hojaId).get();
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>;
      final lista = data['elementos'] as List<dynamic>? ?? [];
      return lista
          .map((e) => ElementoCanvas.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─── CARGAR datos de cabecera/pie ──────────────────────────────────────────
  static Future<CroquisDatos> cargarDatos(String hojaId) async {
    try {
      final doc = await _doc(hojaId).get();
      if (!doc.exists) return const CroquisDatos();
      final data = doc.data() as Map<String, dynamic>;
      if (data['datos'] == null) return const CroquisDatos();
      return CroquisDatos.fromMap(Map<String, dynamic>.from(data['datos']));
    } catch (e) {
      return const CroquisDatos();
    }
  }

  // ─── STREAM en tiempo real (solo elementos) ────────────────────────────────
  static Stream<List<ElementoCanvas>> stream(String hojaId) {
    return _doc(hojaId).snapshots().map((doc) {
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>;
      final lista = data['elementos'] as List<dynamic>? ?? [];
      return lista
          .map((e) => ElementoCanvas.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    });
  }
}
