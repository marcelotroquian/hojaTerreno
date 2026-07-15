// lib/widgets/secciones_hoja_widget.dart
// Botones de acceso a las 4 secciones de la hoja, en orden 1-2-3-4.

import 'package:flutter/material.dart';
import '../models/inspeccion_radiografica.dart';
import '../models/inspeccion_fabricacion.dart';
import '../models/prueba_hermeticidad.dart';
import '../models/inspeccion_recubrimiento.dart';
import '../models/verificacion_accesorios.dart';
import '../models/placa_identificacion.dart';
import '../screens/inspeccion_radiografica_screen.dart';
import '../screens/inspeccion_fabricacion_screen.dart';
import '../screens/prueba_hermeticidad_screen.dart';
import '../screens/inspeccion_recubrimiento_screen.dart';
import '../screens/verificacion_accesorios_screen.dart';
import '../screens/placa_identificacion_screen.dart';

class SeccionesHojaWidget extends StatelessWidget {
  final String? hojaId;
  final InspeccionRadiografica radiografica;
  final InspeccionFabricacion fabricacion;
  final PruebaHermeticidad hermeticidad;
  final InspeccionRecubrimiento recubrimiento;
  final VerificacionAccesorios accesorios;
  final PlacaIdentificacion placa;
  final ValueChanged<InspeccionRadiografica> onRadiograficaChanged;
  final ValueChanged<InspeccionFabricacion> onFabricacionChanged;
  final ValueChanged<PruebaHermeticidad> onHermeticidadChanged;
  final ValueChanged<InspeccionRecubrimiento> onRecubrimientoChanged;
  final ValueChanged<VerificacionAccesorios> onAccesoriosChanged;
  final ValueChanged<PlacaIdentificacion> onPlacaChanged;

  const SeccionesHojaWidget({
    super.key,
    this.hojaId,
    required this.radiografica,
    required this.fabricacion,
    required this.hermeticidad,
    required this.recubrimiento,
    required this.accesorios,
    required this.placa,
    required this.onRadiograficaChanged,
    required this.onFabricacionChanged,
    required this.onHermeticidadChanged,
    required this.onRecubrimientoChanged,
    required this.onAccesoriosChanged,
    required this.onPlacaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Radiográfica
        _SeccionBtn(
          numero: '1', titulo: 'Inspección Radiográfica',
          subtitulo: 'Equipo, operador, resultados',
          icono: Icons.radio_button_checked_rounded,
          completada: radiografica.estaCompleto, color: Colors.indigo,
          onTap: () async {
            final r = await Navigator.push<InspeccionRadiografica>(context,
              MaterialPageRoute(builder: (_) => InspeccionRadiograficaScreen(hojaId: hojaId, datosIniciales: radiografica)));
            if (r != null) onRadiograficaChanged(r);
          },
        ),
        const SizedBox(height: 10),

        // 2. Fabricación
        _SeccionBtn(
          numero: '2', titulo: 'Inspección de Fabricación',
          subtitulo: 'Materiales, visual, dimensional, soldaduras',
          icono: Icons.precision_manufacturing_rounded,
          completada: fabricacion.estaCompleto, color: Colors.deepPurple,
          onTap: () async {
            final r = await Navigator.push<InspeccionFabricacion>(context,
              MaterialPageRoute(builder: (_) => InspeccionFabricacionScreen(hojaId: hojaId, datosIniciales: fabricacion)));
            if (r != null) onFabricacionChanged(r);
          },
        ),
        const SizedBox(height: 10),

        // 3. Hermeticidad
        _SeccionBtn(
          numero: '3', titulo: 'Prueba de Hermeticidad',
          subtitulo: 'Tanque, serpentín, mamparos',
          icono: Icons.water_drop_rounded,
          completada: hermeticidad.estaCompleto, color: Colors.blue,
          onTap: () async {
            final r = await Navigator.push<PruebaHermeticidad>(context,
              MaterialPageRoute(builder: (_) => PruebaHermeticidadScreen(hojaId: hojaId, datosIniciales: hermeticidad)));
            if (r != null) onHermeticidadChanged(r);
          },
        ),
        const SizedBox(height: 10),

        // 4. Recubrimiento
        _SeccionBtn(
          numero: '4', titulo: 'Recubrimiento / Revestimiento',
          subtitulo: 'General, espesores, porosidad',
          icono: Icons.layers_rounded,
          completada: recubrimiento.estaCompleto, color: Colors.teal,
          onTap: () async {
            final r = await Navigator.push<InspeccionRecubrimiento>(context,
              MaterialPageRoute(builder: (_) => InspeccionRecubrimientoScreen(hojaId: hojaId, datosIniciales: recubrimiento)));
            if (r != null) onRecubrimientoChanged(r);
          },
        ),
        const SizedBox(height: 10),

        // 5. Verificación Accesorios
        _SeccionBtn(
          numero: '5', titulo: 'Verificación Accesorios',
          subtitulo: 'Presión y vacío esp. interst.',
          icono: Icons.build_rounded,
          completada: accesorios.estaCompleto, color: Colors.orange,
          onTap: () async {
            final r = await Navigator.push<VerificacionAccesorios>(context,
              MaterialPageRoute(builder: (_) => VerificacionAccesoriosScreen(hojaId: hojaId, datosIniciales: accesorios)));
            if (r != null) onAccesoriosChanged(r);
          },
        ),
        const SizedBox(height: 10),

        // 6. Placa de Identificación
        _SeccionBtn(
          numero: '6', titulo: 'Placa de Identificación',
          subtitulo: 'Ubicación, cuño, certificado',
          icono: Icons.badge_rounded,
          completada: placa.estaCompleto, color: Colors.brown,
          onTap: () async {
            final r = await Navigator.push<PlacaIdentificacion>(context,
              MaterialPageRoute(builder: (_) => PlacaIdentificacionScreen(hojaId: hojaId, datosIniciales: placa)));
            if (r != null) onPlacaChanged(r);
          },
        ),
      ],
    );
  }
}

class _SeccionBtn extends StatelessWidget {
  final String numero, titulo, subtitulo;
  final IconData icono;
  final bool completada;
  final MaterialColor color;
  final VoidCallback onTap;

  const _SeccionBtn({
    required this.numero, required this.titulo, required this.subtitulo,
    required this.icono, required this.completada, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: completada ? color.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: completada ? color.shade300 : Colors.grey.shade200, width: completada ? 1.5 : 1),
          boxShadow: [BoxShadow(color: completada ? color.withOpacity(0.08) : Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: completada ? color.shade100 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Icon(icono, color: completada ? color.shade600 : Colors.grey.shade400, size: 22),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: completada ? color.shade600 : Colors.grey.shade400, shape: BoxShape.circle),
                child: Text(numero, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: completada ? color.shade800 : const Color(0xFF374151))),
                const SizedBox(height: 2),
                Text(subtitulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: completada ? color.shade100 : Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                child: Text(completada ? 'Completado' : 'Pendiente',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: completada ? color.shade700 : Colors.grey.shade500)),
              ),
              const SizedBox(height: 4),
              Icon(Icons.chevron_right_rounded, color: completada ? color.shade400 : Colors.grey.shade300, size: 18),
            ],
          ),
        ]),
      ),
    );
  }
}
