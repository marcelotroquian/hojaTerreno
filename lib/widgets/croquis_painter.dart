// lib/widgets/croquis_painter.dart
// CustomPainter que dibuja todos los elementos en el canvas

import 'package:flutter/material.dart';
import '../models/canvas_element.dart';

class CroquisPainter extends CustomPainter {
  final List<ElementoCanvas> elementos;
  final ElementoCanvas? elementoEnProgreso; // El que se está dibujando ahora

  CroquisPainter({required this.elementos, this.elementoEnProgreso});

  @override
  void paint(Canvas canvas, Size size) {
    // Usamos una capa (saveLayer) para que la goma (BlendMode.clear) pueda
    // borrar lo que está debajo. Sin esta capa, clear pintaría negro en vez
    // de borrar. Todo lo que se dibuje aquí queda aislado en su propia capa.
    canvas.saveLayer(Offset.zero & size, Paint());

    // Dibujamos todos los elementos guardados
    for (final el in elementos) {
      _dibujarElemento(canvas, el);
    }
    // Encima, el elemento que se está dibujando en este momento
    if (elementoEnProgreso != null) {
      _dibujarElemento(canvas, elementoEnProgreso!);
    }

    canvas.restore(); // aplica la capa con los borrados ya procesados
  }

  void _dibujarElemento(Canvas canvas, ElementoCanvas el) {
    // La goma: trazo que borra en vez de pintar (BlendMode.clear)
    if (el.tipo == TipoElemento.borrado) {
      final paintBorrador = Paint()
        ..strokeWidth = el.grosor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.clear; // ← borra los píxeles por donde pasa
      _dibujarTrazo(canvas, el, paintBorrador);
      return;
    }

    final paint = Paint()
      ..color = el.color
      ..strokeWidth = el.grosor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (el.tipo) {
      case TipoElemento.trazo:
        _dibujarTrazo(canvas, el, paint);
        break;
      case TipoElemento.linea:
        _dibujarLinea(canvas, el, paint);
        break;
      case TipoElemento.rectangulo:
        _dibujarRectangulo(canvas, el, paint);
        break;
      case TipoElemento.circulo:
        _dibujarCirculo(canvas, el, paint);
        break;
      case TipoElemento.texto:
        _dibujarTexto(canvas, el);
        break;
      case TipoElemento.borrado:
        break; // ya manejado arriba
    }
  }

  // ─── Trazo libre ──────────────────────────────────────────────────────────
  void _dibujarTrazo(Canvas canvas, ElementoCanvas el, Paint paint) {
    if (el.puntos.isEmpty) return;
    // Un solo punto: dibujamos un punto (útil para toques rápidos y goma)
    if (el.puntos.length == 1) {
      final p = el.puntos.first;
      canvas.drawCircle(Offset(p.x, p.y), paint.strokeWidth / 2,
          Paint()..color = paint.color..blendMode = paint.blendMode);
      return;
    }
    final path = Path();
    path.moveTo(el.puntos.first.x, el.puntos.first.y);
    for (int i = 1; i < el.puntos.length; i++) {
      // Usamos quadraticBezierTo para trazos suaves
      if (i < el.puntos.length - 1) {
        final midX = (el.puntos[i].x + el.puntos[i + 1].x) / 2;
        final midY = (el.puntos[i].y + el.puntos[i + 1].y) / 2;
        path.quadraticBezierTo(el.puntos[i].x, el.puntos[i].y, midX, midY);
      } else {
        path.lineTo(el.puntos[i].x, el.puntos[i].y);
      }
    }
    canvas.drawPath(path, paint);
  }

  // ─── Línea recta ──────────────────────────────────────────────────────────
  void _dibujarLinea(Canvas canvas, ElementoCanvas el, Paint paint) {
    if (el.inicio == null || el.fin == null) return;
    canvas.drawLine(el.inicio!.toOffset(), el.fin!.toOffset(), paint);
  }

  // ─── Rectángulo ───────────────────────────────────────────────────────────
  void _dibujarRectangulo(Canvas canvas, ElementoCanvas el, Paint paint) {
    if (el.inicio == null || el.fin == null) return;
    final rect = Rect.fromPoints(el.inicio!.toOffset(), el.fin!.toOffset());
    canvas.drawRect(rect, paint);
  }

  // ─── Círculo/Elipse ───────────────────────────────────────────────────────
  void _dibujarCirculo(Canvas canvas, ElementoCanvas el, Paint paint) {
    if (el.inicio == null || el.fin == null) return;
    final rect = Rect.fromPoints(el.inicio!.toOffset(), el.fin!.toOffset());
    canvas.drawOval(rect, paint);
  }

  // ─── Texto ────────────────────────────────────────────────────────────────
  void _dibujarTexto(Canvas canvas, ElementoCanvas el) {
    if (el.texto == null || el.inicio == null) return;
    final tp = TextPainter(
      text: TextSpan(
        text: el.texto,
        style: TextStyle(
          color: el.color,
          fontSize: el.fontSize ?? 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, el.inicio!.toOffset());
  }

  @override
  bool shouldRepaint(CroquisPainter old) =>
      old.elementos != elementos || old.elementoEnProgreso != elementoEnProgreso;
}
