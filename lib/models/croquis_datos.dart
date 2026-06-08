// lib/models/croquis_datos.dart
// Datos de cabecera y pie del croquis (campos alrededor del canvas de dibujo).
// Los trazos (ElementoCanvas) se guardan aparte; esto son los campos de texto y checkboxes.

class CroquisDatos {
  // ── Cabecera: Espesores ─────────────────────────────────────────────────────
  final String espesorCuello;   // mm
  final String espesorTapa;     // mm
  final String espesorFlange;   // mm
  final String instrumento;

  // Inspector / Fecha / Resultado / Inicio / Fin
  final String inspector;
  final String fecha;
  final String resultado;
  final String inicio;
  final String fin;

  // ── Pie: Observaciones (checkboxes SÍ/NO) ──────────────────────────────────
  // Usamos bool? : true = Sí, false = No, null = sin marcar
  final bool? placaFabricacionTanque;
  final bool? reparacionTanque;

  const CroquisDatos({
    this.espesorCuello = '',
    this.espesorTapa = '',
    this.espesorFlange = '',
    this.instrumento = '',
    this.inspector = '',
    this.fecha = '',
    this.resultado = '',
    this.inicio = '',
    this.fin = '',
    this.placaFabricacionTanque,
    this.reparacionTanque,
  });

  factory CroquisDatos.fromMap(Map<String, dynamic> m) {
    String s(String k) => m[k] ?? '';
    return CroquisDatos(
      espesorCuello: s('espesorCuello'),
      espesorTapa: s('espesorTapa'),
      espesorFlange: s('espesorFlange'),
      instrumento: s('instrumento'),
      inspector: s('inspector'),
      fecha: s('fecha'),
      resultado: s('resultado'),
      inicio: s('inicio'),
      fin: s('fin'),
      placaFabricacionTanque: m['placaFabricacionTanque'], // puede ser null
      reparacionTanque: m['reparacionTanque'],
    );
  }

  Map<String, dynamic> toMap() => {
    'espesorCuello': espesorCuello,
    'espesorTapa': espesorTapa,
    'espesorFlange': espesorFlange,
    'instrumento': instrumento,
    'inspector': inspector,
    'fecha': fecha,
    'resultado': resultado,
    'inicio': inicio,
    'fin': fin,
    'placaFabricacionTanque': placaFabricacionTanque,
    'reparacionTanque': reparacionTanque,
  };
}
