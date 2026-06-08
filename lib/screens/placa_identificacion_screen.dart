// lib/screens/placa_identificacion_screen.dart
// Sección 6: Placa de Identificación

import 'package:flutter/material.dart';
import '../models/placa_identificacion.dart';
import '../services/secciones_service.dart';
import '../widgets/seccion_header.dart';

class PlacaIdentificacionScreen extends StatefulWidget {
  final String? hojaId;
  final PlacaIdentificacion datosIniciales;

  const PlacaIdentificacionScreen({
    super.key,
    this.hojaId,
    this.datosIniciales = const PlacaIdentificacion(),
  });

  bool get esModoLocal => hojaId == null;

  @override
  State<PlacaIdentificacionScreen> createState() => _PlacaIdentificacionScreenState();
}

class _PlacaIdentificacionScreenState extends State<PlacaIdentificacionScreen> {
  late final TextEditingController _ubicacionCtrl;
  late final TextEditingController _inicioCtrl, _finCtrl;
  late final TextEditingController _inspectorCtrl, _fechaCtrl, _resultadoCtrl;

  bool _verificacionDatos = false;
  bool _cunoIII = false;
  bool _numeroCertificado = false;

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

  void _initDesde(PlacaIdentificacion d) {
    _ubicacionCtrl = TextEditingController(text: d.ubicacion);
    _inicioCtrl    = TextEditingController(text: d.inicio);
    _finCtrl       = TextEditingController(text: d.fin);
    _inspectorCtrl = TextEditingController(text: d.inspector);
    _fechaCtrl     = TextEditingController(text: d.fecha);
    _resultadoCtrl = TextEditingController(text: d.resultado);
    _verificacionDatos = d.verificacionDatos;
    _cunoIII = d.cunoIII;
    _numeroCertificado = d.numeroCertificadoAcunado;
    setState(() => _isLoading = false);
  }

  Future<void> _cargarDesdeFirestore() async {
    final datos = await SeccionesService.cargarPlaca(widget.hojaId!);
    if (mounted) _initDesde(datos);
  }

  @override
  void dispose() {
    for (final c in [_ubicacionCtrl, _inicioCtrl, _finCtrl, _inspectorCtrl, _fechaCtrl, _resultadoCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  PlacaIdentificacion _leerFormulario() => PlacaIdentificacion(
    ubicacion: _ubicacionCtrl.text.trim(),
    verificacionDatos: _verificacionDatos,
    cunoIII: _cunoIII,
    numeroCertificadoAcunado: _numeroCertificado,
    inicio: _inicioCtrl.text.trim(), fin: _finCtrl.text.trim(),
    inspector: _inspectorCtrl.text.trim(), fecha: _fechaCtrl.text.trim(), resultado: _resultadoCtrl.text.trim(),
  );

  Future<void> _guardar() async {
    final datos = _leerFormulario();
    if (widget.esModoLocal) { Navigator.pop(context, datos); return; }
    setState(() => _isSaving = true);
    final error = await SeccionesService.guardarPlaca(widget.hojaId!, datos);
    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? '¡Placa guardada!'),
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
        title: const Text('6 - Placa de Identificación',
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
                SeccionHeader(numero: '6', titulo: 'PLACA DE IDENTIFICACIÓN'),
                const SizedBox(height: 20),

                // Ubicación
                _campo(_ubicacionCtrl, 'Ubicación'),

                const SizedBox(height: 16),

                // Checkboxes
                _check('Verificación Datos', _verificacionDatos, (v) => setState(() => _verificacionDatos = v)),
                const SizedBox(height: 8),
                _check('Cuño III', _cunoIII, (v) => setState(() => _cunoIII = v)),
                const SizedBox(height: 8),
                _check('Número de Certificado acuñado en copla', _numeroCertificado, (v) => setState(() => _numeroCertificado = v)),

                const SizedBox(height: 16),

                // Inicio / Fin
                Row(children: [
                  Expanded(child: _campo(_inicioCtrl, 'Inicio')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_finCtrl, 'Fin')),
                  const Spacer(),
                ]),

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
                    Expanded(child: _campo(_resultadoCtrl, 'Resultado')),
                  ]),
                ),

                const SizedBox(height: 32),
                _botonGuardar(),
              ],
            ),
    );
  }

  Widget _check(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF6C63FF).withOpacity(0.1) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: value ? const Color(0xFF6C63FF) : Colors.grey.shade200, width: value ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF6C63FF) : Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: value ? const Color(0xFF6C63FF) : Colors.grey.shade400, width: 2),
              ),
              child: value ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 14, fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                  color: value ? const Color(0xFF6C63FF) : const Color(0xFF374151))),
            ),
          ],
        ),
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
          controller: ctrl, style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            filled: true, fillColor: const Color(0xFFF9FAFB),
            border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
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
