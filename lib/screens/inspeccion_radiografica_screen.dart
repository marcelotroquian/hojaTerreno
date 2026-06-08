// lib/screens/inspeccion_radiografica_screen.dart
// Formulario de Inspección Radiográfica — funciona en modo local y Firestore

import 'package:flutter/material.dart';
import '../models/inspeccion_radiografica.dart';
import '../services/secciones_service.dart';
import '../widgets/seccion_header.dart';

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

  // Filas operador/fecha/resultado — máximo 5
  static const int maxFilas = 5;
  late List<_FilaCtrl> _filasCtrl;

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

    // Rellenar filas existentes + vacías hasta maxFilas
    _filasCtrl = List.generate(maxFilas, (i) {
      final fila = i < d.filas.length ? d.filas[i] : const FilaInspeccion();
      return _FilaCtrl(fila);
    });
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
    for (final f in _filasCtrl) f.dispose();
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
      filas: _filasCtrl
          .map((f) => FilaInspeccion(
                operador:  f.operadorCtrl.text.trim(),
                fecha:     f.fechaCtrl.text.trim(),
                resultado: f.resultadoCtrl.text.trim(),
              ))
          .where((f) => f.tieneContenido)
          .toList(),
    );
  }

  Future<void> _guardar() async {
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
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
                  Expanded(child: _campo(_inicioCtrl, 'Inicio')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_finCtrl, 'Fin')),
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

                // ── Tabla Operador / Fecha / Resultado ─────────────────────
                SeccionHeader(numero: '', titulo: 'Operador — Fecha — Resultado'),
                const SizedBox(height: 12),

                // Encabezado de tabla
                _FilaEncabezado(),
                const Divider(height: 1),

                // Filas editables
                ...List.generate(maxFilas, (i) => _FilaEditable(ctrl: _filasCtrl[i], numero: i + 1)),

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
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
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
        backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white,
        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isSaving
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : Text(widget.esModoLocal ? 'Listo' : 'Guardar', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _FilaCtrl {
  final TextEditingController operadorCtrl;
  final TextEditingController fechaCtrl;
  final TextEditingController resultadoCtrl;

  _FilaCtrl(FilaInspeccion f)
      : operadorCtrl  = TextEditingController(text: f.operador),
        fechaCtrl     = TextEditingController(text: f.fecha),
        resultadoCtrl = TextEditingController(text: f.resultado);

  void dispose() { operadorCtrl.dispose(); fechaCtrl.dispose(); resultadoCtrl.dispose(); }
}

class _FilaEncabezado extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: const Row(children: [
        SizedBox(width: 28),
        Expanded(flex: 3, child: Text('Operador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF374151)))),
        Expanded(flex: 2, child: Text('Fecha',    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF374151)))),
        Expanded(flex: 2, child: Text('Resultado',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF374151)))),
      ]),
    );
  }
}

class _FilaEditable extends StatelessWidget {
  final _FilaCtrl ctrl;
  final int numero;
  const _FilaEditable({required this.ctrl, required this.numero});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(children: [
        SizedBox(width: 28, child: Text('$numero', style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w600))),
        Expanded(flex: 3, child: _mini(ctrl.operadorCtrl, 'Operador')),
        const SizedBox(width: 6),
        Expanded(flex: 2, child: _mini(ctrl.fechaCtrl,    'dd/mm/aaaa')),
        const SizedBox(width: 6),
        Expanded(flex: 2, child: _mini(ctrl.resultadoCtrl,'Resultado')),
      ]),
    );
  }

  Widget _mini(TextEditingController c, String hint) => TextField(
    controller: c,
    style: const TextStyle(fontSize: 12),
    decoration: InputDecoration(
      isDense: true, hintText: hint,
      hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade300),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF6C63FF))),
    ),
  );
}

