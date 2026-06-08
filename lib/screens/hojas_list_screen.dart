// lib/screens/hojas_list_screen.dart
// Lista de todas las Hojas de Terreno (visible para todos los usuarios)

import 'package:flutter/material.dart';
import '../models/hoja_terreno.dart';
import '../services/auth_service.dart';
import '../services/hoja_terreno_service.dart';
import 'hoja_terreno_form_screen.dart';
import 'pdf_preview_screen.dart';

class HojasListScreen extends StatelessWidget {
  const HojasListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Hojas de Terreno',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      // Botón flotante para crear nueva hoja
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const HojaTerrenoFormScreen(),
          ),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva hoja', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<HojaTerreno>>(
        stream: HojaTerrenoService.listarTodas(),
        builder: (context, snapshot) {

          // Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  const Text('Error al cargar las hojas'),
                ],
              ),
            );
          }

          final hojas = snapshot.data ?? [];

          // Lista vacía
          if (hojas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No hay hojas de terreno aún',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toca el botón + para crear la primera',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          // Lista con todas las hojas
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: hojas.length,
            itemBuilder: (context, index) {
              final hoja = hojas[index];
              final esMia = hoja.creadaPor == currentUid;

              return _HojaCard(
                hoja: hoja,
                esMia: esMia,
                currentUid: currentUid,
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Tarjeta de cada Hoja ──────────────────────────────────────────────────
class _HojaCard extends StatelessWidget {
  final HojaTerreno hoja;
  final bool esMia;
  final String currentUid;

  const _HojaCard({
    required this.hoja,
    required this.esMia,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esMia
              ? const Color(0xFF6C63FF).withOpacity(0.3)
              : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HojaTerrenoFormScreen(hojaId: hoja.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: título + badges
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hoja.titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  // Badge tipo inspección
                  _Badge(
                    label: hoja.tipoInspeccion == TipoInspeccion.periodica
                        ? 'PERIÓDICA'
                        : 'FABRICACIÓN',
                    color: hoja.tipoInspeccion == TipoInspeccion.periodica
                        ? Colors.blue
                        : Colors.orange,
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Cliente
              if (hoja.cliente.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.business_rounded, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      hoja.cliente,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // Datos rápidos
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (hoja.certificadoNumero.isNotEmpty)
                    _DataChip(label: 'Cert. ${hoja.certificadoNumero}'),
                  if (hoja.capacidad.isNotEmpty)
                    _DataChip(label: hoja.capacidad),
                  if (hoja.normaAplicada.isNotEmpty)
                    _DataChip(label: hoja.normaAplicada),
                ],
              ),

              const SizedBox(height: 10),

              // Footer: creador + fecha + acciones
              Row(
                children: [
                  Icon(Icons.person_outline_rounded, size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      esMia ? 'Creada por mí' : hoja.creadaPorNombre,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ),
                  Text(
                    _formatFecha(hoja.modificadaEn),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                  // Botón exportar PDF (disponible para todos)
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PdfPreviewScreen(hoja: hoja)),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 18,
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                  // Solo el creador ve el botón eliminar
                  if (esMia) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _confirmarEliminar(context),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red.shade300,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar hoja'),
        content: Text(
          '¿Estás seguro de eliminar "${hoja.titulo}"?\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await HojaTerrenoService.eliminar(hoja.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diff = ahora.difference(fecha);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final MaterialColor color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color.shade700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DataChip extends StatelessWidget {
  final String label;
  const _DataChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
      ),
    );
  }
}
