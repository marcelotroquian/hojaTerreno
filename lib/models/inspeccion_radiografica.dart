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

  // ── 2. Filas de operador/fecha/resultado (hasta 5 filas) ──────────────────
  final List<FilaInspeccion> filas;

  const InspeccionRadiografica({
    this.equipo = '',
    this.numero = '',
    this.inicio = '',
    this.fin = '',
    this.curitaje = '',
    this.distanciaPulg = '',
    this.tiempo = '',
    this.filas = const [],
  });

  factory InspeccionRadiografica.fromMap(Map<String, dynamic> m) {
    return InspeccionRadiografica(
      equipo:         m['equipo'] ?? '',
      numero:         m['numero'] ?? '',
      inicio:         m['inicio'] ?? '',
      fin:            m['fin'] ?? '',
      curitaje:       m['curitaje'] ?? '',
      distanciaPulg:  m['distanciaPulg'] ?? '',
      tiempo:         m['tiempo'] ?? '',
      filas: (m['filas'] as List<dynamic>? ?? [])
          .map((f) => FilaInspeccion.fromMap(Map<String, dynamic>.from(f)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'equipo': equipo, 'numero': numero, 'inicio': inicio, 'fin': fin,
    'curitaje': curitaje, 'distanciaPulg': distanciaPulg, 'tiempo': tiempo,
    'filas': filas.map((f) => f.toMap()).toList(),
  };

  bool get tieneContenido =>
      equipo.isNotEmpty || numero.isNotEmpty || filas.any((f) => f.tieneContenido);

  InspeccionRadiografica copyWith({
    String? equipo, String? numero, String? inicio, String? fin,
    String? curitaje, String? distanciaPulg, String? tiempo,
    List<FilaInspeccion>? filas,
  }) => InspeccionRadiografica(
    equipo: equipo ?? this.equipo, numero: numero ?? this.numero,
    inicio: inicio ?? this.inicio, fin: fin ?? this.fin,
    curitaje: curitaje ?? this.curitaje, distanciaPulg: distanciaPulg ?? this.distanciaPulg,
    tiempo: tiempo ?? this.tiempo, filas: filas ?? this.filas,
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
