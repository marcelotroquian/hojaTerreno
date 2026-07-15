// lib/screens/prueba_hermeticidad_screen.dart
// Sección 3: Prueba de Hermeticidad o Estanqueidad

import 'package:flutter/material.dart';
import '../models/prueba_hermeticidad.dart';
import '../services/secciones_service.dart';
import '../widgets/seccion_header.dart';
import '../widgets/campos_ensayo.dart';

class PruebaHermeticidadScreen extends StatefulWidget {
  final String? hojaId;
  final PruebaHermeticidad datosIniciales;

  const PruebaHermeticidadScreen({
    super.key,
    this.hojaId,
    this.datosIniciales = const PruebaHermeticidad(),
  });

  bool get esModoLocal => hojaId == null;

  @override
  State<PruebaHermeticidadScreen> createState() => _PruebaHermeticidadScreenState();
}

class _PruebaHermeticidadScreenState extends State<PruebaHermeticidadScreen> {
  late final TextEditingController _inicioCtrl;
  late final TextEditingController _finCtrl;

  // 3.1 Tanque
  late final TextEditingController _presionTanqueCtrl;
  late final TextEditingController _manometroTanqueCtrl;
  late final TextEditingController _rangoTanqueCtrl;
  late final TextEditingController _tiempoTanqueCtrl;
  // 3.2 Serpentín
  late final TextEditingController _presionSerpentinCtrl;
  late final TextEditingController _manometroSerpentinCtrl;
  late final TextEditingController _rangoSerpentinCtrl;
  late final TextEditingController _tiempoSerpentinCtrl;
  // 3.3 Mamparos
  late final TextEditingController _presionMamparosCtrl;
  late final TextEditingController _manometroMamparosCtrl;
  late final TextEditingController _rangoMamparosCtrl;
  late final TextEditingController _tiempoMamparosCtrl;
  // Inspector
  late final TextEditingController _inspectorCtrl;
  late final TextEditingController _fechaCtrl;
  late final TextEditingController _resultadoCtrl;

  bool _isLoading = true;
  bool _isSaving  = false;

  @override
  void initState() {
    super.initState();
    if (widget.esModoLocal) {
      _initDesde(widget.datosIniciales);
    } else {
      _cargarDesdeFirestore();
    }
  }

  void _initDesde(PruebaHermeticidad d) {
    _inicioCtrl = TextEditingController(text: d.inicio);
    _finCtrl    = TextEditingController(text: d.fin);
    _presionTanqueCtrl     = TextEditingController(text: d.presionTanque);
    _manometroTanqueCtrl   = TextEditingController(text: d.manometroTanque);
    _rangoTanqueCtrl       = TextEditingController(text: d.rangoTanque);
    _tiempoTanqueCtrl      = TextEditingController(text: d.tiempoTanque);
    _presionSerpentinCtrl  = TextEditingController(text: d.presionSerpentin);
    _manometroSerpentinCtrl= TextEditingController(text: d.manometroSerpentin);
    _rangoSerpentinCtrl    = TextEditingController(text: d.rangoSerpentin);
    _tiempoSerpentinCtrl   = TextEditingController(text: d.tiempoSerpentin);
    _presionMamparosCtrl   = TextEditingController(text: d.presionMamparos);
    _manometroMamparosCtrl = TextEditingController(text: d.manometroMamparos);
    _rangoMamparosCtrl     = TextEditingController(text: d.rangoMamparos);
    _tiempoMamparosCtrl    = TextEditingController(text: d.tiempoMamparos);
    _inspectorCtrl = TextEditingController(text: d.inspector);
    _fechaCtrl     = TextEditingController(text: d.fecha);
    _resultadoCtrl = TextEditingController(text: d.resultado);
    // Autocompletar inspector (perfil) y fecha actual si están vacíos
    AutocompletarEnsayo.aplicar(inspector: _inspectorCtrl, fecha: _fechaCtrl);
    setState(() => _isLoading = false);
  }

  Future<void> _cargarDesdeFirestore() async {
    final datos = await SeccionesService.cargarHermeticidad(widget.hojaId!);
    if (mounted) _initDesde(datos);
  }

  @override
  void dispose() {
    for (final c in [
      _inicioCtrl, _finCtrl,
      _presionTanqueCtrl, _manometroTanqueCtrl, _rangoTanqueCtrl, _tiempoTanqueCtrl,
      _presionSerpentinCtrl, _manometroSerpentinCtrl, _rangoSerpentinCtrl, _tiempoSerpentinCtrl,
      _presionMamparosCtrl, _manometroMamparosCtrl, _rangoMamparosCtrl, _tiempoMamparosCtrl,
      _inspectorCtrl, _fechaCtrl, _resultadoCtrl,
    ]) c.dispose();
    super.dispose();
  }

  PruebaHermeticidad _leerFormulario() => PruebaHermeticidad(
    inicio: _inicioCtrl.text.trim(), fin: _finCtrl.text.trim(),
    presionTanque: _presionTanqueCtrl.text.trim(), manometroTanque: _manometroTanqueCtrl.text.trim(),
    rangoTanque: _rangoTanqueCtrl.text.trim(), tiempoTanque: _tiempoTanqueCtrl.text.trim(),
    presionSerpentin: _presionSerpentinCtrl.text.trim(), manometroSerpentin: _manometroSerpentinCtrl.text.trim(),
    rangoSerpentin: _rangoSerpentinCtrl.text.trim(), tiempoSerpentin: _tiempoSerpentinCtrl.text.trim(),
    presionMamparos: _presionMamparosCtrl.text.trim(), manometroMamparos: _manometroMamparosCtrl.text.trim(),
    rangoMamparos: _rangoMamparosCtrl.text.trim(), tiempoMamparos: _tiempoMamparosCtrl.text.trim(),
    inspector: _inspectorCtrl.text.trim(), fecha: _fechaCtrl.text.trim(), resultado: _resultadoCtrl.text.trim(),
  );

  Future<void> _guardar() async {
    // Validar horas: formato correcto y que inicio no sea mayor que fin
    final errorHoras = CamposEnsayo.validarPares([(_inicioCtrl, _finCtrl)]);
    if (errorHoras != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorHoras),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
      return;
    }
    final datos = _leerFormulario();
    if (widget.esModoLocal) { Navigator.pop(context, datos); return; }
    setState(() => _isSaving = true);
    final error = await SeccionesService.guardarHermeticidad(widget.hojaId!, datos);
    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? '¡Prueba guardada!'),
      backgroundColor: error != null ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
    if (error == null) Navigator.pop(context, datos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('3 - Prueba de Hermeticidad',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context, _leerFormulario()),
        ),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: Colors.grey.shade100)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SeccionHeader(numero: '3', titulo: 'PRUEBA DE HERMETICIDAD O ESTANQUEIDAD'),
                const SizedBox(height: 16),

                // Inicio / Fin generales
                Row(children: [
                  Expanded(child: CampoHora(controller: _inicioCtrl, label: 'Inicio')),
                  const SizedBox(width: 12),
                  Expanded(child: CampoHora(controller: _finCtrl, label: 'Fin')),
                  const Spacer(),
                ]),

                const SizedBox(height: 20),

                // ── 3.1 Tanque ─────────────────────────────────────────────
                _filaPrueba(
                  numero: '3.1',
                  titulo: 'Presión Insp. Tanque',
                  presion: _presionTanqueCtrl,
                  manometro: _manometroTanqueCtrl,
                  rango: _rangoTanqueCtrl,
                  tiempo: _tiempoTanqueCtrl,
                ),
                const SizedBox(height: 16),

                // ── 3.2 Serpentín ──────────────────────────────────────────
                _filaPrueba(
                  numero: '3.2',
                  titulo: 'Presión Insp. Serpentín',
                  presion: _presionSerpentinCtrl,
                  manometro: _manometroSerpentinCtrl,
                  rango: _rangoSerpentinCtrl,
                  tiempo: _tiempoSerpentinCtrl,
                ),
                const SizedBox(height: 16),

                // ── 3.3 Mamparos ───────────────────────────────────────────
                _filaPrueba(
                  numero: '3.3',
                  titulo: 'Presión Mamparos',
                  presion: _presionMamparosCtrl,
                  manometro: _manometroMamparosCtrl,
                  rango: _rangoMamparosCtrl,
                  tiempo: _tiempoMamparosCtrl,
                ),

                const SizedBox(height: 24),

                // Inspector / Fecha / Resultado
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.15)),
                  ),
                  child: Row(children: [
                    Expanded(child: _campo(_inspectorCtrl, 'Inspector')),
                    const SizedBox(width: 12),
                    Expanded(child: _campo(_fechaCtrl, 'Fecha')),
                    const SizedBox(width: 12),
                    Expanded(child: CampoResultado(controller: _resultadoCtrl)),
                  ]),
                ),

                const SizedBox(height: 32),
                _botonGuardar(),
              ],
            ),
    );
  }

  // Fila de una prueba: número + título + presión/manómetro/rango/tiempo
  Widget _filaPrueba({
    required String numero,
    required String titulo,
    required TextEditingController presion,
    required TextEditingController manometro,
    required TextEditingController rango,
    required TextEditingController tiempo,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
              ),
              child: Text(numero, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
            ),
            const SizedBox(width: 8),
            Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _campoSufijo(presion, 'Presión', 'psi')),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: _campo(manometro, 'Manómetro')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _campoSufijo(rango, 'Rango', 'psi')),
            const SizedBox(width: 10),
            Expanded(child: _campoSufijo(tiempo, 'Tiempo', 'Min.')),
          ]),
        ],
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 13),
          decoration: _decoration(),
        ),
      ],
    );
  }

  Widget _campoSufijo(TextEditingController ctrl, String label, String sufijo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 13),
          keyboardType: TextInputType.number,
          decoration: _decoration().copyWith(
            suffixText: sufijo,
            suffixStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration() => InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    filled: true, fillColor: Colors.white,
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
  );

  Widget _botonGuardar() => SizedBox(
    height: 52, width: double.infinity,
    child: ElevatedButton(
      onPressed: _isSaving ? null : _guardar,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white,
        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isSaving
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Text(widget.esModoLocal ? 'Listo' : 'Guardar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ),
  );
}
