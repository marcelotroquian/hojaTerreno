// lib/models/inspeccion_fabricacion.dart
// Sección 2: INSPECCIÓN DE FABRICACIÓN (la más extensa)

class InspeccionFabricacion {
  // ── 2.1 Materiales (checkboxes) ─────────────────────────────────────────────
  final bool certificadoMateriales;
  final bool plano;
  final bool fichaTecnica;
  final String inicio21;
  final String fin21;

  // ── 2.2 Inspección Visual ──────────────────────────────────────────────────
  // Manto: cilíndrico / elíptico (exclusivo) + válvula de fondo (texto)
  final String mantoForma;          // 'cilindrico' | 'eliptico' | ''
  final String valvulaFondo;
  final String inicioManto;
  final String finManto;

  // Cabezal: bombeado / cónico / plano / curvo trazado (exclusivo) + inicio/fin
  final String cabezalForma;        // 'bombeado'|'conico'|'plano'|'curvo'|''
  final String inicioCabezal;
  final String finCabezal;

  // Campos de texto adicionales de 2.2
  final String conformadoManto;
  final String conformadoCabezales;
  final String estabilidadAB;
  final String refuerzoReglaMedicion;
  final String venteoCuello;
  final String pernoRey;

  // ── 2.3 Control Dimensional ─────────────────────────────────────────────────
  final String huinchaPerimetral;
  final String huinchaConvencional;
  final String largoExterior;       // mm
  final String perimetro;           // mm
  final String largoPestana;        // mm
  final String alturaMantoBrida;    // mm
  final String inicio23;
  final String fin23;
  final String cabezal1;            // mm
  final String cabezal2;            // mm
  final String diamInteriorCuello;  // Ø int. Cuello

  // ── 2.4 Inspección Conexiones / Venteos ────────────────────────────────────
  final String venteoNormal;
  final String venteoEmergencia;
  final String tipoConexiones;
  final String tamanos;
  final String material24;
  final String inicio24;
  final String fin24;

  // ── 2.5 Inspección Soldaduras ───────────────────────────────────────────────
  final String soldLongitudinales;
  final String soldCircunferenciales;
  final String alineamientoSecciones;
  final String traslapoUnionesCircunf;
  final String soldaduraMantoCabezal;
  final String soldaduraEnCabezal;
  final String inicio25;
  final String fin25;
  final String soldaduraCuelloManto;
  final String soldaduraCuelloBrida;

  // ── Inspector / Fecha / Resultado ──────────────────────────────────────────
  final String inspector;
  final String fecha;
  final String resultado;

  const InspeccionFabricacion({
    this.certificadoMateriales = false,
    this.plano = false,
    this.fichaTecnica = false,
    this.inicio21 = '', this.fin21 = '',
    this.mantoForma = '', this.valvulaFondo = '',
    this.inicioManto = '', this.finManto = '',
    this.cabezalForma = '', this.inicioCabezal = '', this.finCabezal = '',
    this.conformadoManto = '', this.conformadoCabezales = '', this.estabilidadAB = '',
    this.refuerzoReglaMedicion = '', this.venteoCuello = '', this.pernoRey = '',
    this.huinchaPerimetral = '', this.huinchaConvencional = '',
    this.largoExterior = '', this.perimetro = '', this.largoPestana = '',
    this.alturaMantoBrida = '', this.inicio23 = '', this.fin23 = '',
    this.cabezal1 = '', this.cabezal2 = '', this.diamInteriorCuello = '',
    this.venteoNormal = '', this.venteoEmergencia = '', this.tipoConexiones = '',
    this.tamanos = '', this.material24 = '', this.inicio24 = '', this.fin24 = '',
    this.soldLongitudinales = '', this.soldCircunferenciales = '',
    this.alineamientoSecciones = '', this.traslapoUnionesCircunf = '',
    this.soldaduraMantoCabezal = '', this.soldaduraEnCabezal = '',
    this.inicio25 = '', this.fin25 = '',
    this.soldaduraCuelloManto = '', this.soldaduraCuelloBrida = '',
    this.inspector = '', this.fecha = '', this.resultado = '',
  });

  factory InspeccionFabricacion.fromMap(Map<String, dynamic> m) {
    String s(String k) => m[k] ?? '';
    bool b(String k) => m[k] ?? false;
    return InspeccionFabricacion(
      certificadoMateriales: b('certificadoMateriales'), plano: b('plano'), fichaTecnica: b('fichaTecnica'),
      inicio21: s('inicio21'), fin21: s('fin21'),
      mantoForma: s('mantoForma'), valvulaFondo: s('valvulaFondo'),
      inicioManto: s('inicioManto'), finManto: s('finManto'),
      cabezalForma: s('cabezalForma'), inicioCabezal: s('inicioCabezal'), finCabezal: s('finCabezal'),
      conformadoManto: s('conformadoManto'), conformadoCabezales: s('conformadoCabezales'),
      estabilidadAB: s('estabilidadAB'), refuerzoReglaMedicion: s('refuerzoReglaMedicion'),
      venteoCuello: s('venteoCuello'), pernoRey: s('pernoRey'),
      huinchaPerimetral: s('huinchaPerimetral'), huinchaConvencional: s('huinchaConvencional'),
      largoExterior: s('largoExterior'), perimetro: s('perimetro'), largoPestana: s('largoPestana'),
      alturaMantoBrida: s('alturaMantoBrida'), inicio23: s('inicio23'), fin23: s('fin23'),
      cabezal1: s('cabezal1'), cabezal2: s('cabezal2'), diamInteriorCuello: s('diamInteriorCuello'),
      venteoNormal: s('venteoNormal'), venteoEmergencia: s('venteoEmergencia'),
      tipoConexiones: s('tipoConexiones'), tamanos: s('tamanos'), material24: s('material24'),
      inicio24: s('inicio24'), fin24: s('fin24'),
      soldLongitudinales: s('soldLongitudinales'), soldCircunferenciales: s('soldCircunferenciales'),
      alineamientoSecciones: s('alineamientoSecciones'), traslapoUnionesCircunf: s('traslapoUnionesCircunf'),
      soldaduraMantoCabezal: s('soldaduraMantoCabezal'), soldaduraEnCabezal: s('soldaduraEnCabezal'),
      inicio25: s('inicio25'), fin25: s('fin25'),
      soldaduraCuelloManto: s('soldaduraCuelloManto'), soldaduraCuelloBrida: s('soldaduraCuelloBrida'),
      inspector: s('inspector'), fecha: s('fecha'), resultado: s('resultado'),
    );
  }

  Map<String, dynamic> toMap() => {
    'certificadoMateriales': certificadoMateriales, 'plano': plano, 'fichaTecnica': fichaTecnica,
    'inicio21': inicio21, 'fin21': fin21,
    'mantoForma': mantoForma, 'valvulaFondo': valvulaFondo,
    'inicioManto': inicioManto, 'finManto': finManto,
    'cabezalForma': cabezalForma, 'inicioCabezal': inicioCabezal, 'finCabezal': finCabezal,
    'conformadoManto': conformadoManto, 'conformadoCabezales': conformadoCabezales,
    'estabilidadAB': estabilidadAB, 'refuerzoReglaMedicion': refuerzoReglaMedicion,
    'venteoCuello': venteoCuello, 'pernoRey': pernoRey,
    'huinchaPerimetral': huinchaPerimetral, 'huinchaConvencional': huinchaConvencional,
    'largoExterior': largoExterior, 'perimetro': perimetro, 'largoPestana': largoPestana,
    'alturaMantoBrida': alturaMantoBrida, 'inicio23': inicio23, 'fin23': fin23,
    'cabezal1': cabezal1, 'cabezal2': cabezal2, 'diamInteriorCuello': diamInteriorCuello,
    'venteoNormal': venteoNormal, 'venteoEmergencia': venteoEmergencia,
    'tipoConexiones': tipoConexiones, 'tamanos': tamanos, 'material24': material24,
    'inicio24': inicio24, 'fin24': fin24,
    'soldLongitudinales': soldLongitudinales, 'soldCircunferenciales': soldCircunferenciales,
    'alineamientoSecciones': alineamientoSecciones, 'traslapoUnionesCircunf': traslapoUnionesCircunf,
    'soldaduraMantoCabezal': soldaduraMantoCabezal, 'soldaduraEnCabezal': soldaduraEnCabezal,
    'inicio25': inicio25, 'fin25': fin25,
    'soldaduraCuelloManto': soldaduraCuelloManto, 'soldaduraCuelloBrida': soldaduraCuelloBrida,
    'inspector': inspector, 'fecha': fecha, 'resultado': resultado,
  };

  bool get tieneContenido =>
      certificadoMateriales || plano || fichaTecnica ||
      mantoForma.isNotEmpty || cabezalForma.isNotEmpty ||
      largoExterior.isNotEmpty || tipoConexiones.isNotEmpty ||
      soldLongitudinales.isNotEmpty || inspector.isNotEmpty;

  // Completo: resultado elegido (OK/No Conforme) y horas puestas
  bool get estaCompleto =>
      resultado.isNotEmpty;
}
