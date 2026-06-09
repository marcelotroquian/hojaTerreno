// lib/models/hoja_terreno.dart
// Modelo que representa una Hoja de Terreno en Firestore

enum TipoInspeccion { periodica, fabricacion }

// Opciones de tipo de tanque (checkboxes múltiples — se pueden combinar)
enum TipoTanque {
  horizontal, vertical, superficie, enterrado,
  semiremolque, sobrecamion, remolque,
}

extension TipoTanqueLabel on TipoTanque {
  String get label {
    switch (this) {
      case TipoTanque.horizontal:   return 'Horizontal';
      case TipoTanque.vertical:     return 'Vertical';
      case TipoTanque.superficie:   return 'Superficie';
      case TipoTanque.enterrado:    return 'Enterrado';
      case TipoTanque.semiremolque: return 'Semiremolque';
      case TipoTanque.sobrecamion:  return 'Sobrecamión';
      case TipoTanque.remolque:     return 'Remolque';
    }
  }
}

class HojaTerreno {
  final String id;
  final String codigoHDT;   // Código legible: HDT-2026-0001 (o BORRADOR-xxx)
  final bool sincronizada;  // false = creada offline, pendiente de código real
  final String creadaPor;
  final String creadaPorNombre;
  final DateTime creadaEn;
  final DateTime modificadaEn;

  // ── Campos del formulario ──────────────────────────────────────────────────
  final String tanqueNumero;
  final String serieNumero;
  final String certificadoNumero;
  final String patenteNumero;
  final String planoNumero;
  final String cliente;
  final String maestranza;              // NUEVO
  final String capacidad;
  final String material;                // NUEVO
  final TipoInspeccion tipoInspeccion;
  final String certificadoAnterior;     // NUEVO
  final String normaAplicada;
  final String protocoloNumero;
  final String numeroChassisVin;        // NUEVO
  final String patenteVehiculo;         // NUEVO (Patente bajo Chassis/VIN)
  final Set<TipoTanque> tiposTanque;    // NUEVO (checkboxes múltiples)

  const HojaTerreno({
    required this.id,
    this.codigoHDT = '',
    this.sincronizada = true,
    required this.creadaPor,
    required this.creadaPorNombre,
    required this.creadaEn,
    required this.modificadaEn,
    this.tanqueNumero = '',
    this.serieNumero = '',
    this.certificadoNumero = '',
    this.patenteNumero = '',
    this.planoNumero = '',
    this.cliente = '',
    this.maestranza = '',
    this.capacidad = '',
    this.material = '',
    this.tipoInspeccion = TipoInspeccion.periodica,
    this.certificadoAnterior = '',
    this.normaAplicada = '',
    this.protocoloNumero = '',
    this.numeroChassisVin = '',
    this.patenteVehiculo = '',
    this.tiposTanque = const {},
  });

  // ─── Desde Firestore ───────────────────────────────────────────────────────
  factory HojaTerreno.fromFirestore(Map<String, dynamic> data, String id) {
    // Deserializar el set de tipos de tanque desde lista de strings
    final tiposRaw = data['tiposTanque'] as List<dynamic>? ?? [];
    final tipos = tiposRaw
        .map((t) => TipoTanque.values.firstWhere(
              (e) => e.name == t,
              orElse: () => TipoTanque.horizontal,
            ))
        .toSet();

    return HojaTerreno(
      id: id,
      codigoHDT: data['codigoHDT'] ?? '',
      sincronizada: data['sincronizada'] ?? true,
      creadaPor: data['creadaPor'] ?? '',
      creadaPorNombre: data['creadaPorNombre'] ?? '',
      creadaEn: DateTime.fromMillisecondsSinceEpoch(data['creadaEn'] ?? 0),
      modificadaEn: DateTime.fromMillisecondsSinceEpoch(data['modificadaEn'] ?? 0),
      tanqueNumero: data['tanqueNumero'] ?? '',
      serieNumero: data['serieNumero'] ?? '',
      certificadoNumero: data['certificadoNumero'] ?? '',
      patenteNumero: data['patenteNumero'] ?? '',
      planoNumero: data['planoNumero'] ?? '',
      cliente: data['cliente'] ?? '',
      maestranza: data['maestranza'] ?? '',
      capacidad: data['capacidad'] ?? '',
      material: data['material'] ?? '',
      tipoInspeccion: data['tipoInspeccion'] == 'fabricacion'
          ? TipoInspeccion.fabricacion
          : TipoInspeccion.periodica,
      certificadoAnterior: data['certificadoAnterior'] ?? '',
      normaAplicada: data['normaAplicada'] ?? '',
      protocoloNumero: data['protocoloNumero'] ?? '',
      numeroChassisVin: data['numeroChassisVin'] ?? '',
      patenteVehiculo: data['patenteVehiculo'] ?? '',
      tiposTanque: tipos,
    );
  }

  // ─── A Firestore ───────────────────────────────────────────────────────────
  Map<String, dynamic> toFirestore() {
    return {
      'creadaPor': creadaPor,
      'codigoHDT': codigoHDT,
      'sincronizada': sincronizada,
      'creadaPorNombre': creadaPorNombre,
      'creadaEn': creadaEn.millisecondsSinceEpoch,
      'modificadaEn': modificadaEn.millisecondsSinceEpoch,
      'tanqueNumero': tanqueNumero,
      'serieNumero': serieNumero,
      'certificadoNumero': certificadoNumero,
      'patenteNumero': patenteNumero,
      'planoNumero': planoNumero,
      'cliente': cliente,
      'maestranza': maestranza,
      'capacidad': capacidad,
      'material': material,
      'tipoInspeccion': tipoInspeccion == TipoInspeccion.fabricacion
          ? 'fabricacion'
          : 'periodica',
      'certificadoAnterior': certificadoAnterior,
      'normaAplicada': normaAplicada,
      'protocoloNumero': protocoloNumero,
      'numeroChassisVin': numeroChassisVin,
      'patenteVehiculo': patenteVehiculo,
      // Guardar set como lista de strings
      'tiposTanque': tiposTanque.map((t) => t.name).toList(),
    };
  }

  // ─── Copia con campos modificados ─────────────────────────────────────────
  HojaTerreno copyWith({
    String? tanqueNumero,
    String? serieNumero,
    String? certificadoNumero,
    String? patenteNumero,
    String? planoNumero,
    String? cliente,
    String? maestranza,
    String? capacidad,
    String? material,
    TipoInspeccion? tipoInspeccion,
    String? certificadoAnterior,
    String? normaAplicada,
    String? protocoloNumero,
    String? numeroChassisVin,
    String? patenteVehiculo,
    Set<TipoTanque>? tiposTanque,
  }) {
    return HojaTerreno(
      id: id,
      codigoHDT: codigoHDT,
      sincronizada: sincronizada,
      creadaPor: creadaPor,
      creadaPorNombre: creadaPorNombre,
      creadaEn: creadaEn,
      modificadaEn: DateTime.now(),
      tanqueNumero: tanqueNumero ?? this.tanqueNumero,
      serieNumero: serieNumero ?? this.serieNumero,
      certificadoNumero: certificadoNumero ?? this.certificadoNumero,
      patenteNumero: patenteNumero ?? this.patenteNumero,
      planoNumero: planoNumero ?? this.planoNumero,
      cliente: cliente ?? this.cliente,
      maestranza: maestranza ?? this.maestranza,
      capacidad: capacidad ?? this.capacidad,
      material: material ?? this.material,
      tipoInspeccion: tipoInspeccion ?? this.tipoInspeccion,
      certificadoAnterior: certificadoAnterior ?? this.certificadoAnterior,
      normaAplicada: normaAplicada ?? this.normaAplicada,
      protocoloNumero: protocoloNumero ?? this.protocoloNumero,
      numeroChassisVin: numeroChassisVin ?? this.numeroChassisVin,
      patenteVehiculo: patenteVehiculo ?? this.patenteVehiculo,
      tiposTanque: tiposTanque ?? this.tiposTanque,
    );
  }

  String get titulo =>
      tanqueNumero.isNotEmpty ? 'Tanque Nº $tanqueNumero' : 'Sin número';

  String get subtitulo =>
      cliente.isNotEmpty ? cliente : 'Sin cliente asignado';
}
