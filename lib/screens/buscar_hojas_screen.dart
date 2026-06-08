// lib/screens/buscar_hojas_screen.dart
// Búsqueda de Hojas de Terreno por código HDT, tanque o cliente.

import 'package:flutter/material.dart';
import '../models/hoja_terreno.dart';
import '../services/hoja_terreno_service.dart';
import 'hoja_terreno_form_screen.dart';

class BuscarHojasScreen extends StatefulWidget {
  const BuscarHojasScreen({super.key});

  @override
  State<BuscarHojasScreen> createState() => _BuscarHojasScreenState();
}

class _BuscarHojasScreenState extends State<BuscarHojasScreen> {
  final _queryCtrl = TextEditingController();
  List<HojaTerreno> _resultados = [];
  bool _buscando = false;
  bool _yaBusco = false;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) return;

    setState(() { _buscando = true; _yaBusco = true; });
    final res = await HojaTerrenoService.buscarPorCodigo(q);
    if (mounted) setState(() { _resultados = res; _buscando = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Buscar Hojas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryCtrl,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _buscar(),
                    decoration: InputDecoration(
                      hintText: 'Código HDT, tanque o cliente...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6C63FF)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _buscando ? null : _buscar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
          ),

          // Resultados
          Expanded(
            child: _buscando
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                : !_yaBusco
                    ? _estadoInicial()
                    : _resultados.isEmpty
                        ? _sinResultados()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _resultados.length,
                            itemBuilder: (context, i) => _ResultadoCard(hoja: _resultados[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _estadoInicial() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.manage_search_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Busca una hoja de terreno',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        const SizedBox(height: 6),
        Text('Por código HDT, número de tanque o cliente',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ],
    ),
  );

  Widget _sinResultados() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Sin resultados',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        const SizedBox(height: 6),
        Text('No se encontró ninguna hoja con "${_queryCtrl.text.trim()}"',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            textAlign: TextAlign.center),
      ],
    ),
  );
}

class _ResultadoCard extends StatelessWidget {
  final HojaTerreno hoja;
  const _ResultadoCard({required this.hoja});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HojaTerrenoFormScreen(hojaId: hoja.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Código HDT destacado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hoja.codigoHDT.isNotEmpty ? hoja.codigoHDT : 'Sin código',
                  style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold,
                    color: Color(0xFF6C63FF), letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(hoja.titulo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.business_rounded, size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(hoja.subtitulo,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
