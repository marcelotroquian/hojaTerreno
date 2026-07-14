// lib/screens/hoja_terreno_form_screen.dart
// Formulario crear/editar Hoja de Terreno.
// El croquis vive en _elementosCroquis (memoria) durante la creación
// y se guarda en Firestore junto con la hoja al presionar "Guardar".

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/canvas_element.dart';
import '../models/croquis_datos.dart';
import '../models/hoja_terreno.dart';
import '../services/auth_service.dart';
import '../services/borrador_service.dart';
import '../services/croquis_service.dart';
import '../services/hoja_terreno_service.dart';
import '../services/profile_service.dart';
import 'croquis_screen.dart';
import '../services/fotos_service.dart';
import '../widgets/fotos_hoja_widget.dart';
import '../models/inspeccion_radiografica.dart';
import '../models/inspeccion_fabricacion.dart';
import '../models/prueba_hermeticidad.dart';
import '../models/inspeccion_recubrimiento.dart';
import '../models/verificacion_accesorios.dart';
import '../models/placa_identificacion.dart';
import '../services/secciones_service.dart';
import '../widgets/secciones_hoja_widget.dart';

class HojaTerrenoFormScreen extends StatefulWidget {
  final String? hojaId;
  final String? draftId; // si viene, carga un borrador local existente
  const HojaTerrenoFormScreen({super.key, this.hojaId, this.draftId});
  bool get esEdicion => hojaId != null;

  @override
  State<HojaTerrenoFormScreen> createState() => _HojaTerrenoFormScreenState();
}

class _HojaTerrenoFormScreenState extends State<HojaTerrenoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tanqueCtrl        = TextEditingController();
  final _serieCtrl         = TextEditingController();
  final _certificadoCtrl   = TextEditingController();
  final _patenteCtrl       = TextEditingController();
  final _planoCtrl         = TextEditingController();
  final _clienteCtrl       = TextEditingController();
  final _capacidadCtrl     = TextEditingController();
  final _normaCtrl         = TextEditingController();
  final _protocoloCtrl     = TextEditingController();
  final _maestranzaCtrl    = TextEditingController();
  final _materialCtrl      = TextEditingController();
  final _certAnteriorCtrl  = TextEditingController();
  final _chassisVinCtrl    = TextEditingController();
  final _patenteVehiculoCtrl = TextEditingController();

  TipoInspeccion _tipoInspeccion = TipoInspeccion.periodica;
  Set<TipoTanque> _tiposTanque = {};

  // ── Croquis: lista de elementos en memoria ─────────────────────────────────
  List<ElementoCanvas> _elementosCroquis = [];
  CroquisDatos _datosCroquis = const CroquisDatos();

  // ── Fotos: archivos locales en memoria (se suben al guardar) ─────────────────
  List<Uint8List> _archivosLocalesFotos = [];
  List<String> _urlsFotos = []; // URLs ya subidas (modo edición)

  // ── Secciones: datos en memoria ───────────────────────────────────────────
  InspeccionRadiografica _radiografica = const InspeccionRadiografica();
  InspeccionFabricacion _fabricacion = const InspeccionFabricacion();
  PruebaHermeticidad _hermeticidad = const PruebaHermeticidad();
  InspeccionRecubrimiento _recubrimiento = const InspeccionRecubrimiento();
  VerificacionAccesorios _accesorios = const VerificacionAccesorios();
  PlacaIdentificacion _placa = const PlacaIdentificacion();

  bool _isLoading = true;
  bool _isSaving  = false;
  HojaTerreno? _hojaOriginal;

  // ── Autoguardado de borrador local ─────────────────────────────────────────
  late String _draftId;          // id del borrador local de esta sesión
  Timer? _debounce;              // para no guardar en cada tecla, sino tras una pausa
  bool _hojaCreada = false;      // si se creó la hoja, ya no autoguardamos borrador
  bool _huboCambios = false;     // si el inspector tocó algo

  @override
  void initState() {
    super.initState();
    if (widget.esEdicion) {
      _cargarHoja();
    } else {
      // draftId: el del borrador que se abre, o uno nuevo basado en timestamp
      _draftId = widget.draftId ?? 'draft_${DateTime.now().millisecondsSinceEpoch}';
      if (widget.draftId != null) {
        _cargarBorrador(widget.draftId!);
      } else {
        _isLoading = false;
      }
      // Autoguardado al escribir en cualquier campo de texto
      _engancharAutoguardado();
    }
  }

  // Engancha un listener a cada controller para autoguardar tras escribir
  void _engancharAutoguardado() {
    for (final c in [
      _tanqueCtrl, _serieCtrl, _certificadoCtrl, _patenteCtrl, _planoCtrl,
      _clienteCtrl, _capacidadCtrl, _normaCtrl, _protocoloCtrl, _maestranzaCtrl,
      _materialCtrl, _certAnteriorCtrl, _chassisVinCtrl, _patenteVehiculoCtrl,
    ]) {
      c.addListener(_programarAutoguardado);
    }
  }

  // Espera 800ms tras el último cambio antes de guardar (debounce)
  void _programarAutoguardado() {
    _huboCambios = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _autoguardarBorrador);
  }

  // Serializa TODO el estado del formulario a un Map (para guardar como borrador)
  Map<String, dynamic> _serializarEstado() {
    return {
      'tanqueNumero': _tanqueCtrl.text,
      'serieNumero': _serieCtrl.text,
      'certificadoNumero': _certificadoCtrl.text,
      'patenteNumero': _patenteCtrl.text,
      'planoNumero': _planoCtrl.text,
      'cliente': _clienteCtrl.text,
      'capacidad': _capacidadCtrl.text,
      'normaAplicada': _normaCtrl.text,
      'protocoloNumero': _protocoloCtrl.text,
      'maestranza': _maestranzaCtrl.text,
      'material': _materialCtrl.text,
      'certificadoAnterior': _certAnteriorCtrl.text,
      'numeroChassisVin': _chassisVinCtrl.text,
      'patenteVehiculo': _patenteVehiculoCtrl.text,
      'tipoInspeccion': _tipoInspeccion.name,
      'tiposTanque': _tiposTanque.map((t) => t.name).toList(),
      // Secciones
      'radiografica': _radiografica.toMap(),
      'fabricacion': _fabricacion.toMap(),
      'hermeticidad': _hermeticidad.toMap(),
      'recubrimiento': _recubrimiento.toMap(),
      'accesorios': _accesorios.toMap(),
      'placa': _placa.toMap(),
      // Croquis (elementos + datos)
      'croquisElementos': _elementosCroquis.map((e) => e.toMap()).toList(),
      'croquisDatos': _datosCroquis.toMap(),
      // Fotos como base64 (para que sobrevivan en el borrador local)
      'fotos': _archivosLocalesFotos.map((b) => base64Encode(b)).toList(),
    };
  }

  // Guarda el borrador local (sin bloquear la UI)
  Future<void> _autoguardarBorrador() async {
    // No autoguardamos en modo edición ni si ya se creó la hoja
    if (widget.esEdicion || _hojaCreada || !_huboCambios) return;

    // Si todo está vacío, no creamos un borrador basura
    if (_estaVacio()) return;

    final borrador = BorradorLocal(
      draftId: _draftId,
      guardadoEn: DateTime.now(),
      datos: _serializarEstado(),
    );
    await BorradorService.guardar(borrador);
  }

  bool _estaVacio() {
    return _tanqueCtrl.text.isEmpty &&
        _clienteCtrl.text.isEmpty &&
        _serieCtrl.text.isEmpty &&
        _elementosCroquis.isEmpty &&
        _archivosLocalesFotos.isEmpty &&
        !_radiografica.tieneContenido &&
        !_fabricacion.tieneContenido;
  }

  // Carga un borrador local en el formulario
  Future<void> _cargarBorrador(String draftId) async {
    final b = await BorradorService.obtener(draftId);
    if (b == null) { setState(() => _isLoading = false); return; }
    final d = b.datos;

    _tanqueCtrl.text = d['tanqueNumero'] ?? '';
    _serieCtrl.text = d['serieNumero'] ?? '';
    _certificadoCtrl.text = d['certificadoNumero'] ?? '';
    _patenteCtrl.text = d['patenteNumero'] ?? '';
    _planoCtrl.text = d['planoNumero'] ?? '';
    _clienteCtrl.text = d['cliente'] ?? '';
    _capacidadCtrl.text = d['capacidad'] ?? '';
    _normaCtrl.text = d['normaAplicada'] ?? '';
    _protocoloCtrl.text = d['protocoloNumero'] ?? '';
    _maestranzaCtrl.text = d['maestranza'] ?? '';
    _materialCtrl.text = d['material'] ?? '';
    _certAnteriorCtrl.text = d['certificadoAnterior'] ?? '';
    _chassisVinCtrl.text = d['numeroChassisVin'] ?? '';
    _patenteVehiculoCtrl.text = d['patenteVehiculo'] ?? '';

    _tipoInspeccion = (d['tipoInspeccion'] == 'fabricacion')
        ? TipoInspeccion.fabricacion : TipoInspeccion.periodica;
    _tiposTanque = ((d['tiposTanque'] as List?) ?? [])
        .map((t) => TipoTanque.values.firstWhere((e) => e.name == t, orElse: () => TipoTanque.horizontal))
        .toSet();

    if (d['radiografica'] != null) _radiografica = InspeccionRadiografica.fromMap(Map<String, dynamic>.from(d['radiografica']));
    if (d['fabricacion'] != null) _fabricacion = InspeccionFabricacion.fromMap(Map<String, dynamic>.from(d['fabricacion']));
    if (d['hermeticidad'] != null) _hermeticidad = PruebaHermeticidad.fromMap(Map<String, dynamic>.from(d['hermeticidad']));
    if (d['recubrimiento'] != null) _recubrimiento = InspeccionRecubrimiento.fromMap(Map<String, dynamic>.from(d['recubrimiento']));
    if (d['accesorios'] != null) _accesorios = VerificacionAccesorios.fromMap(Map<String, dynamic>.from(d['accesorios']));
    if (d['placa'] != null) _placa = PlacaIdentificacion.fromMap(Map<String, dynamic>.from(d['placa']));

    _elementosCroquis = ((d['croquisElementos'] as List?) ?? [])
        .map((e) => ElementoCanvas.fromMap(Map<String, dynamic>.from(e))).toList();
    if (d['croquisDatos'] != null) _datosCroquis = CroquisDatos.fromMap(Map<String, dynamic>.from(d['croquisDatos']));

    _archivosLocalesFotos = ((d['fotos'] as List?) ?? [])
        .map((b64) => base64Decode(b64 as String)).toList();

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tanqueCtrl.dispose(); _serieCtrl.dispose(); _certificadoCtrl.dispose();
    _patenteCtrl.dispose(); _planoCtrl.dispose(); _clienteCtrl.dispose();
    _capacidadCtrl.dispose(); _normaCtrl.dispose(); _protocoloCtrl.dispose();
    _maestranzaCtrl.dispose(); _materialCtrl.dispose(); _certAnteriorCtrl.dispose();
    _chassisVinCtrl.dispose(); _patenteVehiculoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarHoja() async {
    final hoja = await HojaTerrenoService.escuchar(widget.hojaId!).first;
    if (hoja == null || !mounted) return;

    // Mostramos de inmediato los datos principales de la hoja (rápido),
    // así el formulario aparece sin esperar croquis/secciones/fotos.
    setState(() {
      _hojaOriginal        = hoja;
      _tanqueCtrl.text     = hoja.tanqueNumero;
      _serieCtrl.text      = hoja.serieNumero;
      _certificadoCtrl.text = hoja.certificadoNumero;
      _patenteCtrl.text    = hoja.patenteNumero;
      _planoCtrl.text      = hoja.planoNumero;
      _clienteCtrl.text    = hoja.cliente;
      _capacidadCtrl.text  = hoja.capacidad;
      _maestranzaCtrl.text = hoja.maestranza;
      _materialCtrl.text   = hoja.material;
      _certAnteriorCtrl.text = hoja.certificadoAnterior;
      _chassisVinCtrl.text = hoja.numeroChassisVin;
      _patenteVehiculoCtrl.text = hoja.patenteVehiculo;
      _tiposTanque         = Set.from(hoja.tiposTanque);
      _tipoInspeccion      = hoja.tipoInspeccion;
      _normaCtrl.text      = hoja.normaAplicada;
      _protocoloCtrl.text  = hoja.protocoloNumero;
      _isLoading           = false; // ← el formulario ya se ve
    });

    // Cargamos croquis, fotos y las 6 secciones EN PARALELO (no una tras otra).
    // Future.wait lanza todas a la vez; esperamos solo lo que tarde la más lenta.
    final resultados = await Future.wait([
      CroquisService.cargar(widget.hojaId!),          // 0
      CroquisService.cargarDatos(widget.hojaId!),     // 1
      FotosService.obtenerUrls(widget.hojaId!),       // 2
      SeccionesService.cargarRadiografica(widget.hojaId!),  // 3
      SeccionesService.cargarFabricacion(widget.hojaId!),   // 4
      SeccionesService.cargarHermeticidad(widget.hojaId!),  // 5
      SeccionesService.cargarRecubrimiento(widget.hojaId!), // 6
      SeccionesService.cargarAccesorios(widget.hojaId!),    // 7
      SeccionesService.cargarPlaca(widget.hojaId!),         // 8
    ]);

    if (!mounted) return;
    setState(() {
      _elementosCroquis = resultados[0] as List<ElementoCanvas>;
      _datosCroquis     = resultados[1] as CroquisDatos;
      _urlsFotos        = (resultados[2] as List).cast<String>();
      _radiografica     = resultados[3] as InspeccionRadiografica;
      _fabricacion      = resultados[4] as InspeccionFabricacion;
      _hermeticidad     = resultados[5] as PruebaHermeticidad;
      _recubrimiento    = resultados[6] as InspeccionRecubrimiento;
      _accesorios       = resultados[7] as VerificacionAccesorios;
      _placa            = resultados[8] as PlacaIdentificacion;
    });
  }

  // ── Abrir editor de croquis (funciona en creación Y edición) ──────────────
  Future<void> _abrirCroquis() async {
    final titulo = _tanqueCtrl.text.isNotEmpty
        ? 'Tanque Nº ${_tanqueCtrl.text}'
        : 'Nueva Hoja de Terreno';

    // En modo CREACIÓN: modo local → recibe de vuelta los elementos
    // En modo EDICIÓN:  modo Firestore → guarda directamente en Firestore
    if (esModoLocal) {
      // push y esperamos el resultado (CroquisResultado?)
      final resultado = await Navigator.push<CroquisResultado>(
        context,
        MaterialPageRoute(
          builder: (_) => CroquisScreen(
            titulo: titulo,
            elementosIniciales: _elementosCroquis,
            datosIniciales: _datosCroquis,
          ),
        ),
      );
      // Si el usuario presionó "Listo", actualizamos elementos y datos
      if (resultado != null) {
        setState(() {
          _elementosCroquis = resultado.elementos;
          _datosCroquis = resultado.datos;
        });
        _programarAutoguardado();
      }
    } else {
      // En edición abrimos con hojaId → guarda directo en Firestore
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CroquisScreen(
            hojaId: widget.hojaId,
            titulo: titulo,
            elementosIniciales: _elementosCroquis,
            datosIniciales: _datosCroquis,
          ),
        ),
      );
    }
  }

  bool get esModoLocal => !widget.esEdicion;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final uid = AuthService.currentUser?.uid ?? '';
    final datos = HojaTerreno(
      id: widget.hojaId ?? '',
      creadaPor: _hojaOriginal?.creadaPor ?? uid,
      creadaPorNombre: _hojaOriginal?.creadaPorNombre ?? '',
      creadaEn: _hojaOriginal?.creadaEn ?? DateTime.now(),
      modificadaEn: DateTime.now(),
      tanqueNumero:      _tanqueCtrl.text.trim(),
      serieNumero:       _serieCtrl.text.trim(),
      certificadoNumero: _certificadoCtrl.text.trim(),
      patenteNumero:     _patenteCtrl.text.trim(),
      planoNumero:       _planoCtrl.text.trim(),
      cliente:           _clienteCtrl.text.trim(),
      maestranza:        _maestranzaCtrl.text.trim(),
      capacidad:         _capacidadCtrl.text.trim(),
      material:          _materialCtrl.text.trim(),
      tipoInspeccion:    _tipoInspeccion,
      certificadoAnterior: _certAnteriorCtrl.text.trim(),
      numeroChassisVin:  _chassisVinCtrl.text.trim(),
      patenteVehiculo:   _patenteVehiculoCtrl.text.trim(),
      tiposTanque:       _tiposTanque,
      normaAplicada:     _normaCtrl.text.trim(),
      protocoloNumero:   _protocoloCtrl.text.trim(),
    );

    String? error;
    String? hojaIdFinal = widget.hojaId;

    if (widget.esEdicion) {
      error = await HojaTerrenoService.actualizar(id: widget.hojaId!, datos: datos);
    } else {
      final profile = await ProfileService.getProfile(uid);
      final nombre = profile?.name ?? AuthService.currentUser?.displayName ?? 'Usuario';

      // crear() devuelve (hojaId, null) o (null, error)
      final (nuevoId, codigoOError) = await HojaTerrenoService.crear(
        uid: uid, nombreUsuario: nombre, datos: datos,
      );

      if (nuevoId == null) {
        error = codigoOError; // hubo error
      } else {
        hojaIdFinal = nuevoId; // ID real, sin necesidad de buscar
        _hojaCreada = true;    // detenemos el autoguardado de borrador
      }
    }

    // Guardar croquis (elementos + datos) si hay contenido y tenemos el ID
    final hayDatosCroquis = _elementosCroquis.isNotEmpty ||
        _datosCroquis.espesorCuello.isNotEmpty ||
        _datosCroquis.inspector.isNotEmpty ||
        _datosCroquis.placaFabricacionTanque != null ||
        _datosCroquis.reparacionTanque != null;

    if (error == null && hayDatosCroquis && hojaIdFinal != null) {
      await CroquisService.guardar(
        hojaId: hojaIdFinal,
        elementos: _elementosCroquis,
        datos: _datosCroquis,
      );
    }

    // Subir fotos locales si las hay (solo en creación)
    // Storage NO tiene caché offline como Firestore, así que envolvemos cada
    // subida en un timeout para no bloquear el guardado si no hay conexión.
    // Si falla por estar offline, la hoja igual se guarda; las fotos se podrán
    // re-subir al editar la hoja cuando haya internet.
    int fotosFallidas = 0;
    if (error == null && widget.esEdicion == false && _archivosLocalesFotos.isNotEmpty && hojaIdFinal != null) {
      for (int i = 0; i < _archivosLocalesFotos.length; i++) {
        try {
          await FotosService.subirFoto(
            hojaId: hojaIdFinal,
            bytes: _archivosLocalesFotos[i],
            indice: i,
          ).timeout(const Duration(seconds: 15));
        } catch (_) {
          fotosFallidas++; // probablemente sin conexión
        }
      }
    }

    // Guardar secciones si tienen contenido
    if (error == null && hojaIdFinal != null) {
      await SeccionesService.guardarTodas(
        hojaId: hojaIdFinal,
        radiografica: _radiografica,
        fabricacion: _fabricacion,
        hermeticidad: _hermeticidad,
        recubrimiento: _recubrimiento,
        accesorios: _accesorios,
        placa: _placa,
      );
    }

    setState(() => _isSaving = false);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    } else {
      // Al crear la hoja con éxito, eliminamos el borrador local (ya no se necesita)
      if (!widget.esEdicion) {
        await BorradorService.eliminar(_draftId);
      }
      // Mensaje según si quedaron fotos sin subir (offline)
      final msg = fotosFallidas > 0
          ? 'Hoja guardada. $fotosFallidas foto(s) se subirán al recuperar conexión.'
          : (widget.esEdicion ? '¡Hoja actualizada!' : '¡Hoja creada exitosamente!');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: fotosFallidas > 0 ? Colors.orange.shade700 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // canPop: false → controlamos la salida manualmente para garantizar
      // que el borrador se guarde COMPLETO antes de cerrar la pantalla.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // ya salió, nada que hacer

        // Si hay cambios sin guardar y no se creó la hoja, guardamos el borrador
        if (!widget.esEdicion && !_hojaCreada && _huboCambios && !_estaVacio()) {
          _debounce?.cancel();
          await _autoguardarBorrador();
        }
        // Ahora sí salimos (el guardado ya terminó)
        if (mounted) Navigator.of(context).pop(result);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            widget.esEdicion ? 'Editar Hoja de Terreno' : 'Nueva Hoja de Terreno',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF111827),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: Colors.grey.shade100),
          ),
        ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [

                  // ── Identificación ───────────────────────────────────────
                  _SectionHeader(title: 'Identificación', icon: Icons.tag_rounded),
                  const SizedBox(height: 12),
                  _buildRow(
                    _buildField(ctrl: _tanqueCtrl,      label: 'Tanque Nº',      hint: 'Ej: 1234', required: true),
                    _buildField(ctrl: _serieCtrl,       label: 'Serie Nº',       hint: 'Ej: AB-001'),
                  ),
                  const SizedBox(height: 12),
                  _buildRow(
                    _buildField(ctrl: _certificadoCtrl, label: 'Certificado Nº', hint: 'Ej: C-2024'),
                    _buildField(ctrl: _patenteCtrl,     label: 'Patente Nº',     hint: 'Ej: P-001'),
                  ),
                  const SizedBox(height: 12),
                  _buildField(ctrl: _planoCtrl, label: 'Plano Nº', hint: 'Ej: PL-2024-001'),

                  const SizedBox(height: 24),

                  // ── Cliente ──────────────────────────────────────────────
                  _SectionHeader(title: 'Cliente', icon: Icons.business_rounded),
                  const SizedBox(height: 12),
                  _buildRow(
                    _buildField(ctrl: _clienteCtrl,    label: 'Cliente',    hint: 'Nombre del cliente', required: true),
                    _buildField(ctrl: _maestranzaCtrl, label: 'Maestranza', hint: 'Nombre de maestranza'),
                  ),
                  const SizedBox(height: 12),
                  _buildRow(
                    _buildField(ctrl: _capacidadCtrl, label: 'Capacidad', hint: 'Ej: 10.000 lts'),
                    _buildField(ctrl: _materialCtrl,  label: 'Material',  hint: 'Ej: Acero A36'),
                  ),

                  const SizedBox(height: 24),

                  // ── Tipo de Inspección ────────────────────────────────────
                  _SectionHeader(title: 'Tipo de Inspección', icon: Icons.checklist_rounded),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF9FAFB),
                    ),
                    child: Column(
                      children: [
                        _TipoInspeccionTile(label: 'PERIÓDICA',   descripcion: 'Inspección periódica del equipo',          valor: TipoInspeccion.periodica,   seleccionado: _tipoInspeccion, onChanged: (v) { setState(() => _tipoInspeccion = v); _programarAutoguardado(); }),
                        Divider(height: 1, color: Colors.grey.shade200),
                        _TipoInspeccionTile(label: 'FABRICACIÓN', descripcion: 'Inspección en proceso de fabricación',     valor: TipoInspeccion.fabricacion, seleccionado: _tipoInspeccion, onChanged: (v) { setState(() => _tipoInspeccion = v); _programarAutoguardado(); }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Normativa ────────────────────────────────────────────
                  _SectionHeader(title: 'Normativa', icon: Icons.gavel_rounded),
                  const SizedBox(height: 12),
                  _buildRow(
                    _buildField(ctrl: _normaCtrl,     label: 'Norma aplicada', hint: 'Ej: NCh 2369'),
                    _buildField(ctrl: _protocoloCtrl, label: 'Protocolo Nº',   hint: 'Ej: PR-001'),
                  ),
                  const SizedBox(height: 12),
                  _buildField(ctrl: _certAnteriorCtrl, label: 'Certificado Anterior Nº', hint: 'Ej: C-2023'),

                  const SizedBox(height: 24),

                  // ── Vehículo ──────────────────────────────────────────────
                  _SectionHeader(title: 'Vehículo', icon: Icons.local_shipping_rounded),
                  const SizedBox(height: 12),
                  _buildRow(
                    _buildField(ctrl: _chassisVinCtrl,      label: 'Número Chassis / VIN', hint: 'Ej: 1HGBH...'),
                    _buildField(ctrl: _patenteVehiculoCtrl, label: 'Patente',             hint: 'Ej: ABCD-12'),
                  ),

                  const SizedBox(height: 24),

                  // ── Tipo de Tanque (checkboxes múltiples) ─────────────────
                  _SectionHeader(title: 'Tipo de Tanque', icon: Icons.category_rounded),
                  const SizedBox(height: 8),
                  Text(
                    'Puedes seleccionar varias opciones (ej. Superficie + Vertical)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TipoTanque.values.map((tipo) {
                      final selected = _tiposTanque.contains(tipo);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _tiposTanque.remove(tipo);
                            } else {
                              _tiposTanque.add(tipo);
                            }
                          });
                          _programarAutoguardado();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF6C63FF).withOpacity(0.1) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? const Color(0xFF6C63FF) : Colors.grey.shade200,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18, height: 18,
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFF6C63FF) : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: selected ? const Color(0xFF6C63FF) : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: selected ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tipo.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                  color: selected ? const Color(0xFF6C63FF) : const Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── Secciones de Inspección ───────────────────────────────
                  _SectionHeader(title: 'Secciones de Inspección', icon: Icons.assignment_rounded),
                  const SizedBox(height: 12),

                  SeccionesHojaWidget(
                    hojaId: widget.hojaId,
                    radiografica: _radiografica,
                    fabricacion: _fabricacion,
                    hermeticidad: _hermeticidad,
                    recubrimiento: _recubrimiento,
                    accesorios: _accesorios,
                    placa: _placa,
                    onRadiograficaChanged: (v) { setState(() => _radiografica = v); _programarAutoguardado(); },
                    onFabricacionChanged: (v) { setState(() => _fabricacion = v); _programarAutoguardado(); },
                    onHermeticidadChanged: (v) { setState(() => _hermeticidad = v); _programarAutoguardado(); },
                    onRecubrimientoChanged: (v) { setState(() => _recubrimiento = v); _programarAutoguardado(); },
                    onAccesoriosChanged: (v) { setState(() => _accesorios = v); _programarAutoguardado(); },
                    onPlacaChanged: (v) { setState(() => _placa = v); _programarAutoguardado(); },
                  ),

                  const SizedBox(height: 24),

                  // ── Fotos ─────────────────────────────────────────────────
                  _SectionHeader(title: 'Fotos', icon: Icons.photo_library_rounded),
                  const SizedBox(height: 12),

                  FotosHojaWidget(
                    hojaId: widget.hojaId,
                    urlsIniciales: _urlsFotos,
                    archivosLocales: _archivosLocalesFotos,
                    onArchivosChanged: (archivos) {
                      setState(() => _archivosLocalesFotos = archivos);
                      _programarAutoguardado();
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── Croquis ───────────────────────────────────────────────
                  _SectionHeader(title: 'Croquis', icon: Icons.draw_rounded),
                  const SizedBox(height: 12),

                  // Botón siempre disponible — modo local en creación,
                  // modo Firestore en edición
                  GestureDetector(
                    onTap: _abrirCroquis,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _elementosCroquis.isNotEmpty
                              ? [const Color(0xFF6C63FF), const Color(0xFF9C95FF)]
                              : [Colors.grey.shade400, Colors.grey.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _elementosCroquis.isNotEmpty ? Icons.draw_rounded : Icons.add_rounded,
                            color: Colors.white, size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _elementosCroquis.isNotEmpty
                                ? 'Editar croquis  (${_elementosCroquis.length} elemento${_elementosCroquis.length == 1 ? '' : 's'})'
                                : 'Agregar croquis',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                        ],
                      ),
                    ),
                  ),

                  // Mini preview: muestra cuántos elementos hay dibujados
                  if (_elementosCroquis.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Croquis con ${_elementosCroquis.length} elemento${_elementosCroquis.length == 1 ? '' : 's'} — se guardará al crear la hoja',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Botón guardar ────────────────────────────────────────
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF6C63FF).withOpacity(0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              widget.esEdicion ? 'Guardar cambios' : 'Crear Hoja de Terreno',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  if (widget.esEdicion && _hojaOriginal != null)
                    Center(
                      child: Text(
                        'Creada por ${_hojaOriginal!.creadaPorNombre}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildField({required TextEditingController ctrl, required String label, String hint = '', bool required = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
              children: required ? const [TextSpan(text: ' *', style: TextStyle(color: Color(0xFF6C63FF)))] : [],
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true, fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
              errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(Widget a, Widget b) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [a, const SizedBox(width: 12), b]);
  }
}

// ─── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Colors.grey.shade200)),
      ],
    );
  }
}

class _TipoInspeccionTile extends StatelessWidget {
  final String label;
  final String descripcion;
  final TipoInspeccion valor;
  final TipoInspeccion seleccionado;
  final ValueChanged<TipoInspeccion> onChanged;

  const _TipoInspeccionTile({required this.label, required this.descripcion, required this.valor, required this.seleccionado, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isSelected = valor == seleccionado;
    return InkWell(
      onTap: () => onChanged(valor),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(5),
                color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
                border: Border.all(color: isSelected ? const Color(0xFF6C63FF) : Colors.grey.shade300, width: 2),
              ),
              child: isSelected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF374151))),
                Text(descripcion, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
