// lib/models/inspeccion_radiografica.dart

class InspeccionRadiografica {
  // ── 1. Datos generales ─────────────────────────────────────────────────────
  final String equipo;
  final String numero;
  final String inicio;
  final String fin;
  final String curitaje;
  final String distanciaPulg;
  final String tiempo;

  // ── 2. Inspector / Fecha / Resultado (uno solo) ───────────────────────────
  final String inspector;
  final String fecha;
  final String resultado;

  // (Legado) Filas antiguas de operador/fecha/resultado — ya no se usan en la UI,
  // pero se conservan para no romper datos guardados previamente.
  final List<FilaInspeccion> filas;

  const InspeccionRadiografica({
    this.equipo = '',
    this.numero = '',
    this.inicio = '',
    this.fin = '',
    this.curitaje = '',
    this.distanciaPulg = '',
    this.tiempo = '',
    this.inspector = '',
    this.fecha = '',
    this.resultado = '',
    this.filas = const [],
  });

  factory InspeccionRadiografica.fromMap(Map<String, dynamic> m) {
    // Compatibilidad: si no hay inspector nuevo pero sí filas viejas,
    // tomamos la primera fila como inspector/fecha/resultado.
    final filasViejas = (m['filas'] as List<dynamic>? ?? [])
        .map((f) => FilaInspeccion.fromMap(Map<String, dynamic>.from(f)))
        .toList();
    String insp = m['inspector'] ?? '';
    String fec = m['fecha'] ?? '';
    String res = m['resultado'] ?? '';
    if (insp.isEmpty && fec.isEmpty && res.isEmpty && filasViejas.isNotEmpty) {
      insp = filasViejas.first.operador;
      fec = filasViejas.first.fecha;
      res = filasViejas.first.resultado;
    }
    return InspeccionRadiografica(
      equipo:         m['equipo'] ?? '',
      numero:         m['numero'] ?? '',
      inicio:         m['inicio'] ?? '',
      fin:            m['fin'] ?? '',
      curitaje:       m['curitaje'] ?? '',
      distanciaPulg:  m['distanciaPulg'] ?? '',
      tiempo:         m['tiempo'] ?? '',
      inspector:      insp,
      fecha:          fec,
      resultado:      res,
      filas:          filasViejas,
    );
  }

  Map<String, dynamic> toMap() => {
    'equipo': equipo, 'numero': numero, 'inicio': inicio, 'fin': fin,
    'curitaje': curitaje, 'distanciaPulg': distanciaPulg, 'tiempo': tiempo,
    'inspector': inspector, 'fecha': fecha, 'resultado': resultado,
  };

  bool get tieneContenido =>
      equipo.isNotEmpty || numero.isNotEmpty ||
      inspector.isNotEmpty || resultado.isNotEmpty;

  InspeccionRadiografica copyWith({
    String? equipo, String? numero, String? inicio, String? fin,
    String? curitaje, String? distanciaPulg, String? tiempo,
    String? inspector, String? fecha, String? resultado,
    List<FilaInspeccion>? filas,
  }) => InspeccionRadiografica(
    equipo: equipo ?? this.equipo, numero: numero ?? this.numero,
    inicio: inicio ?? this.inicio, fin: fin ?? this.fin,
    curitaje: curitaje ?? this.curitaje, distanciaPulg: distanciaPulg ?? this.distanciaPulg,
    tiempo: tiempo ?? this.tiempo,
    inspector: inspector ?? this.inspector, fecha: fecha ?? this.fecha,
    resultado: resultado ?? this.resultado,
    filas: filas ?? this.filas,
  );
}

class FilaInspeccion {
  final String operador;
  final String fecha;
  final String resultado;

  const FilaInspeccion({this.operador = '', this.fecha = '', this.resultado = ''});

  factory FilaInspeccion.fromMap(Map<String, dynamic> m) =>
      FilaInspeccion(operador: m['operador'] ?? '', fecha: m['fecha'] ?? '', resultado: m['resultado'] ?? '');

  Map<String, dynamic> toMap() => {'operador': operador, 'fecha': fecha, 'resultado': resultado};

  bool get tieneContenido => operador.isNotEmpty || fecha.isNotEmpty || resultado.isNotEmpty;
}
