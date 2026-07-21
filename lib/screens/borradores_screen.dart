// lib/screens/borradores_screen.dart
// Lista de borradores locales (autoguardados). El inspector puede reanudarlos o eliminarlos.

import 'package:flutter/material.dart';
import '../services/borrador_service.dart';
import 'hoja_terreno_form_screen.dart';

class BorradoresScreen extends StatefulWidget {
  const BorradoresScreen({super.key});

  @override
  State<BorradoresScreen> createState() => _BorradoresScreenState();
}

class _BorradoresScreenState extends State<BorradoresScreen> {
  List<BorradorLocal> _borradores = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final lista = await BorradorService.listar();
    if (mounted) setState(() { _borradores = lista; _cargando = false; });
  }

  Future<void> _abrir(BorradorLocal b) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HojaTerrenoFormScreen(draftId: b.draftId)),
    );
    _cargar(); // recargar al volver (pudo crearse la hoja o editarse el borrador)
  }

  Future<void> _eliminar(BorradorLocal b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar borrador'),
        content: const Text('¿Seguro que quieres eliminar este borrador? No se podrá recuperar.'),
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
    if (ok == true) {
      await BorradorService.eliminar(b.draftId);
      _cargar();
    }
  }

  String _fecha(DateTime d) {
    final meses = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${meses[d.month - 1]} · $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Borradores', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF60A66B)))
          : _borradores.isEmpty
              ? _vacio()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _borradores.length,
                  itemBuilder: (context, i) {
                    final b = _borradores[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.shade100),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _abrir(b),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.edit_note_rounded, color: Colors.orange.shade600),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('SIN GUARDAR',
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(b.titulo,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                                    Text(b.subtitulo, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                    const SizedBox(height: 2),
                                    Text('Guardado ${_fecha(b.guardadoEn)}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _eliminar(b),
                                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _vacio() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.drafts_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('No hay borradores', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Cuando empieces una hoja y salgas sin crearla, se guardará aquí automáticamente.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}
