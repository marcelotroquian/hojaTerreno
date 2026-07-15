// lib/screens/inspeccion_fabricacion_screen.dart
// Sección 2: Inspección de Fabricación (la más extensa)

import 'package:flutter/material.dart';
import '../models/inspeccion_fabricacion.dart';
import '../services/secciones_service.dart';
import '../widgets/seccion_header.dart';
import '../widgets/campos_ensayo.dart';

class InspeccionFabricacionScreen extends StatefulWidget {
  final String? hojaId;
  final InspeccionFabricacion datosIniciales;

  const InspeccionFabricacionScreen({
    super.key,
    this.hojaId,
    this.datosIniciales = const InspeccionFabricacion(),
  });

  bool get esModoLocal => hojaId == null;

  @override
  State<InspeccionFabricacionScreen> createState() => _InspeccionFabricacionScreenState();
}

class _InspeccionFabricacionScreenState extends State<InspeccionFabricacionScreen> {
  // 2.1 checkboxes
  bool _certMateriales = false;
  bool _plano = false;
  bool _fichaTecnica = false;
  late final TextEditingController _inicio21Ctrl, _fin21Ctrl;

  // 2.2 visual
  String _mantoForma = '';   // cilindrico | eliptico
  String _cabezalForma = ''; // bombeado | conico | plano | curvo
  late final TextEditingController _valvulaFondoCtrl, _inicioMantoCtrl, _finMantoCtrl;
  late final TextEditingController _inicioCabezalCtrl, _finCabezalCtrl;
  late final TextEditingController _conformadoMantoCtrl, _conformadoCabezalesCtrl, _estabilidadABCtrl;
  late final TextEditingController _refuerzoReglaCtrl, _venteoCuelloCtrl, _pernoReyCtrl;

  // 2.3 dimensional
  late final TextEditingController _huinchaPerimetralCtrl, _huinchaConvencionalCtrl;
  late final TextEditingController _largoExteriorCtrl, _perimetroCtrl, _largoPestanaCtrl, _alturaMantoBridaCtrl;
  late final TextEditingController _inicio23Ctrl, _fin23Ctrl;
  late final TextEditingController _cabezal1Ctrl, _cabezal2Ctrl, _diamCuelloCtrl;

  // 2.4 conexiones
  late final TextEditingController _venteoNormalCtrl, _venteoEmergenciaCtrl;
  late final TextEditingController _tipoConexionesCtrl, _tamanosCtrl, _material24Ctrl;
  late final TextEditingController _inicio24Ctrl, _fin24Ctrl;

  // 2.5 soldaduras
  late final TextEditingController _soldLongCtrl, _soldCircCtrl, _alineamientoCtrl, _traslapoCtrl;
  late final TextEditingController _soldMantoCabezalCtrl, _soldEnCabezalCtrl;
  late final TextEditingController _inicio25Ctrl, _fin25Ctrl;
  late final TextEditingController _soldCuelloMantoCtrl, _soldCuelloBridaCtrl;

  // inspector
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

  void _initDesde(InspeccionFabricacion d) {
    _certMateriales = d.certificadoMateriales;
    _plano = d.plano;
    _fichaTecnica = d.fichaTecnica;
    _mantoForma = d.mantoForma;
    _cabezalForma = d.cabezalForma;

    _inicio21Ctrl = TextEditingController(text: d.inicio21);
    _fin21Ctrl    = TextEditingController(text: d.fin21);
    _valvulaFondoCtrl = TextEditingController(text: d.valvulaFondo);
    _inicioMantoCtrl  = TextEditingController(text: d.inicioManto);
    _finMantoCtrl     = TextEditingController(text: d.finManto);
    _inicioCabezalCtrl= TextEditingController(text: d.inicioCabezal);
    _finCabezalCtrl   = TextEditingController(text: d.finCabezal);
    _conformadoMantoCtrl     = TextEditingController(text: d.conformadoManto);
    _conformadoCabezalesCtrl = TextEditingController(text: d.conformadoCabezales);
    _estabilidadABCtrl       = TextEditingController(text: d.estabilidadAB);
    _refuerzoReglaCtrl = TextEditingController(text: d.refuerzoReglaMedicion);
    _venteoCuelloCtrl  = TextEditingController(text: d.venteoCuello);
    _pernoReyCtrl      = TextEditingController(text: d.pernoRey);

    _huinchaPerimetralCtrl   = TextEditingController(text: d.huinchaPerimetral);
    _huinchaConvencionalCtrl = TextEditingController(text: d.huinchaConvencional);
    _largoExteriorCtrl   = TextEditingController(text: d.largoExterior);
    _perimetroCtrl       = TextEditingController(text: d.perimetro);
    _largoPestanaCtrl    = TextEditingController(text: d.largoPestana);
    _alturaMantoBridaCtrl= TextEditingController(text: d.alturaMantoBrida);
    _inicio23Ctrl = TextEditingController(text: d.inicio23);
    _fin23Ctrl    = TextEditingController(text: d.fin23);
    _cabezal1Ctrl = TextEditingController(text: d.cabezal1);
    _cabezal2Ctrl = TextEditingController(text: d.cabezal2);
    _diamCuelloCtrl = TextEditingController(text: d.diamInteriorCuello);

    _venteoNormalCtrl     = TextEditingController(text: d.venteoNormal);
    _venteoEmergenciaCtrl = TextEditingController(text: d.venteoEmergencia);
    _tipoConexionesCtrl   = TextEditingController(text: d.tipoConexiones);
    _tamanosCtrl          = TextEditingController(text: d.tamanos);
    _material24Ctrl       = TextEditingController(text: d.material24);
    _inicio24Ctrl = TextEditingController(text: d.inicio24);
    _fin24Ctrl    = TextEditingController(text: d.fin24);

    _soldLongCtrl     = TextEditingController(text: d.soldLongitudinales);
    _soldCircCtrl     = TextEditingController(text: d.soldCircunferenciales);
    _alineamientoCtrl = TextEditingController(text: d.alineamientoSecciones);
    _traslapoCtrl     = TextEditingController(text: d.traslapoUnionesCircunf);
    _soldMantoCabezalCtrl = TextEditingController(text: d.soldaduraMantoCabezal);
    _soldEnCabezalCtrl    = TextEditingController(text: d.soldaduraEnCabezal);
    _inicio25Ctrl = TextEditingController(text: d.inicio25);
    _fin25Ctrl    = TextEditingController(text: d.fin25);
    _soldCuelloMantoCtrl = TextEditingController(text: d.soldaduraCuelloManto);
    _soldCuelloBridaCtrl = TextEditingController(text: d.soldaduraCuelloBrida);

    _inspectorCtrl = TextEditingController(text: d.inspector);
    _fechaCtrl     = TextEditingController(text: d.fecha);
    _resultadoCtrl = TextEditingController(text: d.resultado);

    // Autocompletar inspector (perfil) y fecha actual si están vacíos
    AutocompletarEnsayo.aplicar(inspector: _inspectorCtrl, fecha: _fechaCtrl);
    setState(() => _isLoading = false);
  }

  Future<void> _cargarDesdeFirestore() async {
    final datos = await SeccionesService.cargarFabricacion(widget.hojaId!);
    if (mounted) _initDesde(datos);
  }

  @override
  void dispose() {
    for (final c in [
      _inicio21Ctrl, _fin21Ctrl, _valvulaFondoCtrl, _inicioMantoCtrl, _finMantoCtrl,
      _inicioCabezalCtrl, _finCabezalCtrl, _conformadoMantoCtrl, _conformadoCabezalesCtrl,
      _estabilidadABCtrl, _refuerzoReglaCtrl, _venteoCuelloCtrl, _pernoReyCtrl,
      _huinchaPerimetralCtrl, _huinchaConvencionalCtrl, _largoExteriorCtrl, _perimetroCtrl,
      _largoPestanaCtrl, _alturaMantoBridaCtrl, _inicio23Ctrl, _fin23Ctrl,
      _cabezal1Ctrl, _cabezal2Ctrl, _diamCuelloCtrl,
      _venteoNormalCtrl, _venteoEmergenciaCtrl, _tipoConexionesCtrl, _tamanosCtrl, _material24Ctrl,
      _inicio24Ctrl, _fin24Ctrl, _soldLongCtrl, _soldCircCtrl, _alineamientoCtrl, _traslapoCtrl,
      _soldMantoCabezalCtrl, _soldEnCabezalCtrl, _inicio25Ctrl, _fin25Ctrl,
      _soldCuelloMantoCtrl, _soldCuelloBridaCtrl, _inspectorCtrl, _fechaCtrl, _resultadoCtrl,
    ]) c.dispose();
    super.dispose();
  }

  InspeccionFabricacion _leerFormulario() => InspeccionFabricacion(
    certificadoMateriales: _certMateriales, plano: _plano, fichaTecnica: _fichaTecnica,
    inicio21: _inicio21Ctrl.text.trim(), fin21: _fin21Ctrl.text.trim(),
    mantoForma: _mantoForma, valvulaFondo: _valvulaFondoCtrl.text.trim(),
    inicioManto: _inicioMantoCtrl.text.trim(), finManto: _finMantoCtrl.text.trim(),
    cabezalForma: _cabezalForma, inicioCabezal: _inicioCabezalCtrl.text.trim(), finCabezal: _finCabezalCtrl.text.trim(),
    conformadoManto: _conformadoMantoCtrl.text.trim(), conformadoCabezales: _conformadoCabezalesCtrl.text.trim(),
    estabilidadAB: _estabilidadABCtrl.text.trim(), refuerzoReglaMedicion: _refuerzoReglaCtrl.text.trim(),
    venteoCuello: _venteoCuelloCtrl.text.trim(), pernoRey: _pernoReyCtrl.text.trim(),
    huinchaPerimetral: _huinchaPerimetralCtrl.text.trim(), huinchaConvencional: _huinchaConvencionalCtrl.text.trim(),
    largoExterior: _largoExteriorCtrl.text.trim(), perimetro: _perimetroCtrl.text.trim(),
    largoPestana: _largoPestanaCtrl.text.trim(), alturaMantoBrida: _alturaMantoBridaCtrl.text.trim(),
    inicio23: _inicio23Ctrl.text.trim(), fin23: _fin23Ctrl.text.trim(),
    cabezal1: _cabezal1Ctrl.text.trim(), cabezal2: _cabezal2Ctrl.text.trim(), diamInteriorCuello: _diamCuelloCtrl.text.trim(),
    venteoNormal: _venteoNormalCtrl.text.trim(), venteoEmergencia: _venteoEmergenciaCtrl.text.trim(),
    tipoConexiones: _tipoConexionesCtrl.text.trim(), tamanos: _tamanosCtrl.text.trim(), material24: _material24Ctrl.text.trim(),
    inicio24: _inicio24Ctrl.text.trim(), fin24: _fin24Ctrl.text.trim(),
    soldLongitudinales: _soldLongCtrl.text.trim(), soldCircunferenciales: _soldCircCtrl.text.trim(),
    alineamientoSecciones: _alineamientoCtrl.text.trim(), traslapoUnionesCircunf: _traslapoCtrl.text.trim(),
    soldaduraMantoCabezal: _soldMantoCabezalCtrl.text.trim(), soldaduraEnCabezal: _soldEnCabezalCtrl.text.trim(),
    inicio25: _inicio25Ctrl.text.trim(), fin25: _fin25Ctrl.text.trim(),
    soldaduraCuelloManto: _soldCuelloMantoCtrl.text.trim(), soldaduraCuelloBrida: _soldCuelloBridaCtrl.text.trim(),
    inspector: _inspectorCtrl.text.trim(), fecha: _fechaCtrl.text.trim(), resultado: _resultadoCtrl.text.trim(),
  );

  Future<void> _guardar() async {
    // Validar horas: formato correcto y que inicio no sea mayor que fin
    final errorHoras = CamposEnsayo.validarPares([(_inicio21Ctrl, _fin21Ctrl), (_inicioMantoCtrl, _finMantoCtrl), (_inicioCabezalCtrl, _finCabezalCtrl), (_inicio23Ctrl, _fin23Ctrl), (_inicio24Ctrl, _fin24Ctrl), (_inicio25Ctrl, _fin25Ctrl)]);
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
    final error = await SeccionesService.guardarFabricacion(widget.hojaId!, datos);
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
        title: const Text('2 - Inspección de Fabricación',
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SeccionHeader(numero: '2', titulo: 'INSPECCIÓN DE FABRICACIÓN'),
                const SizedBox(height: 20),

                // ── 2.1 Materiales ─────────────────────────────────────────
                _SubSeccion(numero: '2.1', titulo: 'Materiales'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _check('Certificado de Materiales', _certMateriales, (v) => setState(() => _certMateriales = v)),
                    _check('Plano', _plano, (v) => setState(() => _plano = v)),
                    _check('Ficha Técnica', _fichaTecnica, (v) => setState(() => _fichaTecnica = v)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: CampoHora(controller: _inicio21Ctrl, label: 'Inicio')),
                  const SizedBox(width: 12),
                  Expanded(child: CampoHora(controller: _fin21Ctrl, label: 'Fin')),
                  const Spacer(),
                ]),

                const SizedBox(height: 20),

                // ── 2.2 Inspección Visual ──────────────────────────────────
                _SubSeccion(numero: '2.2', titulo: 'Inspección Visual'),
                const SizedBox(height: 10),

                // Manto: forma exclusiva + válvula de fondo
                Text('Manto', style: _labelStyle()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _radio('Cilíndrico', 'cilindrico', _mantoForma, (v) => setState(() => _mantoForma = v)),
                    _radio('Elíptico', 'eliptico', _mantoForma, (v) => setState(() => _mantoForma = v)),
                  ],
                ),
                const SizedBox(height: 10),
                _campo(_valvulaFondoCtrl, 'Válvula de fondo'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: CampoHora(controller: _inicioMantoCtrl, label: 'Inicio')),
                  const SizedBox(width: 12),
                  Expanded(child: CampoHora(controller: _finMantoCtrl, label: 'Fin')),
                  const Spacer(),
                ]),

                const SizedBox(height: 14),

                // Cabezal: forma exclusiva
                Text('Cabezal', style: _labelStyle()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _radio('Bombeado', 'bombeado', _cabezalForma, (v) => setState(() => _cabezalForma = v)),
                    _radio('Cónico', 'conico', _cabezalForma, (v) => setState(() => _cabezalForma = v)),
                    _radio('Plano', 'plano', _cabezalForma, (v) => setState(() => _cabezalForma = v)),
                    _radio('Curvo Trazado', 'curvo', _cabezalForma, (v) => setState(() => _cabezalForma = v)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: CampoHora(controller: _inicioCabezalCtrl, label: 'Inicio')),
                  const SizedBox(width: 12),
                  Expanded(child: CampoHora(controller: _finCabezalCtrl, label: 'Fin')),
                  const Spacer(),
                ]),

                const SizedBox(height: 14),

                // Campos adicionales de 2.2
                Row(children: [
                  Expanded(child: _campo(_conformadoMantoCtrl, 'Conformado Manto')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_conformadoCabezalesCtrl, 'Conformado Cabezales')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_estabilidadABCtrl, 'Estabilidad A/B')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campo(_refuerzoReglaCtrl, 'Refuerzo regla medición')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_venteoCuelloCtrl, 'Venteo cuello')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_pernoReyCtrl, 'Perno Rey')),
                ]),

                const SizedBox(height: 20),

                // ── 2.3 Control Dimensional ────────────────────────────────
                _SubSeccion(numero: '2.3', titulo: 'Control Dimensional'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campo(_huinchaPerimetralCtrl, 'Huincha perimetral')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_huinchaConvencionalCtrl, 'Huincha convencional')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campoSufijo(_largoExteriorCtrl, 'Largo Exterior', 'mm')),
                  const SizedBox(width: 12),
                  Expanded(child: _campoSufijo(_perimetroCtrl, 'Perímetro', 'mm')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campoSufijo(_largoPestanaCtrl, 'Largo pestaña', 'mm')),
                  const SizedBox(width: 12),
                  Expanded(child: _campoSufijo(_alturaMantoBridaCtrl, 'Altura manto brida', 'mm')),
                  const SizedBox(width: 12),
                  Expanded(child: CampoHora(controller: _inicio23Ctrl, label: 'Inicio')),
                  const SizedBox(width: 8),
                  Expanded(child: CampoHora(controller: _fin23Ctrl, label: 'Fin')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campoSufijo(_cabezal1Ctrl, 'Cabezal 1', 'mm')),
                  const SizedBox(width: 12),
                  Expanded(child: _campoSufijo(_cabezal2Ctrl, 'Cabezal 2', 'mm')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_diamCuelloCtrl, 'Ø int. Cuello')),
                ]),

                const SizedBox(height: 20),

                // ── 2.4 Conexiones / Venteos ───────────────────────────────
                _SubSeccion(numero: '2.4', titulo: 'Inspecc. Conexiones / Venteos'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campo(_venteoNormalCtrl, 'Venteo Normal')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_venteoEmergenciaCtrl, 'Venteo Emergencia')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campo(_tipoConexionesCtrl, 'Tipo conexiones')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_tamanosCtrl, 'Tamaños')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_material24Ctrl, 'Material')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: CampoHora(controller: _inicio24Ctrl, label: 'Inicio')),
                  const SizedBox(width: 12),
                  Expanded(child: CampoHora(controller: _fin24Ctrl, label: 'Fin')),
                  const Spacer(),
                ]),

                const SizedBox(height: 20),

                // ── 2.5 Soldaduras ─────────────────────────────────────────
                _SubSeccion(numero: '2.5', titulo: 'Inspección Soldaduras'),
                const SizedBox(height: 4),
                Text('(Indicar claramente si uniones son de tope o filete)',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade500)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campo(_soldLongCtrl, 'Sold. Longitudinales')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_soldCircCtrl, 'Sold. Circunferenciales')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campo(_alineamientoCtrl, 'Alineamiento secciones')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_traslapoCtrl, 'Traslapo uniones Circunf.')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campo(_soldMantoCabezalCtrl, 'Soldadura Manto-Cabezal')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_soldEnCabezalCtrl, 'Soldadura en cabezal')),
                  const SizedBox(width: 12),
                  Expanded(child: CampoHora(controller: _inicio25Ctrl, label: 'Inicio')),
                  const SizedBox(width: 8),
                  Expanded(child: CampoHora(controller: _fin25Ctrl, label: 'Fin')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campo(_soldCuelloMantoCtrl, 'Soldadura cuello-manto')),
                  const SizedBox(width: 12),
                  Expanded(child: _campo(_soldCuelloBridaCtrl, 'Soldadura cuello-brida')),
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
                    Expanded(child: CampoResultado(controller: _resultadoCtrl)),
                  ]),
                ),

                const SizedBox(height: 32),
                _botonGuardar(),
              ],
            ),
    );
  }

  TextStyle _labelStyle() => const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151));

  // Checkbox para 2.1
  Widget _check(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF6C63FF).withOpacity(0.1) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value ? const Color(0xFF6C63FF) : Colors.grey.shade200, width: value ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF6C63FF) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: value ? const Color(0xFF6C63FF) : Colors.grey.shade400, width: 2),
              ),
              child: value ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                color: value ? const Color(0xFF6C63FF) : const Color(0xFF374151))),
          ],
        ),
      ),
    );
  }

  // Radio exclusivo (forma de manto/cabezal) — toca de nuevo para deseleccionar
  Widget _radio(String label, String valor, String seleccionado, ValueChanged<String> onChanged) {
    final isSelected = valor == seleccionado;
    return GestureDetector(
      onTap: () => onChanged(isSelected ? '' : valor), // toggle
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.1) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.shade400, width: 2),
              ),
              child: isSelected ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF374151))),
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
    filled: true, fillColor: const Color(0xFFF9FAFB),
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
          color: const Color(0xFF6C63FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
        ),
        child: Text(numero, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
      ),
      const SizedBox(width: 8),
      Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
      const SizedBox(width: 8),
      Expanded(child: Divider(color: Colors.grey.shade200)),
    ]);
  }
}
