// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: StreamBuilder<UserProfile?>(
          stream: ProfileService.profileStream(uid),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final name = profile?.name ?? AuthService.currentUser?.displayName ?? 'Usuario';

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bienvenido', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                        ],
                      ),
                      IconButton(
                        onPressed: () async {
                          await AuthService.logout();
                          if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                        },
                        icon: const Icon(Icons.logout_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red.shade400,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Tarjeta de perfil
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          ClipOval(child: SizedBox(width: 48, height: 48, child: _buildAvatar(profile))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(profile?.email ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          Text('Editar perfil', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text('Módulos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  const SizedBox(height: 12),

                  // ── Módulo Hojas de Terreno ──────────────────────────────
                  _ModuleCard(
                    icon: Icons.description_rounded,
                    title: 'Hojas de Terreno',
                    subtitle: 'Crear, ver y editar hojas de inspección',
                    color: const Color(0xFF6C63FF),
                    onTap: () => Navigator.pushNamed(context, '/hojas'),
                  ),

                  const SizedBox(height: 10),

                  // ── Módulo Buscar ────────────────────────────────────────
                  _ModuleCard(
                    icon: Icons.manage_search_rounded,
                    title: 'Buscar Hojas',
                    subtitle: 'Buscar por código HDT, tanque o cliente',
                    color: const Color(0xFF00897B),
                    onTap: () => Navigator.pushNamed(context, '/buscar'),
                  ),

                  const SizedBox(height: 10),

                  _buildMenuItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Cambiar contraseña',
                    onTap: () => _sendPasswordReset(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatar(UserProfile? profile) {
    final photoUrl = profile?.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover, placeholder: (c, u) => _defaultAvatar(), errorWidget: (c, u, e) => _defaultAvatar());
    }
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Container(color: const Color(0xFF6C63FF).withOpacity(0.1), child: const Icon(Icons.person_rounded, color: Color(0xFF6C63FF), size: 24));
  }

  Widget _buildMenuItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF6C63FF), size: 18),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _sendPasswordReset(BuildContext context) async {
    final email = AuthService.currentUser?.email;
    if (email == null) return;
    await AuthService.resetPassword(email);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Correo enviado a $email'), backgroundColor: Colors.green.shade600, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      );
    }
  }
}

// ─── Tarjeta de módulo ─────────────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.7), size: 16),
          ],
        ),
      ),
    );
  }
}
