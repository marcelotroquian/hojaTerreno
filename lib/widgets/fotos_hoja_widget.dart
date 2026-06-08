// lib/widgets/fotos_hoja_widget.dart
// Galería de fotos MULTIPLATAFORMA (Web + móvil).
// Trabaja con Uint8List (bytes) en lugar de File para funcionar en navegador.
//   - Con hojaId: sube directamente a Firebase Storage al seleccionar
//   - Sin hojaId (creación): guarda los bytes en memoria y los devuelve al padre

import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/fotos_service.dart';

class FotosHojaWidget extends StatefulWidget {
  final String? hojaId;                          // null = modo local (creación)
  final List<String> urlsIniciales;              // URLs ya guardadas (edición)
  final List<Uint8List> archivosLocales;         // Bytes en memoria (creación)
  final ValueChanged<List<Uint8List>>? onArchivosChanged;

  const FotosHojaWidget({
    super.key,
    this.hojaId,
    this.urlsIniciales = const [],
    this.archivosLocales = const [],
    this.onArchivosChanged,
  });

  bool get esModoLocal => hojaId == null;

  @override
  State<FotosHojaWidget> createState() => _FotosHojaWidgetState();
}

class _FotosHojaWidgetState extends State<FotosHojaWidget> {
  List<String> _urls = [];              // URLs de Firestore (edición)
  List<Uint8List?> _bytes = [];         // Bytes locales (creación), null = vacío
  final Set<int> _subiendo = {};

  @override
  void initState() {
    super.initState();
    if (widget.esModoLocal) {
      _bytes = List.generate(
        FotosService.maxFotos,
        (i) => i < widget.archivosLocales.length ? widget.archivosLocales[i] : null,
      );
    } else {
      _urls = List.from(widget.urlsIniciales);
    }
  }

  int get _cantidadOcupados => widget.esModoLocal
      ? _bytes.where((b) => b != null).length
      : _urls.length;

  // ─── Seleccionar imagen ─────────────────────────────────────────────────────
  Future<void> _seleccionarImagen(int indice) async {
    final source = await _mostrarFuenteDialog();
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );
    if (picked == null) return;

    // readAsBytes() funciona en Web y móvil
    final bytes = await picked.readAsBytes();

    if (widget.esModoLocal) {
      // Modo local: guardamos los bytes en memoria
      setState(() => _bytes[indice] = bytes);
      _notificarCambios();
    } else {
      // Modo Firestore: subimos directamente
      setState(() => _subiendo.add(indice));
      final error = await FotosService.subirFoto(
        hojaId: widget.hojaId!,
        bytes: bytes,
        indice: indice,
      );
      if (!mounted) return;
      setState(() => _subiendo.remove(indice));

      if (error != null) {
        _mostrarError(error);
      } else {
        final urls = await FotosService.obtenerUrls(widget.hojaId!);
        if (mounted) setState(() => _urls = urls);
      }
    }
  }

  // ─── Eliminar imagen ────────────────────────────────────────────────────────
  Future<void> _eliminarImagen(int indice) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar foto'),
        content: const Text('¿Estás seguro de eliminar esta foto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    if (widget.esModoLocal) {
      setState(() => _bytes[indice] = null);
      _notificarCambios();
    } else {
      setState(() => _subiendo.add(indice));
      await FotosService.eliminarFoto(hojaId: widget.hojaId!, indice: indice);
      if (!mounted) return;
      final urls = await FotosService.obtenerUrls(widget.hojaId!);
      setState(() { _urls = urls; _subiendo.remove(indice); });
    }
  }

  void _notificarCambios() {
    widget.onArchivosChanged?.call(_bytes.whereType<Uint8List>().toList());
  }

  Future<ImageSource?> _mostrarFuenteDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Agregar foto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF6C63FF)),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF6C63FF)),
              title: const Text('Tomar una foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _verFoto(int indice) {
    final esLocal = widget.esModoLocal;
    final bytes = esLocal ? _bytes[indice] : null;
    final url   = !esLocal && indice < _urls.length ? _urls[indice] : null;
    if (bytes == null && url == null) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _VisorFoto(bytes: bytes, url: url, numero: indice + 1),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('$_cantidadOcupados / ${FotosService.maxFotos} fotos',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const Spacer(),
            if (_cantidadOcupados > 0)
              Text('Toca una foto para verla',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1,
          ),
          itemCount: FotosService.maxFotos,
          itemBuilder: (context, i) => _SlotFoto(
            indice: i,
            url: (!widget.esModoLocal && i < _urls.length) ? _urls[i] : null,
            bytes: (widget.esModoLocal && i < _bytes.length) ? _bytes[i] : null,
            subiendo: _subiendo.contains(i),
            onAgregar: () => _seleccionarImagen(i),
            onEliminar: () => _eliminarImagen(i),
            onVer: () => _verFoto(i),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.compress_rounded, size: 12, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text('Las fotos se comprimen automáticamente (máx. 200 KB c/u)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ],
        ),
      ],
    );
  }
}

// ─── Slot individual ───────────────────────────────────────────────────────────
class _SlotFoto extends StatelessWidget {
  final int indice;
  final String? url;
  final Uint8List? bytes;
  final bool subiendo;
  final VoidCallback onAgregar;
  final VoidCallback onEliminar;
  final VoidCallback onVer;

  const _SlotFoto({
    required this.indice,
    required this.subiendo,
    required this.onAgregar,
    required this.onEliminar,
    required this.onVer,
    this.url,
    this.bytes,
  });

  bool get tieneContenido => url != null || bytes != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tieneContenido ? onVer : onAgregar,
      child: Container(
        decoration: BoxDecoration(
          color: tieneContenido ? Colors.black : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: tieneContenido ? Colors.transparent : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: subiendo
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 2))
              : tieneContenido
                  ? _buildImagenOcupada()
                  : _buildSlotVacio(),
        ),
      ),
    );
  }

  Widget _buildImagenOcupada() {
    return Stack(
      fit: StackFit.expand,
      children: [
        bytes != null
            ? Image.memory(bytes!, fit: BoxFit.cover)
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (c, u) => Container(
                  color: Colors.grey.shade100,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (c, u, e) => Container(
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                ),
              ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 4, left: 6,
          child: Text('${indice + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: onEliminar,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotVacio() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded, color: Colors.grey.shade300, size: 28),
        const SizedBox(height: 4),
        Text('${indice + 1}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade300, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Visor a pantalla completa ──────────────────────────────────────────────────
class _VisorFoto extends StatelessWidget {
  final Uint8List? bytes;
  final String? url;
  final int numero;

  const _VisorFoto({this.bytes, this.url, required this.numero});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Foto $numero', style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5, maxScale: 4.0,
          child: bytes != null
              ? Image.memory(bytes!, fit: BoxFit.contain)
              : CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.contain,
                  placeholder: (c, u) => const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (c, u, e) => const Icon(Icons.broken_image_rounded, color: Colors.white, size: 64),
                ),
        ),
      ),
    );
  }
}
