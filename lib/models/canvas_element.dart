// lib/models/canvas_element.dart
// Modelos para cada tipo de elemento que se puede dibujar en el croquis
// Cada elemento sabe serializar/deserializar a Firestore

import 'package:flutter/material.dart';

// ─── Enum de herramientas disponibles ─────────────────────────────────────────
enum HerramientaCroquis {
  lapiz,      // Trazo libre
  linea,      // Línea recta
  rectangulo, // Rectángulo
  circulo,    // Círculo/elipse
  texto,      // Texto libre
  borrador,   // Borrar elementos
}

// ─── Enum de tipos de elemento ────────────────────────────────────────────────
enum TipoElemento { trazo, linea, rectangulo, circulo, texto, borrado }

// ─── Clase base para un punto ─────────────────────────────────────────────────
class PuntoCanvas {
  final double x;
  final double y;
  const PuntoCanvas(this.x, this.y);

  factory PuntoCanvas.fromMap(Map<String, dynamic> m) =>
      PuntoCanvas((m['x'] as num).toDouble(), (m['y'] as num).toDouble());

  Map<String, dynamic> toMap() => {'x': x, 'y': y};

  Offset toOffset() => Offset(x, y);
}

// ─── Elemento genérico del canvas ─────────────────────────────────────────────
class ElementoCanvas {
  final String id;
  final TipoElemento tipo;
  final int colorValue;       // Color almacenado como int (Color.value)
  final double grosor;

  // Para trazos libres: lista de puntos
  final List<PuntoCanvas> puntos;

  // Para formas (línea, rect, círculo): punto inicio y fin
  final PuntoCanvas? inicio;
  final PuntoCanvas? fin;

  // Para texto
  final String? texto;
  final double? fontSize;

  ElementoCanvas({
    required this.id,
    required this.tipo,
    required this.colorValue,
    required this.grosor,
    this.puntos = const [],
    this.inicio,
    this.fin,
    this.texto,
    this.fontSize,
  });

  Color get color => Color(colorValue);

  // ─── Desde Firestore ─────────────────────────────────────────────────────
  factory ElementoCanvas.fromMap(Map<String, dynamic> m) {
    final tipoStr = m['tipo'] as String;
    final tipo = TipoElemento.values.firstWhere(
      (t) => t.name == tipoStr,
      orElse: () => TipoElemento.trazo,
    );

    return ElementoCanvas(
      id:          m['id'] as String,
      tipo:        tipo,
      colorValue:  (m['color'] as num).toInt(),
      grosor:      (m['grosor'] as num).toDouble(),
      puntos:      (m['puntos'] as List<dynamic>? ?? [])
          .map((p) => PuntoCanvas.fromMap(Map<String, dynamic>.from(p)))
          .toList(),
      inicio: m['inicio'] != null
          ? PuntoCanvas.fromMap(Map<String, dynamic>.from(m['inicio']))
          : null,
      fin: m['fin'] != null
          ? PuntoCanvas.fromMap(Map<String, dynamic>.from(m['fin']))
          : null,
      texto:    m['texto'] as String?,
      fontSize: m['fontSize'] != null ? (m['fontSize'] as num).toDouble() : null,
    );
  }

  // ─── A Firestore ─────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'id':       id,
      'tipo':     tipo.name,
      'color':    colorValue,
      'grosor':   grosor,
      'puntos':   puntos.map((p) => p.toMap()).toList(),
      'inicio':   inicio?.toMap(),
      'fin':      fin?.toMap(),
      'texto':    texto,
      'fontSize': fontSize,
    };
  }

  // Copia con nuevos puntos (para trazos en progreso)
  ElementoCanvas copyWithPuntos(List<PuntoCanvas> nuevosPuntos) {
    return ElementoCanvas(
      id: id, tipo: tipo, colorValue: colorValue, grosor: grosor,
      puntos: nuevosPuntos, inicio: inicio, fin: fin, texto: texto, fontSize: fontSize,
    );
  }

  // Copia con nuevo punto fin (para formas en progreso)
  ElementoCanvas copyWithFin(PuntoCanvas nuevoFin) {
    return ElementoCanvas(
      id: id, tipo: tipo, colorValue: colorValue, grosor: grosor,
      puntos: puntos, inicio: inicio, fin: nuevoFin, texto: texto, fontSize: fontSize,
    );
  }
}
