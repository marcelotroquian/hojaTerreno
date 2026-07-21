// lib/screens/verificacion_accesorios_screen.dart
// Sección 5: Verificación Accesorios

import 'package:flutter/material.dart';
import '../models/verificacion_accesorios.dart';
import '../services/secciones_service.dart';
import '../widgets/seccion_header.dart';
import '../widgets/campos_ensayo.dart';

class VerificacionAccesoriosScreen extends StatefulWidget {
  final String? hojaId;
  final VerificacionAccesorios datosIniciales;

  const VerificacionAccesoriosScreen({
    super.key,
    this.hojaId,
    this.datosIniciales = const VerificacionAccesorios(),
  });

  bool get esModoLocal => hojaId == null;

  @override
  State<VerificacionAccesoriosScreen> createState() => _VerificacionAccesoriosScreenState();
}

class _VerificacionAccesoriosScreenState extends State<VerificacionAccesoriosScreen> {
  // Presión
  late final TextEditingController _presionCtrl, _instrPresionCtrl, _rangoPresionCtrl;
  late final TextEditingController _inicioPresionCtrl, _finPresionCtrl;
  // Vacío
  late final TextEditingController _vacioCtrl, _instrVacioCtrl, _rangoVacioCtrl;
  late final TextEditingController _inicioVacioCtrl, _finVacioCtrl;
  // Inspector
  late final TextEditingController _inspectorCtrl, _fechaCtrl, _resultadoCtrl;

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

  void _initDesde(VerificacionAccesorios d) {
    _presionCtrl       = TextEditingController(text: d.presionEsp);
    _instrPresionCtrl  = TextEditingController(text: d.instrumentoPresion);
    _rangoPresionCtrl  = TextEditingController(text: d.rangoPresion);
    _inicioPresionCtrl = TextEditingController(text: d.inicioPresion);
    _finPresionCtrl    = TextEditingController(text: d.finPresion);
    _vacioCtrl         = TextEditingController(text: d.vacioEsp);
    _instrVacioCtrl    = TextEditingController(text: d.instrumentoVacio);
    _rangoVacioCtrl    = TextEditingController(text: d.rangoVacio);
    _inicioVacioCtrl   = TextEditingController(text: d.inicioVacio);
    _finVacioCtrl      = TextEditingController(text: d.finVacio);
    _inspectorCtrl     = TextEditingController(text: d.inspector);
    _fechaCtrl         = TextEditingController(text: d.fecha);
    _resultadoCtrl     = TextEditingController(text: d.resultado);
    // Autocompletar inspector (perfil) y fecha actual si están vacíos
    AutocompletarEnsayo.aplicar(inspector: _inspectorCtrl, fecha: _fechaCtrl);
    setState(() => _isLoading = false);
  }

  Future<void> _cargarDesdeFirestore() async {
    final datos = await SeccionesService.cargarAccesorios(widget.hojaId!);
    if (mounted) _initDesde(datos);
  }

  @override
  void dispose() {
    for (final c in [
      _presionCtrl, _instrPresionCtrl, _rangoPresionCtrl, _inicioPresionCtrl, _finPresionCtrl,
      _vacioCtrl, _instrVacioCtrl, _rangoVacioCtrl, _inicioVacioCtrl, _finVacioCtrl,
      _inspectorCtrl, _fechaCtrl, _resultadoCtrl,
    ]) c.dispose();
    super.dispose();
  }

  VerificacionAccesorios _leerFormulario() => VerificacionAccesorios(
    presionEsp: _presionCtrl.text.trim(), instrumentoPresion: _instrPresionCtrl.text.trim(),
    rangoPresion: _rangoPresionCtrl.text.trim(),
    inicioPresion: _inicioPresionCtrl.text.trim(), finPresion: _finPresionCtrl.text.trim(),
    vacioEsp: _vacioCtrl.text.trim(), instrumentoVacio: _instrVacioCtrl.text.trim(),
    rangoVacio: _rangoVacioCtrl.text.trim(),
    inicioVacio: _inicioVacioCtrl.text.trim(), finVacio: _finVacioCtrl.text.trim(),
    inspector: _inspectorCtrl.text.trim(), fecha: _fechaCtrl.text.trim(), resultado: _resultadoCtrl.text.trim(),
  );

  Future<void> _guardar() async {
    // Validar horas: formato correcto y que inicio no sea mayor que fin
    final errorHoras = CamposEnsayo.validarPares([(_inicioPresionCtrl, _finPresionCtrl), (_inicioVacioCtrl, _finVacioCtrl)]);
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
    final error = await SeccionesService.guardarAccesorios(widget.hojaId!, datos);
    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? '¡Verificación guardada!'),
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
        title: const Text('5 - Verificación Accesorios',
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
                SeccionHeader(numero: '5', titulo: 'VERIFICACIÓN ACCESORIOS'),
                const SizedBox(height: 20),

                // ── Presión Esp. Interst. ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Presión Esp. Interst.', style: _tituloFila()),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _campoSufijo(_presionCtrl, 'Presión', 'psig')),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: _campo(_instrPresionCtrl, 'Instrumento')),
                        const SizedBox(width: 10),
                        Expanded(child: _campo(_rangoPresionCtrl, 'Rango')),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: CampoHora(controller: _inicioPresionCtrl, label: 'Inicio')),
                        const SizedBox(width: 10),
                        Expanded(child: CampoHora(controller: _finPresionCtrl, label: 'Fin')),
                        const Spacer(),
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Vacío esp. Interst. ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vacío esp. Interst.', style: _tituloFila()),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _campoSufijo(_vacioCtrl, 'Vacío', 'inHg')),
                        const SizedBox(width: 10),
                        Expanded(flex: 2, child: _campo(_instrVacioCtrl, 'Instrumento')),
                        const SizedBox(width: 10),
                        Expanded(child: _campo(_rangoVacioCtrl, 'Rango')),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: CampoHora(controller: _inicioVacioCtrl, label: 'Inicio')),
                        const SizedBox(width: 10),
                        Expanded(child: CampoHora(controller: _finVacioCtrl, label: 'Fin')),
                        const Spacer(),
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Inspector / Fecha / Resultado
                _filaInspector(),

                const SizedBox(height: 32),
                _botonGuardar(),
              ],
            ),
    );
  }

  TextStyle _tituloFila() => const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827));

  Widget _filaInspector() => Container(
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
  );

  Widget _campo(TextEditingController ctrl, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 4),
        TextField(controller: ctrl, style: const TextStyle(fontSize: 13), decoration: _decoration()),
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
          controller: ctrl, style: const TextStyle(fontSize: 13),
          keyboardType: TextInputType.number,
          decoration: _decoration().copyWith(
            suffixText: sufijo, suffixStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF60A66B), width: 2)),
  );

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
