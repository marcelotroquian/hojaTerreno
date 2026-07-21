// lib/screens/inspeccion_radiografica_screen.dart
// Formulario de Inspección Radiográfica — funciona en modo local y Firestore

import 'package:flutter/material.dart';
import '../models/inspeccion_radiografica.dart';
import '../services/secciones_service.dart';
import '../widgets/seccion_header.dart';
import '../widgets/campos_ensayo.dart';

class InspeccionRadiograficaScreen extends StatefulWidget {
  final String? hojaId;                             // null = modo local
  final InspeccionRadiografica datosIniciales;

  const InspeccionRadiograficaScreen({
    super.key,
    this.hojaId,
    this.datosIniciales = const InspeccionRadiografica(),
  });

  bool get esModoLocal => hojaId == null;

  @override
  State<InspeccionRadiograficaScreen> createState() => _InspeccionRadiograficaScreenState();
}

class _InspeccionRadiograficaScreenState extends State<InspeccionRadiograficaScreen> {
  // Campos generales
  late final TextEditingController _equipoCtrl;
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _inicioCtrl;
  late final TextEditingController _finCtrl;
  late final TextEditingController _curitajeCtrl;
  late final TextEditingController _distanciaCtrl;
  late final TextEditingController _tiempoCtrl;

  // Inspector / Fecha / Resultado (uno solo)
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

  void _initDesde(InspeccionRadiografica d) {
    _equipoCtrl    = TextEditingController(text: d.equipo);
    _numeroCtrl    = TextEditingController(text: d.numero);
    _inicioCtrl    = TextEditingController(text: d.inicio);
    _finCtrl       = TextEditingController(text: d.fin);
    _curitajeCtrl  = TextEditingController(text: d.curitaje);
    _distanciaCtrl = TextEditingController(text: d.distanciaPulg);
    _tiempoCtrl    = TextEditingController(text: d.tiempo);
    _inspectorCtrl = TextEditingController(text: d.inspector);
    _fechaCtrl     = TextEditingController(text: d.fecha);
    _resultadoCtrl = TextEditingController(text: d.resultado);
    // Autocompletar inspector (perfil) y fecha actual si están vacíos
    AutocompletarEnsayo.aplicar(inspector: _inspectorCtrl, fecha: _fechaCtrl);
    setState(() => _isLoading = false);
  }

  Future<void> _cargarDesdeFirestore() async {
    final datos = await SeccionesService.cargarRadiografica(widget.hojaId!);
    if (mounted) _initDesde(datos);
  }

  @override
  void dispose() {
    _equipoCtrl.dispose(); _numeroCtrl.dispose(); _inicioCtrl.dispose();
    _finCtrl.dispose(); _curitajeCtrl.dispose(); _distanciaCtrl.dispose();
    _tiempoCtrl.dispose();
    _inspectorCtrl.dispose(); _fechaCtrl.dispose(); _resultadoCtrl.dispose();
    super.dispose();
  }

  InspeccionRadiografica _leerFormulario() {
    return InspeccionRadiografica(
      equipo:        _equipoCtrl.text.trim(),
      numero:        _numeroCtrl.text.trim(),
      inicio:        _inicioCtrl.text.trim(),
      fin:           _finCtrl.text.trim(),
      curitaje:      _curitajeCtrl.text.trim(),
      distanciaPulg: _distanciaCtrl.text.trim(),
      tiempo:        _tiempoCtrl.text.trim(),
      inspector:     _inspectorCtrl.text.trim(),
      fecha:         _fechaCtrl.text.trim(),
      resultado:     _resultadoCtrl.text.trim(),
    );
  }

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

    if (widget.esModoLocal) {
      Navigator.pop(context, datos);
      return;
    }

    setState(() => _isSaving = true);
    final error = await SeccionesService.guardarRadiografica(widget.hojaId!, datos);
    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? '¡Inspección guardada!'),
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
        title: const Text('1 - Inspección Radiográfica',
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF60A66B)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [

                // ── Encabezado ─────────────────────────────────────────────
                SeccionHeader(numero: '1', titulo: 'INSPECCIÓN RADIOGRÁFICA'),
                const SizedBox(height: 16),

                // Equipo / Nº
                Row(children: [
                  Expanded(child: _campo(_equipoCtrl, 'Equipo')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_numeroCtrl, 'Nº')),
                  const SizedBox(width: 12),
                  Expanded(child: CampoHora(controller: _inicioCtrl, label: 'Inicio')),
                  const SizedBox(width: 12),
                  Expanded(child: CampoHora(controller: _finCtrl, label: 'Fin')),
                ]),
                const SizedBox(height: 12),

                // Curitaje / Distancia / Tiempo
                Row(children: [
                  Expanded(child: _campo(_curitajeCtrl, 'Curitaje')),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _campo(_distanciaCtrl, 'Distancia (pulg.)')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_tiempoCtrl, 'Tiempo')),
                ]),

                const SizedBox(height: 24),

                // ── Inspector / Fecha / Resultado (uno solo) ───────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF60A66B).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF60A66B).withOpacity(0.15)),
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

  Widget _campo(TextEditingController ctrl, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            filled: true, fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF60A66B), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _botonGuardar() => SizedBox(
    height: 52, width: double.infinity,
    child: ElevatedButton(
      onPressed: _isSaving ? null : _guardar,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF60A66B), foregroundColor: Colors.white,
        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isSaving
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Text(widget.esModoLocal ? 'Listo' : 'Guardar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ),
  );
}
