// lib/screens/inspeccion_recubrimiento_screen.dart
// Formulario de Inspección de Recubrimiento o Revestimiento

import 'package:flutter/material.dart';
import '../models/inspeccion_recubrimiento.dart';
import '../services/secciones_service.dart';
import '../widgets/seccion_header.dart';
import '../widgets/campos_ensayo.dart';

class InspeccionRecubrimientoScreen extends StatefulWidget {
  final String? hojaId;
  final InspeccionRecubrimiento datosIniciales;

  const InspeccionRecubrimientoScreen({
    super.key,
    this.hojaId,
    this.datosIniciales = const InspeccionRecubrimiento(),
  });

  bool get esModoLocal => hojaId == null;

  @override
  State<InspeccionRecubrimientoScreen> createState() => _InspeccionRecubrimientoScreenState();
}

class _InspeccionRecubrimientoScreenState extends State<InspeccionRecubrimientoScreen> {
  // 4.1 General
  late final TextEditingController _tipoCtrl;
  late final TextEditingController _materialCtrl;
  late final TextEditingController _inicio41Ctrl;
  late final TextEditingController _fin41Ctrl;
  late final TextEditingController _tipoAplicacionCtrl;
  late final TextEditingController _prepSuperficieCtrl;
  late final TextEditingController _resinaCtrl;
  late final TextEditingController _imprimanteCtrl;
  late final TextEditingController _instrumento41Ctrl;

  // 4.2 Espesores
  late final TextEditingController _espesorMinimoCtrl;
  late final TextEditingController _cantidadMedidasCtrl;
  late final TextEditingController _inicio42Ctrl;
  late final TextEditingController _fin42Ctrl;
  late final TextEditingController _minimoCtrl;
  late final TextEditingController _maximoCtrl;
  late final TextEditingController _promedioCtrl;

  // 4.3 Porosidad
  late final TextEditingController _voltajeCtrl;
  late final TextEditingController _instrumento43Ctrl;
  late final TextEditingController _inicio43Ctrl;
  late final TextEditingController _fin43Ctrl;

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

  void _initDesde(InspeccionRecubrimiento d) {
    _tipoCtrl           = TextEditingController(text: d.tipo);
    _materialCtrl       = TextEditingController(text: d.material);
    _inicio41Ctrl       = TextEditingController(text: d.inicio41);
    _fin41Ctrl          = TextEditingController(text: d.fin41);
    _tipoAplicacionCtrl = TextEditingController(text: d.tipoAplicacion);
    _prepSuperficieCtrl = TextEditingController(text: d.prepSuperficie);
    _resinaCtrl         = TextEditingController(text: d.resina);
    _imprimanteCtrl     = TextEditingController(text: d.imprimanteAnticorrosivo);
    _instrumento41Ctrl  = TextEditingController(text: d.instrumento41);
    _espesorMinimoCtrl  = TextEditingController(text: d.espesorMinimo);
    _cantidadMedidasCtrl= TextEditingController(text: d.cantidadMedidas);
    _inicio42Ctrl       = TextEditingController(text: d.inicio42);
    _fin42Ctrl          = TextEditingController(text: d.fin42);
    _minimoCtrl         = TextEditingController(text: d.minimoEspesor);
    _maximoCtrl         = TextEditingController(text: d.maximoEspesor);
    _promedioCtrl       = TextEditingController(text: d.promedioEspesor);
    _voltajeCtrl        = TextEditingController(text: d.voltajeKV);
    _instrumento43Ctrl  = TextEditingController(text: d.instrumento43);
    _inicio43Ctrl       = TextEditingController(text: d.inicio43);
    _fin43Ctrl          = TextEditingController(text: d.fin43);
    _inspectorCtrl      = TextEditingController(text: d.inspector);
    _fechaCtrl          = TextEditingController(text: d.fecha);
    _resultadoCtrl      = TextEditingController(text: d.resultado);
    // Autocompletar inspector (perfil) y fecha actual si están vacíos
    AutocompletarEnsayo.aplicar(inspector: _inspectorCtrl, fecha: _fechaCtrl);
    setState(() => _isLoading = false);
  }

  Future<void> _cargarDesdeFirestore() async {
    final datos = await SeccionesService.cargarRecubrimiento(widget.hojaId!);
    if (mounted) _initDesde(datos);
  }

  @override
  void dispose() {
    for (final c in [
      _tipoCtrl, _materialCtrl, _inicio41Ctrl, _fin41Ctrl,
      _tipoAplicacionCtrl, _prepSuperficieCtrl, _resinaCtrl, _imprimanteCtrl, _instrumento41Ctrl,
      _espesorMinimoCtrl, _cantidadMedidasCtrl, _inicio42Ctrl, _fin42Ctrl,
      _minimoCtrl, _maximoCtrl, _promedioCtrl,
      _voltajeCtrl, _instrumento43Ctrl, _inicio43Ctrl, _fin43Ctrl,
      _inspectorCtrl, _fechaCtrl, _resultadoCtrl,
    ]) c.dispose();
    super.dispose();
  }

  InspeccionRecubrimiento _leerFormulario() => InspeccionRecubrimiento(
    tipo: _tipoCtrl.text.trim(), material: _materialCtrl.text.trim(),
    inicio41: _inicio41Ctrl.text.trim(), fin41: _fin41Ctrl.text.trim(),
    tipoAplicacion: _tipoAplicacionCtrl.text.trim(), prepSuperficie: _prepSuperficieCtrl.text.trim(),
    resina: _resinaCtrl.text.trim(), imprimanteAnticorrosivo: _imprimanteCtrl.text.trim(),
    instrumento41: _instrumento41Ctrl.text.trim(),
    espesorMinimo: _espesorMinimoCtrl.text.trim(), cantidadMedidas: _cantidadMedidasCtrl.text.trim(),
    inicio42: _inicio42Ctrl.text.trim(), fin42: _fin42Ctrl.text.trim(),
    minimoEspesor: _minimoCtrl.text.trim(), maximoEspesor: _maximoCtrl.text.trim(),
    promedioEspesor: _promedioCtrl.text.trim(),
    voltajeKV: _voltajeCtrl.text.trim(), instrumento43: _instrumento43Ctrl.text.trim(),
    inicio43: _inicio43Ctrl.text.trim(), fin43: _fin43Ctrl.text.trim(),
    inspector: _inspectorCtrl.text.trim(), fecha: _fechaCtrl.text.trim(),
    resultado: _resultadoCtrl.text.trim(),
  );

  Future<void> _guardar() async {
    // Validar horas: formato correcto y que inicio no sea mayor que fin
    final errorHoras = CamposEnsayo.validarPares([(_inicio41Ctrl, _fin41Ctrl), (_inicio42Ctrl, _fin42Ctrl), (_inicio43Ctrl, _fin43Ctrl)]);
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
    final error = await SeccionesService.guardarRecubrimiento(widget.hojaId!, datos);
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
        title: const Text('4 - Recubrimiento / Revestimiento',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

                SeccionHeader(numero: '4', titulo: 'INSPECCIÓN RECUBRIMIENTO O REVESTIMIENTO'),
                const SizedBox(height: 20),

                // ── 4.1 General ────────────────────────────────────────────
                _SubSeccion(numero: '4.1', titulo: 'General'),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(flex: 2, child: _campo(_tipoCtrl,      'Tipo')),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: _campo(_materialCtrl,  'Material')),
                  const SizedBox(width: 12),
                  Expanded(child: CampoHora(controller: _inicio41Ctrl, label: 'Inicio')),
                  const SizedBox(width: 8),
                  Expanded(child: CampoHora(controller: _fin41Ctrl, label: 'Fin')),
                ]),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(flex: 2, child: _campo(_tipoAplicacionCtrl, 'Tipo Aplicación')),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _campo(_prepSuperficieCtrl, 'Prep. Superficie')),
                ]),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(child: _campo(_resinaCtrl,    'Resina')),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _campo(_imprimanteCtrl, 'Imprimante/Anticorrosivo')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_instrumento41Ctrl, 'Instrumento')),
                ]),

                const SizedBox(height: 24),

                // ── 4.2 Espesores ─────────────────────────────────────────
                _SubSeccion(numero: '4.2', titulo: 'Espesores'),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(flex: 2, child: _campo(_espesorMinimoCtrl,   'Espesor Mínimo')),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _campo(_cantidadMedidasCtrl, 'Cantidad Medidas')),
                  const SizedBox(width: 12),
                  Expanded(child: CampoHora(controller: _inicio42Ctrl, label: 'Inicio')),
                  const SizedBox(width: 8),
                  Expanded(child: CampoHora(controller: _fin42Ctrl, label: 'Fin')),
                ]),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(child: _campo(_minimoCtrl,   'MÍNIMO')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_maximoCtrl,   'MÁXIMO')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_promedioCtrl, 'PROMEDIO')),
                ]),

                const SizedBox(height: 24),

                // ── 4.3 Ensayo de Porosidad ────────────────────────────────
                _SubSeccion(numero: '4.3', titulo: 'Ensayo de Porosidad'),
                const SizedBox(height: 8),
                Text('Ensayo realizado a manto y cabezales',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 10),

                Row(children: [
                  Expanded(child: _campo(_voltajeCtrl,       'Voltaje KV')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_instrumento43Ctrl, 'Instrumento')),
                  const SizedBox(width: 12),
                  Expanded(child: CampoHora(controller: _inicio43Ctrl, label: 'Inicio')),
                  const SizedBox(width: 8),
                  Expanded(child: CampoHora(controller: _fin43Ctrl, label: 'Fin')),
                ]),

                const SizedBox(height: 24),

                // ── Inspector / Fecha / Resultado ──────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF60A66B).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF60A66B).withOpacity(0.15)),
                  ),
                  child: Row(children: [
                    Expanded(flex: 2, child: _campo(_inspectorCtrl, 'Inspector')),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _campo(_fechaCtrl,     'Fecha')),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: CampoResultado(controller: _resultadoCtrl)),
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
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            filled: true, fillColor: const Color(0xFFF9FAFB),
            border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
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

class _SubSeccion extends StatelessWidget {
  final String numero;
  final String titulo;
  const _SubSeccion({required this.numero, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF60A66B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF60A66B).withOpacity(0.3)),
        ),
        child: Text(numero, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF60A66B))),
      ),
      const SizedBox(width: 8),
      Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
      const SizedBox(width: 8),
      Expanded(child: Divider(color: Colors.grey.shade200)),
    ]);
  }
}
