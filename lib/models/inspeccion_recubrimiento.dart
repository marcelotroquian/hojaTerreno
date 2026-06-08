// lib/models/inspeccion_recubrimiento.dart

class InspeccionRecubrimiento {
  // ── 4.1 General ────────────────────────────────────────────────────────────
  final String tipo;
  final String material;
  final String inicio41;
  final String fin41;
  final String tipoAplicacion;
  final String prepSuperficie;
  final String resina;
  final String imprimanteAnticorrosivo;
  final String instrumento41;

  // ── 4.2 Espesores ──────────────────────────────────────────────────────────
  final String espesorMinimo;
  final String cantidadMedidas;
  final String inicio42;
  final String fin42;
  final String minimoEspesor;
  final String maximoEspesor;
  final String promedioEspesor;

  // ── 4.3 Ensayo de Porosidad ────────────────────────────────────────────────
  final String voltajeKV;
  final String instrumento43;
  final String inicio43;
  final String fin43;

  // ── Fila inspector/fecha/resultado ────────────────────────────────────────
  final String inspector;
  final String fecha;
  final String resultado;

  const InspeccionRecubrimiento({
    this.tipo = '', this.material = '', this.inicio41 = '', this.fin41 = '',
    this.tipoAplicacion = '', this.prepSuperficie = '',
    this.resina = '', this.imprimanteAnticorrosivo = '', this.instrumento41 = '',
    this.espesorMinimo = '', this.cantidadMedidas = '', this.inicio42 = '', this.fin42 = '',
    this.minimoEspesor = '', this.maximoEspesor = '', this.promedioEspesor = '',
    this.voltajeKV = '', this.instrumento43 = '', this.inicio43 = '', this.fin43 = '',
    this.inspector = '', this.fecha = '', this.resultado = '',
  });

  factory InspeccionRecubrimiento.fromMap(Map<String, dynamic> m) {
    return InspeccionRecubrimiento(
      tipo: m['tipo'] ?? '', material: m['material'] ?? '',
      inicio41: m['inicio41'] ?? '', fin41: m['fin41'] ?? '',
      tipoAplicacion: m['tipoAplicacion'] ?? '', prepSuperficie: m['prepSuperficie'] ?? '',
      resina: m['resina'] ?? '', imprimanteAnticorrosivo: m['imprimanteAnticorrosivo'] ?? '',
      instrumento41: m['instrumento41'] ?? '',
      espesorMinimo: m['espesorMinimo'] ?? '', cantidadMedidas: m['cantidadMedidas'] ?? '',
      inicio42: m['inicio42'] ?? '', fin42: m['fin42'] ?? '',
      minimoEspesor: m['minimoEspesor'] ?? '', maximoEspesor: m['maximoEspesor'] ?? '',
      promedioEspesor: m['promedioEspesor'] ?? '',
      voltajeKV: m['voltajeKV'] ?? '', instrumento43: m['instrumento43'] ?? '',
      inicio43: m['inicio43'] ?? '', fin43: m['fin43'] ?? '',
      inspector: m['inspector'] ?? '', fecha: m['fecha'] ?? '', resultado: m['resultado'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'tipo': tipo, 'material': material, 'inicio41': inicio41, 'fin41': fin41,
    'tipoAplicacion': tipoAplicacion, 'prepSuperficie': prepSuperficie,
    'resina': resina, 'imprimanteAnticorrosivo': imprimanteAnticorrosivo,
    'instrumento41': instrumento41,
    'espesorMinimo': espesorMinimo, 'cantidadMedidas': cantidadMedidas,
    'inicio42': inicio42, 'fin42': fin42,
    'minimoEspesor': minimoEspesor, 'maximoEspesor': maximoEspesor,
    'promedioEspesor': promedioEspesor,
    'voltajeKV': voltajeKV, 'instrumento43': instrumento43,
    'inicio43': inicio43, 'fin43': fin43,
    'inspector': inspector, 'fecha': fecha, 'resultado': resultado,
  };

  bool get tieneContenido =>
      tipo.isNotEmpty || material.isNotEmpty || espesorMinimo.isNotEmpty || inspector.isNotEmpty;
}
