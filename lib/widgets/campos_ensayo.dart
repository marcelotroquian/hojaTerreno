// lib/widgets/campos_ensayo.dart
// Widgets compartidos para las secciones (ensayos) de la Hoja de Terreno:
//   - AutocompletarEnsayo: rellena inspector (perfil del usuario) y fecha actual
//   - CampoHora: selector de hora nativo, formato HH:mm
//   - CampoResultado: lista desplegable OK / No Conforme
//   - CamposEnsayo.validarPares: detecta horas inválidas o inicio > fin
// Todo queda editable: el inspector puede cambiar nombre, fecha y horas cuando quiera.

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

// ─── Autocompletado de inspector y fecha ───────────────────────────────────────
class AutocompletarEnsayo {
  // Rellena SOLO si están vacíos (respeta lo que ya haya escrito el inspector)
  static Future<void> aplicar({
    required TextEditingController inspector,
    required TextEditingController fecha,
  }) async {
    // Fecha actual dd/mm/aaaa
    if (fecha.text.trim().isEmpty) {
      final n = DateTime.now();
      fecha.text =
          '${n.day.toString().padLeft(2, '0')}/${n.month.toString().padLeft(2, '0')}/${n.year}';
    }
    // Nombre del usuario logueado (desde su perfil)
    if (inspector.text.trim().isEmpty) {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) return;
      try {
        final p = await ProfileService.getProfile(uid);
        final nombre = p?.name ?? AuthService.currentUser?.displayName ?? '';
        // Doble chequeo: quizás escribió algo mientras cargaba el perfil
        if (nombre.isNotEmpty && inspector.text.trim().isEmpty) {
          inspector.text = nombre;
        }
      } catch (_) {}
    }
  }
}

// ─── Validación de horas ───────────────────────────────────────────────────────
class CamposEnsayo {
  // Convierte "HH:mm" a minutos; null si es inválida o está vacía
  static int? _aMinutos(String hhmm) {
    final t = hhmm.trim();
    if (t.isEmpty) return null;
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(t);
    if (m == null) return null;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    if (h > 23 || min > 59) return null;
    return h * 60 + min;
  }

  // Valida una lista de pares (inicio, fin).
  // Devuelve un mensaje de error, o null si todo está bien.
  static String? validarPares(List<(TextEditingController, TextEditingController)> pares) {
    for (final (ini, fin) in pares) {
      final i = _aMinutos(ini.text);
      final f = _aMinutos(fin.text);
      if (ini.text.trim().isNotEmpty && i == null) {
        return 'Hora de inicio inválida: "${ini.text}". Usa formato HH:mm';
      }
      if (fin.text.trim().isNotEmpty && f == null) {
        return 'Hora de fin inválida: "${fin.text}". Usa formato HH:mm';
      }
      if (i != null && f != null && i > f) {
        return 'La hora de inicio (${ini.text}) no puede ser mayor que la de fin (${fin.text}).';
      }
    }
    return null;
  }
}

// ─── Campo de hora con time picker nativo ──────────────────────────────────────
class CampoHora extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback? onChanged;

  const CampoHora({
    super.key,
    required this.controller,
    required this.label,
    this.onChanged,
  });

  Future<void> _abrirPicker(BuildContext context) async {
    // Hora inicial del picker: la ya escrita, o la hora actual
    TimeOfDay inicial = TimeOfDay.now();
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(controller.text.trim());
    if (m != null) {
      final h = int.parse(m.group(1)!);
      final min = int.parse(m.group(2)!);
      if (h <= 23 && min <= 59) inicial = TimeOfDay(hour: h, minute: min);
    }

    final elegida = await showTimePicker(
      context: context,
      initialTime: inicial,
      helpText: 'Selecciona la hora',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF6C63FF)),
        ),
        child: child!,
      ),
    );
    if (elegida != null) {
      controller.text =
          '${elegida.hour.toString().padLeft(2, '0')}:${elegida.minute.toString().padLeft(2, '0')}';
      onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 4),
        // ValueListenableBuilder para que el ícono de limpiar aparezca/desaparezca
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => TextField(
            controller: controller,
            readOnly: true, // se llena con el picker (evita formatos erróneos)
            onTap: () => _abrirPicker(context),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: '--:--',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              suffixIcon: value.text.isEmpty
                  ? const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF6C63FF))
                  : GestureDetector(
                      onTap: () {
                        controller.clear();
                        onChanged?.call();
                      },
                      child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade400),
                    ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Dropdown de resultado: OK / No Conforme ───────────────────────────────────
class CampoResultado extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const CampoResultado({super.key, required this.controller, this.onChanged});

  static const _opciones = ['OK', 'No Conforme'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resultado',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 4),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            // Si el texto guardado no es una opción conocida (dato viejo), mostramos hint
            final actual = _opciones.contains(value.text) ? value.text : null;
            return DropdownButtonFormField<String>(
              value: actual,
              isDense: true,
              isExpanded: true,
              hint: Text('Seleccionar',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2)),
              ),
              items: _opciones.map((o) {
                final esOk = o == 'OK';
                return DropdownMenuItem(
                  value: o,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        esOk ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        size: 14,
                        color: esOk ? Colors.green.shade600 : Colors.red.shade400,
                      ),
                      const SizedBox(width: 6),
                      Flexible(child: Text(o, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) {
                controller.text = v ?? '';
                onChanged?.call(v ?? '');
              },
            );
          },
        ),
      ],
    );
  }
}
