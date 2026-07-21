// lib/screens/profile_screen.dart
// Pantalla de perfil: ver y editar nombre, bio y foto

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;       // Cargando datos iniciales
  bool _isSaving = false;        // Guardando cambios
  bool _isUploadingPhoto = false; // Subiendo foto
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile(); // Cargar perfil al abrir la pantalla
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Carga el perfil desde Firestore
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    final profile = await ProfileService.getProfile(uid);

    if (profile != null && mounted) {
      setState(() {
        _profile = profile;
        _nameController.text = profile.name;
        _bioController.text = profile.bio;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // Guardar nombre y bio en Firestore
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    final error = await ProfileService.updateProfile(
      uid: uid,
      name: _nameController.text,
      bio: _bioController.text,
    );

    setState(() => _isSaving = false);

    if (!mounted) return;

    if (error != null) {
      _showSnackBar(error, isError: true);
    } else {
      _showSnackBar('¡Perfil actualizado correctamente!');
      // Actualizar el estado local también
      setState(() {
        _profile = _profile?.copyWith(
          name: _nameController.text,
          bio: _bioController.text,
        );
      });
    }
  }

  // Seleccionar y subir foto de perfil
  Future<void> _pickAndUploadPhoto() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    // Mostrar opciones: cámara o galería
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,      // Limitar tamaño para no desperdiciar Storage
      maxHeight: 800,
      imageQuality: 85,   // Comprimir un poco la imagen
    );

    if (picked == null) return;

    // readAsBytes() funciona en Web y móvil
    final bytes = await picked.readAsBytes();

    setState(() => _isUploadingPhoto = true);

    final error = await ProfileService.uploadProfilePhoto(
      uid: uid,
      bytes: bytes,
    );

    setState(() => _isUploadingPhoto = false);

    if (!mounted) return;

    if (error != null) {
      _showSnackBar(error, isError: true);
    } else {
      _showSnackBar('¡Foto actualizada!');
      _loadProfile(); // Recargar para mostrar nueva foto
    }
  }

  // Diálogo para elegir fuente de imagen
  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Seleccionar foto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF60A66B)),
              title: const Text('Galería de fotos'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF60A66B)),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Mi perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF60A66B)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ── Foto de perfil ────────────────────────────────────
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        // Avatar circular
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF60A66B).withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: _buildAvatar(),
                          ),
                        ),

                        // Botón para cambiar foto
                        GestureDetector(
                          onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF60A66B),
                              shape: BoxShape.circle,
                            ),
                            child: _isUploadingPhoto
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Email (solo lectura, no se puede editar)
                    Text(
                      _profile?.email ?? AuthService.currentUser?.email ?? '',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),

                    const SizedBox(height: 32),

                    // ── Campos editables ──────────────────────────────────
                    CustomTextField(
                      label: 'Nombre completo',
                      hint: 'Tu nombre',
                      prefixIcon: Icons.person_outline_rounded,
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre no puede estar vacío';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Bio es un campo multilínea
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Biografía',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 4,
                          maxLength: 200,
                          decoration: InputDecoration(
                            hintText: 'Cuéntanos algo sobre ti...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
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
                              borderSide: const BorderSide(
                                color: Color(0xFF60A66B),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Botón guardar
                    PrimaryButton(
                      text: 'Guardar cambios',
                      onPressed: _saveProfile,
                      isLoading: _isSaving,
                    ),

                    const SizedBox(height: 16),

                    // Info sobre cuándo se creó la cuenta
                    if (_profile != null)
                      Text(
                        'Cuenta creada el ${_formatDate(_profile!.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  // Construir el avatar según si tiene foto o no
  Widget _buildAvatar() {
    final photoUrl = _profile?.photoUrl;

    if (photoUrl != null && photoUrl.isNotEmpty) {
      // Imagen desde Firebase Storage con caché
      return CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: const Color(0xFF60A66B).withOpacity(0.1),
          child: const Icon(Icons.person_rounded, color: Color(0xFF60A66B), size: 50),
        ),
        errorWidget: (context, url, error) => _defaultAvatar(),
      );
    }

    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Container(
      color: const Color(0xFF60A66B).withOpacity(0.1),
      child: const Icon(Icons.person_rounded, color: Color(0xFF60A66B), size: 50),
    );
  }

  String _formatDate(DateTime date) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${date.day} de ${meses[date.month - 1]} de ${date.year}';
  }
}
