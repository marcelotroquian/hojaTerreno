// lib/services/pdf_service.dart
// Genera un PDF de la Hoja de Terreno respetando el formato original.
//
// Estructura del PDF:
//   Página 1+: cabecera con logo + datos + secciones 1-6
//   Croquis: en su recuadro (imagen capturada del canvas)
//   Fotos: hojas extra al final
//
// El croquis se recibe como bytes PNG (capturado con RepaintBoundary en la UI).

import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/hoja_terreno.dart';
import '../models/inspeccion_radiografica.dart';
import '../models/inspeccion_fabricacion.dart';
import '../models/prueba_hermeticidad.dart';
import '../models/inspeccion_recubrimiento.dart';
import '../models/verificacion_accesorios.dart';
import '../models/placa_identificacion.dart';
import '../models/croquis_datos.dart';

class PdfService {
  // Color de acento (igual al de la app)
  static const _morado = PdfColor.fromInt(0xFF6C63FF);
  static const _gris = PdfColor.fromInt(0xFFEEEEEE);
  static const _negro = PdfColors.black;

  // ─── Punto de entrada principal ─────────────────────────────────────────────
  static Future<Uint8List> generar({
    required HojaTerreno hoja,
    required InspeccionRadiografica radiografica,
    required InspeccionFabricacion fabricacion,
    required PruebaHermeticidad hermeticidad,
    required InspeccionRecubrimiento recubrimiento,
    required VerificacionAccesorios accesorios,
    required PlacaIdentificacion placa,
    required CroquisDatos croquisDatos,
    Uint8List? croquisImagen,    // PNG del canvas (puede ser null)
    List<String> urlsFotos = const [],
  }) async {
    final doc = pw.Document();

    // Descargar las fotos (si hay) para incrustarlas
    final List<Uint8List> fotos = [];
    for (final url in urlsFotos) {
      if (url.isEmpty) continue;
      try {
        final resp = await http.get(Uri.parse(url));
        if (resp.statusCode == 200) fotos.add(resp.bodyBytes);
      } catch (_) {}
    }

    // Página principal con todo el contenido (multi-página automático)
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _cabecera(hoja),
          pw.SizedBox(height: 6),
          _datosGenerales(hoja),
          pw.SizedBox(height: 6),
          _tipoTanque(hoja),
          pw.SizedBox(height: 10),
          _seccionRadiografica(radiografica),
          pw.SizedBox(height: 8),
          _seccionFabricacion(fabricacion),
          pw.SizedBox(height: 8),
          _seccionHermeticidad(hermeticidad),
          pw.SizedBox(height: 8),
          _seccionRecubrimiento(recubrimiento),
          pw.SizedBox(height: 8),
          _seccionAccesorios(accesorios),
          pw.SizedBox(height: 8),
          _seccionPlaca(placa),
          pw.SizedBox(height: 8),
          _seccionCroquis(croquisDatos, croquisImagen),
        ],
      ),
    );

    // Hojas extra para fotos (2 por página)
    if (fotos.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            _tituloBarra('ANEXO: REGISTRO FOTOGRÁFICO'),
            pw.SizedBox(height: 10),
            pw.Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(fotos.length, (i) {
                return pw.Container(
                  width: 240,
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: _negro, width: 0.5)),
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        color: _gris,
                        width: double.infinity,
                        child: pw.Text('Foto ${i + 1}', style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Container(
                        width: 240,
                        height: 180,
                        alignment: pw.Alignment.center,
                        child: pw.Image(
                          pw.MemoryImage(fotos[i]),
                          width: 238,
                          height: 178,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      );
    }

    return doc.save();
  }

  // ─── CABECERA con logo y datos del tanque ───────────────────────────────────
  static pw.Widget _cabecera(HojaTerreno hoja) {
    return pw.Container(
      height: 95, // altura fija evita el problema de constraints infinitos
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _negro, width: 1)),
      child: pw.Row(
        children: [
          // Logo (texto estilizado, ya que no tenemos el asset)
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              height: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              alignment: pw.Alignment.center,
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide(color: _negro, width: 1)),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('INTECIL',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                  pw.Text('SPA', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
            ),
          ),
          // Título central
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              height: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              alignment: pw.Alignment.center,
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide(color: _negro, width: 1)),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('HOJA DE TERRENO',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Inspección y Reinspección de Tanques para',
                      style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
                  pw.Text('Almacenamiento y Transporte',
                      style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
                  pw.SizedBox(height: 2),
                  pw.Text('Combustibles Líquidos',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ),
          // Datos derecha
          pw.Expanded(
            flex: 4,
            child: pw.Container(
              height: double.infinity,
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisSize: pw.MainAxisSize.min,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  _lineaDato('Tanque Nº', hoja.tanqueNumero),
                  _lineaDato('Serie Nº', hoja.serieNumero),
                  _lineaDato('Certificado Nº', hoja.certificadoNumero),
                  _lineaDato('Patente Nº', hoja.patenteNumero),
                  _lineaDato('Plano Nº', hoja.planoNumero),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Línea "Label: ____valor____"
  static pw.Widget _lineaDato(String label, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        children: [
          pw.Text('$label ', style: const pw.TextStyle(fontSize: 8)),
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: _negro, width: 0.5)),
              ),
              child: pw.Text(valor, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── DATOS GENERALES (Cliente, Maestranza, etc.) ───────────────────────────
  static pw.Widget _datosGenerales(HojaTerreno hoja) {
    final tipoInsp = hoja.tipoInspeccion == TipoInspeccion.periodica ? 'PERIÓDICA' : 'FABRICACIÓN';
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _negro, width: 0.5)),
      child: pw.Column(
        children: [
          pw.Row(children: [
            _celda('Cliente', hoja.cliente, flex: 3),
            _celda('Maestranza', hoja.maestranza, flex: 2),
          ]),
          _divisor(),
          pw.Row(children: [
            _celda('Capacidad', hoja.capacidad, flex: 2),
            _celda('Material', hoja.material, flex: 2),
            _celda('Inspección', tipoInsp, flex: 2),
          ]),
          _divisor(),
          pw.Row(children: [
            _celda('Norma aplicada', hoja.normaAplicada, flex: 2),
            _celda('Protocolo Nº', hoja.protocoloNumero, flex: 2),
            _celda('Certif. Anterior Nº', hoja.certificadoAnterior, flex: 2),
          ]),
          _divisor(),
          pw.Row(children: [
            _celda('Número Chassis / VIN', hoja.numeroChassisVin, flex: 3),
            _celda('Patente', hoja.patenteVehiculo, flex: 2),
          ]),
        ],
      ),
    );
  }

  // ─── TIPO DE TANQUE (checkboxes) ───────────────────────────────────────────
  static pw.Widget _tipoTanque(HojaTerreno hoja) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _negro, width: 0.5)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('TIPO DE TANQUE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Wrap(
            spacing: 14,
            runSpacing: 4,
            children: TipoTanque.values.map((t) {
              return _checkbox(t.label, hoja.tiposTanque.contains(t));
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── SECCIÓN 1: Radiográfica ───────────────────────────────────────────────
  static pw.Widget _seccionRadiografica(InspeccionRadiografica r) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloBarra('1 - INSPECCIÓN RADIOGRÁFICA'),
        _bloque([
          pw.Row(children: [
            _celda('Equipo', r.equipo, flex: 2),
            _celda('Nº', r.numero, flex: 1),
            _celda('Inicio', r.inicio, flex: 1),
            _celda('Fin', r.fin, flex: 1),
          ]),
          _divisor(),
          pw.Row(children: [
            _celda('Curitaje', r.curitaje, flex: 1),
            _celda('Distancia (pulg.)', r.distanciaPulg, flex: 1),
            _celda('Tiempo', r.tiempo, flex: 1),
          ]),
          _divisor(),
          // Inspector / Fecha / Resultado (uno solo)
          _filaInspector(
            r.inspector.isNotEmpty ? r.inspector : (r.filas.isNotEmpty ? r.filas.first.operador : ''),
            r.fecha.isNotEmpty ? r.fecha : (r.filas.isNotEmpty ? r.filas.first.fecha : ''),
            r.resultado.isNotEmpty ? r.resultado : (r.filas.isNotEmpty ? r.filas.first.resultado : ''),
          ),
        ]),
      ],
    );
  }

  // ─── SECCIÓN 2: Fabricación ────────────────────────────────────────────────
  static pw.Widget _seccionFabricacion(InspeccionFabricacion f) {
    String manto() {
      if (f.mantoForma == 'cilindrico') return 'Cilíndrico';
      if (f.mantoForma == 'eliptico') return 'Elíptico';
      return '';
    }
    String cabezal() {
      switch (f.cabezalForma) {
        case 'bombeado': return 'Bombeado';
        case 'conico': return 'Cónico';
        case 'plano': return 'Plano';
        case 'curvo': return 'Curvo Trazado';
        default: return '';
      }
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloBarra('2 - INSPECCIÓN DE FABRICACIÓN'),
        _bloque([
          _subtitulo('2.1 Materiales'),
          pw.Row(children: [
            _checkbox('Certificado de Materiales', f.certificadoMateriales),
            pw.SizedBox(width: 12),
            _checkbox('Plano', f.plano),
            pw.SizedBox(width: 12),
            _checkbox('Ficha Técnica', f.fichaTecnica),
          ]),
          pw.Row(children: [
            _celda('Inicio', f.inicio21, flex: 1),
            _celda('Fin', f.fin21, flex: 1),
          ]),
          _divisor(),
          _subtitulo('2.2 Inspección Visual'),
          pw.Row(children: [
            _celda('Manto', manto(), flex: 1),
            _celda('Válvula de fondo', f.valvulaFondo, flex: 2),
          ]),
          pw.Row(children: [
            _celda('Cabezal', cabezal(), flex: 1),
            _celda('Inicio', f.inicioCabezal, flex: 1),
            _celda('Fin', f.finCabezal, flex: 1),
          ]),
          pw.Row(children: [
            _celda('Conformado Manto', f.conformadoManto, flex: 1),
            _celda('Conformado Cabezales', f.conformadoCabezales, flex: 1),
            _celda('Estabilidad A/B', f.estabilidadAB, flex: 1),
          ]),
          pw.Row(children: [
            _celda('Refuerzo regla medición', f.refuerzoReglaMedicion, flex: 1),
            _celda('Venteo cuello', f.venteoCuello, flex: 1),
            _celda('Perno Rey', f.pernoRey, flex: 1),
          ]),
          _divisor(),
          _subtitulo('2.3 Control Dimensional'),
          pw.Row(children: [
            _celda('Huincha perimetral', f.huinchaPerimetral, flex: 1),
            _celda('Huincha convencional', f.huinchaConvencional, flex: 1),
          ]),
          pw.Row(children: [
            _celda('Largo Exterior (mm)', f.largoExterior, flex: 1),
            _celda('Perímetro (mm)', f.perimetro, flex: 1),
            _celda('Largo pestaña (mm)', f.largoPestana, flex: 1),
            _celda('Altura manto brida (mm)', f.alturaMantoBrida, flex: 1),
          ]),
          pw.Row(children: [
            _celda('Cabezal 1 (mm)', f.cabezal1, flex: 1),
            _celda('Cabezal 2 (mm)', f.cabezal2, flex: 1),
            _celda('Ø int. Cuello', f.diamInteriorCuello, flex: 1),
            _celda('Inicio', f.inicio23, flex: 1),
            _celda('Fin', f.fin23, flex: 1),
          ]),
          _divisor(),
          _subtitulo('2.4 Inspecc. Conexiones / Venteos'),
          pw.Row(children: [
            _celda('Venteo Normal', f.venteoNormal, flex: 1),
            _celda('Venteo Emergencia', f.venteoEmergencia, flex: 1),
          ]),
          pw.Row(children: [
            _celda('Tipo conexiones', f.tipoConexiones, flex: 1),
            _celda('Tamaños', f.tamanos, flex: 1),
            _celda('Material', f.material24, flex: 1),
            _celda('Inicio', f.inicio24, flex: 1),
            _celda('Fin', f.fin24, flex: 1),
          ]),
          _divisor(),
          _subtitulo('2.5 Inspección Soldaduras'),
          pw.Row(children: [
            _celda('Sold. Longitudinales', f.soldLongitudinales, flex: 1),
            _celda('Sold. Circunferenciales', f.soldCircunferenciales, flex: 1),
          ]),
          pw.Row(children: [
            _celda('Alineamiento secciones', f.alineamientoSecciones, flex: 1),
            _celda('Traslapo uniones Circunf.', f.traslapoUnionesCircunf, flex: 1),
          ]),
          pw.Row(children: [
            _celda('Soldadura Manto-Cabezal', f.soldaduraMantoCabezal, flex: 1),
            _celda('Soldadura en cabezal', f.soldaduraEnCabezal, flex: 1),
          ]),
          pw.Row(children: [
            _celda('Soldadura cuello-manto', f.soldaduraCuelloManto, flex: 1),
            _celda('Soldadura cuello-brida', f.soldaduraCuelloBrida, flex: 1),
            _celda('Inicio', f.inicio25, flex: 1),
            _celda('Fin', f.fin25, flex: 1),
          ]),
          _filaInspector(f.inspector, f.fecha, f.resultado),
        ]),
      ],
    );
  }

  // ─── SECCIÓN 3: Hermeticidad ───────────────────────────────────────────────
  static pw.Widget _seccionHermeticidad(PruebaHermeticidad h) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloBarra('3 - PRUEBA DE HERMETICIDAD O ESTANQUEIDAD'),
        _bloque([
          pw.Row(children: [
            _celda('Inicio', h.inicio, flex: 1),
            _celda('Fin', h.fin, flex: 1),
            pw.Expanded(flex: 2, child: pw.SizedBox(height: 1)),
          ]),
          _divisor(),
          _filaPrueba('3.1 Presión Insp. Tanque', h.presionTanque, h.manometroTanque, h.rangoTanque, h.tiempoTanque),
          _filaPrueba('3.2 Presión Insp. Serpentín', h.presionSerpentin, h.manometroSerpentin, h.rangoSerpentin, h.tiempoSerpentin),
          _filaPrueba('3.3 Presión Mamparos', h.presionMamparos, h.manometroMamparos, h.rangoMamparos, h.tiempoMamparos),
          _filaInspector(h.inspector, h.fecha, h.resultado),
        ]),
      ],
    );
  }

  static pw.Widget _filaPrueba(String titulo, String presion, String manometro, String rango, String tiempo) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(children: [
        pw.Expanded(flex: 2, child: pw.Text(titulo, style: const pw.TextStyle(fontSize: 7))),
        _celda('psi', presion, flex: 1),
        _celda('Manómetro', manometro, flex: 2),
        _celda('Rango psi', rango, flex: 1),
        _celda('Tiempo Min.', tiempo, flex: 1),
      ]),
    );
  }

  // ─── SECCIÓN 4: Recubrimiento ──────────────────────────────────────────────
  static pw.Widget _seccionRecubrimiento(InspeccionRecubrimiento r) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloBarra('4 - INSPECCIÓN RECUBRIMIENTO O REVESTIMIENTO'),
        _bloque([
          _subtitulo('4.1 General'),
          pw.Row(children: [
            _celda('Tipo', r.tipo, flex: 1),
            _celda('Material', r.material, flex: 2),
            _celda('Inicio', r.inicio41, flex: 1),
            _celda('Fin', r.fin41, flex: 1),
          ]),
          pw.Row(children: [
            _celda('Tipo Aplicación', r.tipoAplicacion, flex: 1),
            _celda('Prep. Superficie', r.prepSuperficie, flex: 1),
          ]),
          pw.Row(children: [
            _celda('Resina', r.resina, flex: 1),
            _celda('Imprimante/Anticorrosivo', r.imprimanteAnticorrosivo, flex: 2),
            _celda('Instrumento', r.instrumento41, flex: 1),
          ]),
          _divisor(),
          _subtitulo('4.2 Espesores'),
          pw.Row(children: [
            _celda('Espesor Mínimo', r.espesorMinimo, flex: 1),
            _celda('Cantidad Medidas', r.cantidadMedidas, flex: 1),
            _celda('Inicio', r.inicio42, flex: 1),
            _celda('Fin', r.fin42, flex: 1),
          ]),
          pw.Row(children: [
            _celda('MÍNIMO', r.minimoEspesor, flex: 1),
            _celda('MÁXIMO', r.maximoEspesor, flex: 1),
            _celda('PROMEDIO', r.promedioEspesor, flex: 1),
          ]),
          _divisor(),
          _subtitulo('4.3 Ensayo de Porosidad'),
          pw.Row(children: [
            _celda('Voltaje KV', r.voltajeKV, flex: 1),
            _celda('Instrumento', r.instrumento43, flex: 1),
            _celda('Inicio', r.inicio43, flex: 1),
            _celda('Fin', r.fin43, flex: 1),
          ]),
          _filaInspector(r.inspector, r.fecha, r.resultado),
        ]),
      ],
    );
  }

  // ─── SECCIÓN 5: Accesorios ─────────────────────────────────────────────────
  static pw.Widget _seccionAccesorios(VerificacionAccesorios a) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloBarra('5 - VERIFICACIÓN ACCESORIOS'),
        _bloque([
          pw.Row(children: [
            _celda('Presión Esp. Interst. (psig)', a.presionEsp, flex: 1),
            _celda('Instrumento', a.instrumentoPresion, flex: 2),
            _celda('Rango', a.rangoPresion, flex: 1),
            _celda('Inicio', a.inicioPresion, flex: 1),
            _celda('Fin', a.finPresion, flex: 1),
          ]),
          pw.Row(children: [
            _celda('Vacío esp. Interst. (inHg)', a.vacioEsp, flex: 1),
            _celda('Instrumento', a.instrumentoVacio, flex: 2),
            _celda('Rango', a.rangoVacio, flex: 1),
            _celda('Inicio', a.inicioVacio, flex: 1),
            _celda('Fin', a.finVacio, flex: 1),
          ]),
          _filaInspector(a.inspector, a.fecha, a.resultado),
        ]),
      ],
    );
  }

  // ─── SECCIÓN 6: Placa ──────────────────────────────────────────────────────
  static pw.Widget _seccionPlaca(PlacaIdentificacion p) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloBarra('6 - PLACA DE IDENTIFICACIÓN'),
        _bloque([
          pw.Row(
              children: [
                _celda('Ubicación', p.ubicacion, flex: 1),
              ],
            ),
          pw.SizedBox(height: 4),
          pw.Row(children: [
            _checkbox('Verificación Datos', p.verificacionDatos),
            pw.SizedBox(width: 12),
            _checkbox('Cuño III', p.cunoIII),
            pw.SizedBox(width: 12),
            _checkbox('Nº Certificado acuñado en copla', p.numeroCertificadoAcunado),
          ]),
          pw.Row(children: [
            _celda('Inicio', p.inicio, flex: 1),
            _celda('Fin', p.fin, flex: 1),
            pw.Expanded(flex: 2, child: pw.SizedBox(height: 1)),
          ]),
          _filaInspector(p.inspector, p.fecha, p.resultado),
        ]),
      ],
    );
  }

  // ─── CROQUIS (con imagen capturada + cabecera + observaciones) ─────────────
  static pw.Widget _seccionCroquis(CroquisDatos d, Uint8List? imagen) {
    pw.Widget siNo(String label, bool? valor) {
      return pw.Row(children: [
        pw.Text('$label: ', style: const pw.TextStyle(fontSize: 7)),
        _checkbox('Sí', valor == true),
        pw.SizedBox(width: 8),
        _checkbox('No', valor == false),
      ]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloBarra('CROQUIS ESPESORES Y UBICACIÓN DE RADIOGRAFÍAS'),
        _bloque([
          // Cabecera de espesores
          pw.Row(children: [
            _celda('Cuello (mm)', d.espesorCuello, flex: 1),
            _celda('Tapa (mm)', d.espesorTapa, flex: 1),
            _celda('Flange (mm)', d.espesorFlange, flex: 1),
            _celda('Instrumento', d.instrumento, flex: 2),
          ]),
          pw.Row(children: [
            _celda('Inspector', d.inspector, flex: 2),
            _celda('Fecha', d.fecha, flex: 1),
            _celda('Resultado', d.resultado, flex: 1),
            _celda('Inicio', d.inicio, flex: 1),
            _celda('Fin', d.fin, flex: 1),
          ]),
        ]),
        // Imagen del croquis
        pw.Container(
          width: double.infinity,
          height: 260,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: _negro, width: 0.5)),
          alignment: pw.Alignment.center,
          child: imagen != null
              ? pw.Image(
                  pw.MemoryImage(imagen),
                  height: 258,
                  fit: pw.BoxFit.fitHeight,
                )
              : pw.Center(child: pw.Text('(Sin croquis)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey))),
        ),
        // Observaciones
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: _negro, width: 0.5)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('OBSERVACIONES:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              siNo('Placa Fabr. Tanque', d.placaFabricacionTanque),
              pw.SizedBox(height: 2),
              siNo('Reparación Tanque', d.reparacionTanque),
            ],
          ),
        ),
      ],
    );
  }

  // ─── HELPERS de layout ──────────────────────────────────────────────────────

  // Barra de título de sección (fondo morado)
  static pw.Widget _tituloBarra(String texto) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      color: _morado,
      child: pw.Text(texto, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    );
  }

  // Subtítulo de subsección (ej. 2.1)
  static pw.Widget _subtitulo(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Text(texto, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _morado)),
    );
  }

  // Bloque con borde que envuelve filas
  static pw.Widget _bloque(List<pw.Widget> children) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _negro, width: 0.5)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: children),
    );
  }

  // Celda "label: valor" con flex
  static pw.Widget _celda(String label, String valor, {int flex = 1}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
            pw.Container(
              width: double.infinity,
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: _negro, width: 0.5)),
              ),
              child: pw.Text(valor.isEmpty ? ' ' : valor, style: const pw.TextStyle(fontSize: 8)),
            ),
          ],
        ),
      ),
    );
  }

  // Fila inspector/fecha/resultado destacada
  static pw.Widget _filaInspector(String inspector, String fecha, String resultado) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 4),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _negro, width: 0.5)),
      child: pw.Row(children: [
        _celda('Inspector', inspector, flex: 2),
        _celda('Fecha', fecha, flex: 1),
        _celda('Resultado', resultado, flex: 1),
      ]),
    );
  }

  // Checkbox con label
  static pw.Widget _checkbox(String label, bool marcado) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 10, height: 10,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: _negro, width: 0.8)),
          alignment: pw.Alignment.center,
          child: marcado ? pw.Text('X', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)) : pw.SizedBox(width: 10, height: 10),
        ),
        pw.SizedBox(width: 3),
        pw.Text(label, style: const pw.TextStyle(fontSize: 7)),
      ],
    );
  }

  static pw.Widget _divisor() => pw.Container(
    margin: const pw.EdgeInsets.symmetric(vertical: 2),
    height: 0.5,
    color: PdfColors.grey400,
  );
}
