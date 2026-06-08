// lib/models/placa_identificacion.dart
// Sección 6: PLACA DE IDENTIFICACIÓN

class PlacaIdentificacion {
  final String ubicacion;

  // Checkboxes
  final bool verificacionDatos;
  final bool cunoIII;                       // "Cuño III"
  final bool numeroCertificadoAcunado;      // "Número de Certificado acuñado en copla"

  final String inicio;
  final String fin;

  // Inspector / Fecha / Resultado
  final String inspector;
  final String fecha;
  final String resultado;

  const PlacaIdentificacion({
    this.ubicacion = '',
    this.verificacionDatos = false,
    this.cunoIII = false,
    this.numeroCertificadoAcunado = false,
    this.inicio = '', this.fin = '',
    this.inspector = '', this.fecha = '', this.resultado = '',
  });

  factory PlacaIdentificacion.fromMap(Map<String, dynamic> m) {
    String s(String k) => m[k] ?? '';
    bool b(String k) => m[k] ?? false;
    return PlacaIdentificacion(
      ubicacion: s('ubicacion'),
      verificacionDatos: b('verificacionDatos'),
      cunoIII: b('cunoIII'),
      numeroCertificadoAcunado: b('numeroCertificadoAcunado'),
      inicio: s('inicio'), fin: s('fin'),
      inspector: s('inspector'), fecha: s('fecha'), resultado: s('resultado'),
    );
  }

  Map<String, dynamic> toMap() => {
    'ubicacion': ubicacion,
    'verificacionDatos': verificacionDatos,
    'cunoIII': cunoIII,
    'numeroCertificadoAcunado': numeroCertificadoAcunado,
    'inicio': inicio, 'fin': fin,
    'inspector': inspector, 'fecha': fecha, 'resultado': resultado,
  };

  bool get tieneContenido =>
      ubicacion.isNotEmpty || verificacionDatos || cunoIII ||
      numeroCertificadoAcunado || inspector.isNotEmpty;
}
