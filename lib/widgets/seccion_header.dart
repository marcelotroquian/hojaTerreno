// lib/widgets/seccion_header.dart
// Widget de encabezado de sección compartido entre pantallas de inspección

import 'package:flutter/material.dart';

class SeccionHeader extends StatelessWidget {
  final String numero;
  final String titulo;

  const SeccionHeader({super.key, required this.numero, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3540),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        if (numero.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF60A66B),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(numero,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 10),
        ],
        Text(titulo,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
    );
  }
}
