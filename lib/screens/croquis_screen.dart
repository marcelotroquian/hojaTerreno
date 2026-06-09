// lib/screens/croquis_screen.dart
// Canvas de dibujo tipo Paint — funciona en dos modos:
//
// MODO LOCAL (creación): recibe elementosIniciales=[] y NO tiene hojaId.
//   Al presionar "Listo", hace Navigator.pop(elementos) → el formulario
//   recibe la lista y la guarda junto con la hoja en Firestore.
//
// MODO FIRESTORE (edición): recibe hojaId. Carga, guarda y tiene botón "Guardar".

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/canvas_element.dart';
import '../models/croquis_datos.dart';
import '../services/croquis_service.dart';
import '../widgets/croquis_painter.dart';

// Resultado que devuelve el croquis en modo local: trazos + datos
class CroquisResultado {
  final List<ElementoCanvas> elementos;
  final CroquisDatos datos;
  const CroquisResultado(this.elementos, this.datos);
}

class CroquisScreen extends StatefulWidget {
  final String? hojaId;                        // null = modo local (creación)
  final String titulo;
  final List<ElementoCanvas> elementosIniciales; // Trazos previos en modo local
  final CroquisDatos datosIniciales;           // Datos cabecera/pie previos

  const CroquisScreen({
    super.key,
    this.hojaId,
    required this.titulo,
    this.elementosIniciales = const [],
    this.datosIniciales = const CroquisDatos(),
  });

  bool get esModoLocal => hojaId == null;

  @override
  State<CroquisScreen> createState() => _CroquisScreenState();
}

class _CroquisScreenState extends State<CroquisScreen> {
  List<ElementoCanvas> _elementos = [];
  List<List<ElementoCanvas>> _historial = [];
  ElementoCanvas? _enProgreso;

  HerramientaCroquis _herramienta = HerramientaCroquis.lapiz;
  Color _colorActual = Colors.black;
  double _grosorActual = 3.0;
  double _fontSizeActual = 18.0;
  double _grosorBorrador = 20.0; // la goma es más gruesa que el lápiz

  // ── Controladores de los campos de cabecera/pie ────────────────────────────
  final _espesorCuelloCtrl = TextEditingController();
  final _espesorTapaCtrl   = TextEditingController();
  final _espesorFlangeCtrl = TextEditingController();
  final _instrumentoCtrl   = TextEditingController();
  final _inspectorCtrl     = TextEditingController();
  final _fechaCtrl         = TextEditingController();
  final _resultadoCtrl     = TextEditingController();
  final _inicioCtrl        = TextEditingController();
  final _finCtrl           = TextEditingController();
  bool? _placaFabricacion; // checkbox Sí/No
  bool? _reparacionTanque; // checkbox Sí/No

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hayCambios = false;

  final _uuid = const Uuid();

  static const _colores = [
    Colors.black, Colors.red, Colors.blue, Colors.green,
    Colors.orange, Colors.purple, Colors.brown, Colors.grey,
    Colors.cyan, Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.esModoLocal) {
      // Modo local: usamos los elementos y datos que nos pasó el formulario
      _aplicarDatos(widget.datosIniciales);
      setState(() {
        _elementos = List.from(widget.elementosIniciales);
        _isLoading = false;
      });
    } else {
      // Modo Firestore: cargamos desde la base de datos
      _cargarCroquis();
    }
  }

  @override
  void dispose() {
    _espesorCuelloCtrl.dispose(); _espesorTapaCtrl.dispose(); _espesorFlangeCtrl.dispose();
    _instrumentoCtrl.dispose(); _inspectorCtrl.dispose(); _fechaCtrl.dispose();
    _resultadoCtrl.dispose(); _inicioCtrl.dispose(); _finCtrl.dispose();
    super.dispose();
  }

  // Rellena los controladores con los datos cargados
  void _aplicarDatos(CroquisDatos d) {
    _espesorCuelloCtrl.text = d.espesorCuello;
    _espesorTapaCtrl.text   = d.espesorTapa;
    _espesorFlangeCtrl.text = d.espesorFlange;
    _instrumentoCtrl.text   = d.instrumento;
    _inspectorCtrl.text     = d.inspector;
    _fechaCtrl.text         = d.fecha;
    _resultadoCtrl.text     = d.resultado;
    _inicioCtrl.text        = d.inicio;
    _finCtrl.text           = d.fin;
    _placaFabricacion       = d.placaFabricacionTanque;
    _reparacionTanque       = d.reparacionTanque;
  }

  // Construye el objeto CroquisDatos desde los controladores
  CroquisDatos _leerDatos() => CroquisDatos(
    espesorCuello: _espesorCuelloCtrl.text.trim(),
    espesorTapa:   _espesorTapaCtrl.text.trim(),
    espesorFlange: _espesorFlangeCtrl.text.trim(),
    instrumento:   _instrumentoCtrl.text.trim(),
    inspector:     _inspectorCtrl.text.trim(),
    fecha:         _fechaCtrl.text.trim(),
    resultado:     _resultadoCtrl.text.trim(),
    inicio:        _inicioCtrl.text.trim(),
    fin:           _finCtrl.text.trim(),
    placaFabricacionTanque: _placaFabricacion,
    reparacionTanque:       _reparacionTanque,
  );

  Future<void> _cargarCroquis() async {
    final elementos = await CroquisService.cargar(widget.hojaId!);
    final datos = await CroquisService.cargarDatos(widget.hojaId!);
    if (mounted) {
      _aplicarDatos(datos);
      setState(() { _elementos = elementos; _isLoading = false; });
    }
  }

  // ── Guardar en Firestore (solo modo edición) ───────────────────────────────
  Future<void> _guardarFirestore() async {
    setState(() => _isSaving = true);
    final error = await CroquisService.guardar(
      hojaId: widget.hojaId!,
      elementos: _elementos,
      datos: _leerDatos(),
    );
    setState(() { _isSaving = false; _hayCambios = false; });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? '¡Croquis guardado!'),
      backgroundColor: error != null ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Listo (modo local): devuelve elementos + datos al formulario ───────────
  void _listo() {
    Navigator.pop(context, CroquisResultado(_elementos, _leerDatos()));
  }

  void _deshacer() {
    if (_historial.isEmpty) return;
    setState(() { _elementos = List.from(_historial.removeLast()); _hayCambios = true; });
  }

  void _limpiarTodo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Limpiar croquis'),
        content: const Text('¿Borrar todos los elementos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() { _historial.add(List.from(_elementos)); _elementos = []; _hayCambios = true; });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  // ── Gestos ─────────────────────────────────────────────────────────────────
  void _onPanStart(DragStartDetails d) {
    if (_herramienta == HerramientaCroquis.texto) { _pedirTexto(d.localPosition); return; }

    final id = _uuid.v4();
    final inicio = PuntoCanvas(d.localPosition.dx, d.localPosition.dy);
    ElementoCanvas nuevo;

    switch (_herramienta) {
      case HerramientaCroquis.lapiz:
        nuevo = ElementoCanvas(id: id, tipo: TipoElemento.trazo, colorValue: _colorActual.value, grosor: _grosorActual, puntos: [inicio]);
        break;
      case HerramientaCroquis.borrador:
        // La goma es un trazo que borra; el grosor de la goma es más grueso
        nuevo = ElementoCanvas(id: id, tipo: TipoElemento.borrado, colorValue: 0, grosor: _grosorBorrador, puntos: [inicio]);
        break;
      case HerramientaCroquis.linea:
        nuevo = ElementoCanvas(id: id, tipo: TipoElemento.linea, colorValue: _colorActual.value, grosor: _grosorActual, inicio: inicio, fin: inicio);
        break;
      case HerramientaCroquis.rectangulo:
        nuevo = ElementoCanvas(id: id, tipo: TipoElemento.rectangulo, colorValue: _colorActual.value, grosor: _grosorActual, inicio: inicio, fin: inicio);
        break;
      case HerramientaCroquis.circulo:
        nuevo = ElementoCanvas(id: id, tipo: TipoElemento.circulo, colorValue: _colorActual.value, grosor: _grosorActual, inicio: inicio, fin: inicio);
        break;
      default: return;
    }
    setState(() => _enProgreso = nuevo);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_enProgreso == null) return;
    final pos = PuntoCanvas(d.localPosition.dx, d.localPosition.dy);
    setState(() {
      // Lápiz y goma acumulan puntos (ambos son trazos libres)
      if (_herramienta == HerramientaCroquis.lapiz || _herramienta == HerramientaCroquis.borrador) {
        final puntos = List<PuntoCanvas>.from(_enProgreso!.puntos)..add(pos);
        _enProgreso = _enProgreso!.copyWithPuntos(puntos);
      } else {
        _enProgreso = _enProgreso!.copyWithFin(pos);
      }
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (_enProgreso == null) return;
    setState(() {
      _historial.add(List.from(_elementos));
      _elementos.add(_enProgreso!);
      _enProgreso = null;
      _hayCambios = true;
    });
  }

  Future<void> _pedirTexto(Offset posicion) async {
    final ctrl = TextEditingController();
    final texto = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Agregar texto'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Escribe aquí...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    if (texto != null && texto.trim().isNotEmpty) {
      setState(() {
        _historial.add(List.from(_elementos));
        _elementos.add(ElementoCanvas(
          id: _uuid.v4(), tipo: TipoElemento.texto,
          colorValue: _colorActual.value, grosor: 1,
          inicio: PuntoCanvas(posicion.dx, posicion.dy),
          texto: texto.trim(), fontSize: _fontSizeActual,
        ));
        _hayCambios = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        // En modo local, al hacer back también devolvemos los elementos
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.esModoLocal ? _listo : () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Croquis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.titulo, style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
        actions: [
          IconButton(onPressed: _historial.isEmpty ? null : _deshacer, icon: const Icon(Icons.undo_rounded), tooltip: 'Deshacer'),
          IconButton(onPressed: _elementos.isEmpty ? null : _limpiarTodo, icon: const Icon(Icons.delete_outline_rounded), tooltip: 'Limpiar'),

          // Botón derecho: "Listo" en modo local, "Guardar" en modo Firestore
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: widget.esModoLocal
                // MODO LOCAL: siempre habilitado, devuelve los elementos
                ? TextButton.icon(
                    onPressed: _listo,
                    icon: const Icon(Icons.check_rounded, size: 18, color: Colors.greenAccent),
                    label: const Text('Listo', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600)),
                  )
                // MODO FIRESTORE: guarda en Firestore
                : TextButton.icon(
                    onPressed: (!_hayCambios || _isSaving) ? null : _guardarFirestore,
                    icon: _isSaving
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.save_rounded, size: 18, color: _hayCambios ? Colors.greenAccent : Colors.white38),
                    label: Text('Guardar', style: TextStyle(color: _hayCambios ? Colors.greenAccent : Colors.white38, fontWeight: FontWeight.w600)),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : Column(
              children: [
                // ── Barra de herramientas ──────────────────────────────────
                _ToolBar(
                  herramientaActiva: _herramienta,
                  colorActual: _colorActual,
                  colores: _colores,
                  onHerramienta: (h) => setState(() => _herramienta = h),
                  onColor: (c) => setState(() => _colorActual = c),
                ),

                // ── Cabecera: Espesores + Inspector (scrollable) ───────────
                _CabeceraCroquis(
                  espesorCuello: _espesorCuelloCtrl,
                  espesorTapa: _espesorTapaCtrl,
                  espesorFlange: _espesorFlangeCtrl,
                  instrumento: _instrumentoCtrl,
                  inspector: _inspectorCtrl,
                  fecha: _fechaCtrl,
                  resultado: _resultadoCtrl,
                  inicio: _inicioCtrl,
                  fin: _finCtrl,
                  onChanged: () => _hayCambios = true,
                ),

                // ── Canvas ────────────────────────────────────────────────
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: CroquisPainter(elementos: _elementos, elementoEnProgreso: _enProgreso),
                          child: Container(),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Slider grosor (lápiz/formas) ──────────────────────────
                if (_herramienta != HerramientaCroquis.texto && _herramienta != HerramientaCroquis.borrador)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.line_weight_rounded, color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: _grosorActual, min: 1, max: 20, divisions: 19,
                            activeColor: _colorActual, inactiveColor: Colors.white24,
                            label: '${_grosorActual.round()} px',
                            onChanged: (v) => setState(() => _grosorActual = v),
                          ),
                        ),
                        Text('${_grosorActual.round()} px', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),

                // ── Slider grosor de la goma ──────────────────────────────
                if (_herramienta == HerramientaCroquis.borrador)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_fix_normal_rounded, color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: _grosorBorrador, min: 8, max: 60, divisions: 26,
                            activeColor: Colors.white, inactiveColor: Colors.white24,
                            label: 'Goma ${_grosorBorrador.round()} px',
                            onChanged: (v) => setState(() => _grosorBorrador = v),
                          ),
                        ),
                        Text('${_grosorBorrador.round()} px', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),

                // ── Slider tamaño texto ───────────────────────────────────
                if (_herramienta == HerramientaCroquis.texto)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.format_size_rounded, color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: _fontSizeActual, min: 10, max: 48, divisions: 19,
                            activeColor: _colorActual, inactiveColor: Colors.white24,
                            label: '${_fontSizeActual.round()} pt',
                            onChanged: (v) => setState(() => _fontSizeActual = v),
                          ),
                        ),
                        Text('${_fontSizeActual.round()} pt', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),

                // ── Pie: Observaciones (checkboxes Sí/No) ──────────────────
                _PieCroquis(
                  placaFabricacion: _placaFabricacion,
                  reparacionTanque: _reparacionTanque,
                  onPlacaChanged: (v) => setState(() { _placaFabricacion = v; _hayCambios = true; }),
                  onReparacionChanged: (v) => setState(() { _reparacionTanque = v; _hayCambios = true; }),
                ),
              ],
            ),
    );
  }
}

// ─── Barra de herramientas ─────────────────────────────────────────────────────
class _ToolBar extends StatelessWidget {
  final HerramientaCroquis herramientaActiva;
  final Color colorActual;
  final List<Color> colores;
  final ValueChanged<HerramientaCroquis> onHerramienta;
  final ValueChanged<Color> onColor;

  const _ToolBar({
    required this.herramientaActiva,
    required this.colorActual,
    required this.colores,
    required this.onHerramienta,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolBtn(icon: Icons.edit_rounded,            label: 'Lápiz',   herramienta: HerramientaCroquis.lapiz,      activa: herramientaActiva, onTap: onHerramienta),
              _ToolBtn(icon: Icons.remove_rounded,          label: 'Línea',   herramienta: HerramientaCroquis.linea,      activa: herramientaActiva, onTap: onHerramienta),
              _ToolBtn(icon: Icons.crop_square_rounded,     label: 'Rect',    herramienta: HerramientaCroquis.rectangulo, activa: herramientaActiva, onTap: onHerramienta),
              _ToolBtn(icon: Icons.circle_outlined,         label: 'Círculo', herramienta: HerramientaCroquis.circulo,    activa: herramientaActiva, onTap: onHerramienta),
              _ToolBtn(icon: Icons.text_fields_rounded,     label: 'Texto',   herramienta: HerramientaCroquis.texto,      activa: herramientaActiva, onTap: onHerramienta),
              _ToolBtn(icon: Icons.auto_fix_normal_rounded, label: 'Borrar',  herramienta: HerramientaCroquis.borrador,   activa: herramientaActiva, onTap: onHerramienta),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: colores.map((c) {
                final selected = c.value == colorActual.value;
                return GestureDetector(
                  onTap: () => onColor(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: selected ? 30 : 24, height: selected ? 30 : 24,
                    decoration: BoxDecoration(
                      color: c, shape: BoxShape.circle,
                      border: Border.all(color: selected ? Colors.white : Colors.white24, width: selected ? 2.5 : 1),
                      boxShadow: selected ? [BoxShadow(color: c.withOpacity(0.6), blurRadius: 6)] : [],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final HerramientaCroquis herramienta;
  final HerramientaCroquis activa;
  final ValueChanged<HerramientaCroquis> onTap;

  const _ToolBtn({required this.icon, required this.label, required this.herramienta, required this.activa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = herramienta == activa;
    return GestureDetector(
      onTap: () => onTap(herramienta),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6C63FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? const Color(0xFF6C63FF) : Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.white60, size: 20),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, color: isActive ? Colors.white : Colors.white60, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ─── Cabecera del croquis: Espesores + Inspector ────────────────────────────────
class _CabeceraCroquis extends StatelessWidget {
  final TextEditingController espesorCuello, espesorTapa, espesorFlange, instrumento;
  final TextEditingController inspector, fecha, resultado, inicio, fin;
  final VoidCallback onChanged;

  const _CabeceraCroquis({
    required this.espesorCuello, required this.espesorTapa, required this.espesorFlange,
    required this.instrumento, required this.inspector, required this.fecha,
    required this.resultado, required this.inicio, required this.fin,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.straighten_rounded, color: Colors.white54, size: 14),
              const SizedBox(width: 6),
              const Text('Espesores y Ubicación de Radiografías',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          // Fila 1: Espesores con sufijo mm + instrumento
          Row(children: [
            Expanded(child: _mini(espesorCuello, 'Cuello', 'mm')),
            const SizedBox(width: 6),
            Expanded(child: _mini(espesorTapa, 'Tapa', 'mm')),
            const SizedBox(width: 6),
            Expanded(child: _mini(espesorFlange, 'Flange', 'mm')),
            const SizedBox(width: 6),
            Expanded(flex: 2, child: _mini(instrumento, 'Instrumento', null)),
          ]),
          const SizedBox(height: 6),
          // Fila 2: Inspector / Fecha / Resultado
          Row(children: [
            Expanded(flex: 2, child: _mini(inspector, 'Inspector', null)),
            const SizedBox(width: 6),
            Expanded(child: _mini(fecha, 'Fecha', null)),
            const SizedBox(width: 6),
            Expanded(child: _mini(resultado, 'Resultado', null)),
          ]),
          const SizedBox(height: 6),
          // Fila 3: Inicio / Fin
          Row(children: [
            Expanded(child: _mini(inicio, 'Inicio', null)),
            const SizedBox(width: 6),
            Expanded(child: _mini(fin, 'Fin', null)),
            const Spacer(),
          ]),
        ],
      ),
    );
  }

  Widget _mini(TextEditingController ctrl, String label, String? sufijo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        SizedBox(
          height: 32,
          child: TextField(
            controller: ctrl,
            onChanged: (_) => onChanged(),
            style: const TextStyle(fontSize: 12, color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              filled: true, fillColor: Colors.white.withOpacity(0.08),
              suffixText: sufijo,
              suffixStyle: const TextStyle(fontSize: 10, color: Colors.white38),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Pie del croquis: Observaciones con checkboxes Sí/No ────────────────────────
class _PieCroquis extends StatelessWidget {
  final bool? placaFabricacion;
  final bool? reparacionTanque;
  final ValueChanged<bool?> onPlacaChanged;
  final ValueChanged<bool?> onReparacionChanged;

  const _PieCroquis({
    required this.placaFabricacion,
    required this.reparacionTanque,
    required this.onPlacaChanged,
    required this.onReparacionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rtl_rounded, color: Colors.white54, size: 14),
              const SizedBox(width: 6),
              const Text('Observaciones',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          _filaSiNo('Placa Fabr. Tanque', placaFabricacion, onPlacaChanged),
          const SizedBox(height: 6),
          _filaSiNo('Reparación Tanque', reparacionTanque, onReparacionChanged),
        ],
      ),
    );
  }

  Widget _filaSiNo(String label, bool? valor, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
        // Botón Sí
        _opcion('Sí', valor == true, () => onChanged(valor == true ? null : true), Colors.green),
        const SizedBox(width: 8),
        // Botón No
        _opcion('No', valor == false, () => onChanged(valor == false ? null : false), Colors.red),
      ],
    );
  }

  Widget _opcion(String texto, bool seleccionado, VoidCallback onTap, MaterialColor color) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado ? color.shade600 : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: seleccionado ? color.shade400 : Colors.white24, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              seleccionado ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 14,
              color: seleccionado ? Colors.white : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(texto, style: TextStyle(
              color: seleccionado ? Colors.white : Colors.white60,
              fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            )),
          ],
        ),
      ),
    );
  }
}
