// lib/services/croquis_render.dart
// Renderiza los elementos del croquis a una imagen PNG sin necesidad de
// mostrar el canvas en pantalla. Usa el mismo CroquisPainter.

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/canvas_element.dart';
import '../widgets/croquis_painter.dart';

class CroquisRender {
  // Renderiza la lista de elementos a PNG.
  // width/height definen el tamaño del lienzo de salida.
  static Future<Uint8List?> aPng({
    required List<ElementoCanvas> elementos,
    double width = 800,
    double height = 520,
  }) async {
    if (elementos.isEmpty) return null;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

      // Fondo blanco
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        Paint()..color = Colors.white,
      );

      // Dibujar los elementos con el mismo painter de la pantalla
      final painter = CroquisPainter(elementos: elementos);
      painter.paint(canvas, Size(width, height));

      // Convertir a imagen
      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }
}
