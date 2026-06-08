// lib/screens/pdf_preview_screen.dart
// Vista previa del PDF generado, con opciones de compartir / imprimir / guardar.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/hoja_terreno.dart';
import '../models/inspeccion_radiografica.dart';
import '../models/inspeccion_fabricacion.dart';
import '../models/prueba_hermeticidad.dart';
import '../models/inspeccion_recubrimiento.dart';
import '../models/verificacion_accesorios.dart';
import '../models/placa_identificacion.dart';
import '../models/canvas_element.dart';
import '../models/croquis_datos.dart';
import '../services/secciones_service.dart';
import '../services/croquis_service.dart';
import '../services/croquis_render.dart';
import '../services/fotos_service.dart';
import '../services/pdf_service.dart';

class PdfPreviewScreen extends StatefulWidget {
  final HojaTerreno hoja;
  const PdfPreviewScreen({super.key, required this.hoja});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  Uint8List? _pdfBytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generar();
  }

  Future<void> _generar() async {
    try {
      final hojaId = widget.hoja.id;

      // Cargamos en paralelo todas las secciones, croquis y fotos
      final results = await Future.wait([
        SeccionesService.cargarRadiografica(hojaId),
        SeccionesService.cargarFabricacion(hojaId),
        SeccionesService.cargarHermeticidad(hojaId),
        SeccionesService.cargarRecubrimiento(hojaId),
        SeccionesService.cargarAccesorios(hojaId),
        SeccionesService.cargarPlaca(hojaId),
        CroquisService.cargar(hojaId),
        CroquisService.cargarDatos(hojaId),
        FotosService.obtenerUrls(hojaId),
      ]);

      final radiografica  = results[0] as InspeccionRadiografica;
      final fabricacion   = results[1] as InspeccionFabricacion;
      final hermeticidad  = results[2] as PruebaHermeticidad;
      final recubrimiento = results[3] as InspeccionRecubrimiento;
      final accesorios    = results[4] as VerificacionAccesorios;
      final placa         = results[5] as PlacaIdentificacion;
      final elementos     = results[6] as List<ElementoCanvas>;
      final croquisDatos  = results[7] as CroquisDatos;
      final urlsFotos     = (results[8] as List).cast<String>();

      // Renderizar croquis a PNG
      final croquisImg = await CroquisRender.aPng(elementos: elementos);

      // Generar el PDF
      final bytes = await PdfService.generar(
        hoja: widget.hoja,
        radiografica: radiografica,
        fabricacion: fabricacion,
        hermeticidad: hermeticidad,
        recubrimiento: recubrimiento,
        accesorios: accesorios,
        placa: placa,
        croquisDatos: croquisDatos,
        croquisImagen: croquisImg,
        urlsFotos: urlsFotos,
      );

      if (mounted) setState(() => _pdfBytes = bytes);
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al generar el PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreArchivo = 'Hoja_Terreno_${widget.hoja.tanqueNumero.isNotEmpty ? widget.hoja.tanqueNumero : widget.hoja.id}.pdf';

    return Scaffold(
      backgroundColor: const Color(0xFF525659),
      appBar: AppBar(
        title: const Text('Vista previa PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : _pdfBytes == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text('Generando PDF...', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                )
              // PdfPreview ya incluye botones de compartir/imprimir/descargar
              : PdfPreview(
                  build: (format) => _pdfBytes!,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  pdfFileName: nombreArchivo,
                  actionBarTheme: const PdfActionBarTheme(
                    backgroundColor: Color(0xFF6C63FF),
                    iconColor: Colors.white,
                  ),
                ),
    );
  }
}
