// lib/models/verificacion_accesorios.dart
// Sección 5: VERIFICACIÓN ACCESORIOS

class VerificacionAccesorios {
  // Presión Esp. Interst. (psig)
  final String presionEsp;        // psig
  final String instrumentoPresion;
  final String rangoPresion;
  final String inicioPresion;
  final String finPresion;

  // Vacío esp. Interst. (inHg)
  final String vacioEsp;          // inHg
  final String instrumentoVacio;
  final String rangoVacio;
  final String inicioVacio;
  final String finVacio;

  // Inspector / Fecha / Resultado
  final String inspector;
  final String fecha;
  final String resultado;

  const VerificacionAccesorios({
    this.presionEsp = '', this.instrumentoPresion = '', this.rangoPresion = '',
    this.inicioPresion = '', this.finPresion = '',
    this.vacioEsp = '', this.instrumentoVacio = '', this.rangoVacio = '',
    this.inicioVacio = '', this.finVacio = '',
    this.inspector = '', this.fecha = '', this.resultado = '',
  });

  factory VerificacionAccesorios.fromMap(Map<String, dynamic> m) {
    String s(String k) => m[k] ?? '';
    return VerificacionAccesorios(
      presionEsp: s('presionEsp'), instrumentoPresion: s('instrumentoPresion'),
      rangoPresion: s('rangoPresion'), inicioPresion: s('inicioPresion'), finPresion: s('finPresion'),
      vacioEsp: s('vacioEsp'), instrumentoVacio: s('instrumentoVacio'),
      rangoVacio: s('rangoVacio'), inicioVacio: s('inicioVacio'), finVacio: s('finVacio'),
      inspector: s('inspector'), fecha: s('fecha'), resultado: s('resultado'),
    );
  }

  Map<String, dynamic> toMap() => {
    'presionEsp': presionEsp, 'instrumentoPresion': instrumentoPresion,
    'rangoPresion': rangoPresion, 'inicioPresion': inicioPresion, 'finPresion': finPresion,
    'vacioEsp': vacioEsp, 'instrumentoVacio': instrumentoVacio,
    'rangoVacio': rangoVacio, 'inicioVacio': inicioVacio, 'finVacio': finVacio,
    'inspector': inspector, 'fecha': fecha, 'resultado': resultado,
  };

  bool get tieneContenido =>
      presionEsp.isNotEmpty || vacioEsp.isNotEmpty || inspector.isNotEmpty;
}
