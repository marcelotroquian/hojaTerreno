// lib/models/prueba_hermeticidad.dart
// Sección 3: PRUEBA DE HERMETICIDAD O ESTANQUEIDAD

class PruebaHermeticidad {
  final String inicio;
  final String fin;

  // 3.1 Presión Insp. Tanque
  final String presionTanque;       // psi
  final String manometroTanque;
  final String rangoTanque;         // psi
  final String tiempoTanque;        // Min.

  // 3.2 Presión Insp. Serpentín
  final String presionSerpentin;    // psi
  final String manometroSerpentin;
  final String rangoSerpentin;      // psi
  final String tiempoSerpentin;     // Min.

  // 3.3 Presión Mamparos
  final String presionMamparos;     // psi
  final String manometroMamparos;
  final String rangoMamparos;       // psi
  final String tiempoMamparos;      // Min.

  // Inspector / Fecha / Resultado
  final String inspector;
  final String fecha;
  final String resultado;

  const PruebaHermeticidad({
    this.inicio = '', this.fin = '',
    this.presionTanque = '', this.manometroTanque = '', this.rangoTanque = '', this.tiempoTanque = '',
    this.presionSerpentin = '', this.manometroSerpentin = '', this.rangoSerpentin = '', this.tiempoSerpentin = '',
    this.presionMamparos = '', this.manometroMamparos = '', this.rangoMamparos = '', this.tiempoMamparos = '',
    this.inspector = '', this.fecha = '', this.resultado = '',
  });

  factory PruebaHermeticidad.fromMap(Map<String, dynamic> m) {
    String s(String k) => m[k] ?? '';
    return PruebaHermeticidad(
      inicio: s('inicio'), fin: s('fin'),
      presionTanque: s('presionTanque'), manometroTanque: s('manometroTanque'),
      rangoTanque: s('rangoTanque'), tiempoTanque: s('tiempoTanque'),
      presionSerpentin: s('presionSerpentin'), manometroSerpentin: s('manometroSerpentin'),
      rangoSerpentin: s('rangoSerpentin'), tiempoSerpentin: s('tiempoSerpentin'),
      presionMamparos: s('presionMamparos'), manometroMamparos: s('manometroMamparos'),
      rangoMamparos: s('rangoMamparos'), tiempoMamparos: s('tiempoMamparos'),
      inspector: s('inspector'), fecha: s('fecha'), resultado: s('resultado'),
    );
  }

  Map<String, dynamic> toMap() => {
    'inicio': inicio, 'fin': fin,
    'presionTanque': presionTanque, 'manometroTanque': manometroTanque,
    'rangoTanque': rangoTanque, 'tiempoTanque': tiempoTanque,
    'presionSerpentin': presionSerpentin, 'manometroSerpentin': manometroSerpentin,
    'rangoSerpentin': rangoSerpentin, 'tiempoSerpentin': tiempoSerpentin,
    'presionMamparos': presionMamparos, 'manometroMamparos': manometroMamparos,
    'rangoMamparos': rangoMamparos, 'tiempoMamparos': tiempoMamparos,
    'inspector': inspector, 'fecha': fecha, 'resultado': resultado,
  };

  bool get tieneContenido =>
      presionTanque.isNotEmpty || presionSerpentin.isNotEmpty ||
      presionMamparos.isNotEmpty || inspector.isNotEmpty;

  // Completo: resultado elegido (OK/No Conforme) y horas puestas
  bool get estaCompleto =>
      resultado.isNotEmpty && inicio.isNotEmpty && fin.isNotEmpty;
}
