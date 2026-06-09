// lib/services/borrador_service.dart
// Borradores LOCALES (autoguardado en el dispositivo).
//
// DIFERENCIA con el "BORRADOR" de sincronización:
//   - Borrador LOCAL (este archivo): hoja a medio llenar que NUNCA se creó en
//     Firestore. Vive solo en el teléfono (shared_preferences). No tiene código HDT.
//     Se usa para no perder el trabajo si el inspector sale sin guardar.
//   - BORRADOR de sincronización (hoja_terreno_service): hoja YA creada offline,
//     esperando código HDT del servidor. Esa sí está en Firestore.
//
// Guardamos varios borradores, cada uno identificado por un draftId único.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BorradorLocal {
  final String draftId;          // id único local (timestamp)
  final DateTime guardadoEn;
  final Map<String, dynamic> datos; // todo el contenido serializado del formulario

  BorradorLocal({
    required this.draftId,
    required this.guardadoEn,
    required this.datos,
  });

  Map<String, dynamic> toJson() => {
    'draftId': draftId,
    'guardadoEn': guardadoEn.millisecondsSinceEpoch,
    'datos': datos,
  };

  factory BorradorLocal.fromJson(Map<String, dynamic> j) => BorradorLocal(
    draftId: j['draftId'],
    guardadoEn: DateTime.fromMillisecondsSinceEpoch(j['guardadoEn'] ?? 0),
    datos: Map<String, dynamic>.from(j['datos'] ?? {}),
  );

  // Título legible para mostrar en la lista de borradores
  String get titulo {
    final tanque = datos['tanqueNumero'] ?? '';
    final cliente = datos['cliente'] ?? '';
    if (tanque.toString().isNotEmpty) return 'Tanque Nº $tanque';
    if (cliente.toString().isNotEmpty) return cliente;
    return 'Borrador sin título';
  }

  String get subtitulo {
    final cliente = datos['cliente'] ?? '';
    return cliente.toString().isNotEmpty ? cliente : 'Sin cliente';
  }
}

class BorradorService {
  // Prefijo de las claves en shared_preferences
  static const _prefix = 'borrador_';

  // ─── GUARDAR / ACTUALIZAR un borrador ──────────────────────────────────────
  static Future<void> guardar(BorradorLocal borrador) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix${borrador.draftId}', jsonEncode(borrador.toJson()));
  }

  // ─── LISTAR todos los borradores (más recientes primero) ───────────────────
  static Future<List<BorradorLocal>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));

    final lista = <BorradorLocal>[];
    for (final k in keys) {
      final raw = prefs.getString(k);
      if (raw == null) continue;
      try {
        lista.add(BorradorLocal.fromJson(jsonDecode(raw)));
      } catch (_) {
        // Si un borrador está corrupto, lo ignoramos
      }
    }
    lista.sort((a, b) => b.guardadoEn.compareTo(a.guardadoEn));
    return lista;
  }

  // ─── OBTENER uno por id ─────────────────────────────────────────────────────
  static Future<BorradorLocal?> obtener(String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$draftId');
    if (raw == null) return null;
    try {
      return BorradorLocal.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  // ─── ELIMINAR un borrador (al crear la hoja o al descartarlo) ──────────────
  static Future<void> eliminar(String draftId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$draftId');
  }

  // ─── CONTAR borradores ──────────────────────────────────────────────────────
  static Future<int> contar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().where((k) => k.startsWith(_prefix)).length;
  }
}
