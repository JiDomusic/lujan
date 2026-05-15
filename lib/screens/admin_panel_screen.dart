import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../services/supabase_service.dart';

TextStyle _editorStyleForAttr(quill.Attribute attr) {
  if (attr.key == quill.Attribute.font.key) {
    final font = attr.value as String? ?? 'Roboto';
    switch (font) {
      case 'Playfair Display':
        return GoogleFonts.playfairDisplay(fontSize: 14, color: Colors.black87, height: 1.6);
      case 'Georgia':
        return const TextStyle(fontFamily: 'Georgia', fontSize: 14, color: Colors.black87, height: 1.6);
      case 'Courier New':
        return const TextStyle(fontFamily: 'Courier', fontSize: 14, color: Colors.black87, height: 1.6);
      case 'Roboto':
      default:
        return GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black87, height: 1.6);
    }
  }
  if (attr.key == quill.Attribute.bold.key) {
    return const TextStyle(fontWeight: FontWeight.bold);
  }
  if (attr.key == quill.Attribute.italic.key) {
    return const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF6A4EB3));
  }
  if (attr.key == quill.Attribute.underline.key) {
    return const TextStyle(decoration: TextDecoration.underline);
  }
  return GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black87, height: 1.6);
}

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await SupabaseService.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3845),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Panel de Administración',
          style: GoogleFonts.roboto(
            fontSize: isDesktop ? 18 : 16,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
            label: Text(
              'Salir',
              style: GoogleFonts.roboto(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 2,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          tabs: const [
            Tab(text: 'GALERÍA'),
            Tab(text: 'BIOGRAFÍA'),
            Tab(text: 'AHORA'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GalleryTab(),
          _BioTab(),
          _CurrentWorkTab(),
        ],
      ),
    );
  }
}

// ==================== CURRENT WORK TAB ====================

class _CurrentWorkTab extends StatefulWidget {
  const _CurrentWorkTab();

  @override
  State<_CurrentWorkTab> createState() => _CurrentWorkTabState();
}

class _CurrentWorkTabState extends State<_CurrentWorkTab> {
  List<Map<String, dynamic>> _works = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorks();
  }

  Future<void> _loadWorks() async {
    setState(() => _isLoading = true);
    try {
      final works = await SupabaseService.getCurrentWorks();
      setState(() {
        _works = works;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar: $e')),
        );
      }
    }
  }

  Future<void> _deleteWork(Map<String, dynamic> work) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar', style: GoogleFonts.roboto(fontWeight: FontWeight.w500)),
        content: const Text('¿Eliminar este trabajo en proceso?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await SupabaseService.deleteCurrentWork(
        work['id'],
        work['media_url'] ?? '',
        work['media_type'] ?? 'video',
      );
      await _loadWorks();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eliminado')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showWorkDialog({Map<String, dynamic>? work}) async {
    final isEdit = work != null;
    final titleController = TextEditingController(text: work?['title'] ?? '');
    final descController = TextEditingController(text: work?['description'] ?? '');
    final urlController = TextEditingController(text: work?['media_url'] ?? '');
    final orderController = TextEditingController(text: work?['display_order']?.toString() ?? '0');
    String mediaType = work?['media_type'] ?? 'youtube';
    bool isUploading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              isEdit ? 'Editar trabajo' : 'Nuevo trabajo',
              style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tipo
                  DropdownButtonFormField<String>(
                    value: mediaType,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                      DropdownMenuItem(value: 'video', child: Text('Video MP4')),
                    ],
                    onChanged: (v) => setDialogState(() => mediaType = v!),
                  ),
                  const SizedBox(height: 12),
                  // Título
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  const SizedBox(height: 12),
                  // Descripción
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  // URL o Video file
                  if (mediaType == 'youtube')
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        labelText: 'URL de YouTube',
                        hintText: 'https://youtube.com/watch?v=...',
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: isUploading
                          ? null
                          : () async {
                              setDialogState(() => isUploading = true);
                              try {
                                final picker = ImagePicker();
                                final video = await picker.pickVideo(
                                  source: ImageSource.gallery,
                                  maxDuration: const Duration(minutes: 10),
                                );
                                if (video != null) {
                                  final bytes = await video.readAsBytes();
                                  final url = await SupabaseService.uploadVideo(bytes, video.name);
                                  urlController.text = url;
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Video subido')),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error al subir: $e')),
                                  );
                                }
                              } finally {
                                setDialogState(() => isUploading = false);
                              }
                            },
                      icon: isUploading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.video_file),
                      label: Text(urlController.text.isEmpty ? 'Elegir video MP4' : 'Cambiar video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3845),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (urlController.text.isNotEmpty && mediaType == 'video')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Video cargado: ${urlController.text.split('/').last}',
                        style: GoogleFonts.roboto(fontSize: 11, color: Colors.green[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Orden
                  TextField(
                    controller: orderController,
                    decoration: const InputDecoration(labelText: 'Orden de visualización'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        final title = titleController.text.trim();
                        final desc = descController.text.trim();
                        final url = urlController.text.trim();
                        final order = int.tryParse(orderController.text) ?? 0;

                        if (url.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Falta la URL o el video')),
                          );
                          return;
                        }

                        Navigator.pop(context);

                        try {
                          if (isEdit) {
                            await SupabaseService.updateCurrentWork(
                              id: work!['id'],
                              title: title.isEmpty ? null : title,
                              description: desc.isEmpty ? null : desc,
                              mediaUrl: url,
                              displayOrder: order,
                            );
                          } else {
                            await SupabaseService.addCurrentWork(
                              title: title,
                              description: desc,
                              mediaType: mediaType,
                              mediaUrl: url,
                              displayOrder: order,
                            );
                          }
                          await _loadWorks();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(isEdit ? 'Actualizado' : 'Agregado')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3845),
                ),
                child: Text(isEdit ? 'Guardar' : 'Agregar', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${_works.length} trabajo(s) en proceso',
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.black54),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _showWorkDialog(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Agregar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3845),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _works.isEmpty
                  ? Center(
                      child: Text(
                        'No hay trabajos en proceso',
                        style: GoogleFonts.roboto(fontSize: 16, color: Colors.black45),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isDesktop ? 3 : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: _works.length,
                      itemBuilder: (context, index) {
                        final work = _works[index];
                        final isYouTube = work['media_type'] == 'youtube';
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header con tipo
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isYouTube ? Colors.red[50] : Colors.blue[50],
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isYouTube ? Icons.play_circle_outline : Icons.videocam,
                                      size: 16,
                                      color: isYouTube ? Colors.red[400] : Colors.blue[400],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isYouTube ? 'YouTube' : 'Video MP4',
                                      style: GoogleFonts.roboto(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isYouTube ? Colors.red[700] : Colors.blue[700],
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      color: Colors.black45,
                                      onPressed: () => _showWorkDialog(work: work),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      color: Colors.red[400],
                                      onPressed: () => _deleteWork(work),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                    ),
                                  ],
                                ),
                              ),
                              // Info
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      work['title'] ?? 'Sin título',
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (work['description']?.toString().isNotEmpty == true) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        work['description'],
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      work['media_url'] ?? '',
                                      style: GoogleFonts.roboto(fontSize: 10, color: Colors.black38),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ==================== GALERÍA TAB ====================

class _GalleryTab extends StatefulWidget {
  const _GalleryTab();

  @override
  State<_GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<_GalleryTab> {
  List<Map<String, dynamic>> _images = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _isLoading = true);
    try {
      final images = await SupabaseService.getGalleryImages();
      setState(() {
        _images = images;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar imágenes: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    // Mostrar diálogo para datos de la imagen
    if (!mounted) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ImageDataDialog(),
    );

    if (result == null) return;

    // Subir imagen
    setState(() => _isLoading = true);
    try {
      final bytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name;

      final imageUrl = await SupabaseService.uploadImage(bytes, fileName);

      await SupabaseService.addGalleryImage(
        imageUrl: imageUrl,
        title: result['title'] ?? 'Sin titulo',
        technique: result['technique'] ?? 'Oleo sobre lienzo',
        size: result['size'] ?? '',
        year: result['year'] ?? '',
        displayOrder: _images.length,
      );

      await _loadImages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Dale loko subi mas obra puta',
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.pink[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e')),
        );
      }
    }
  }

  Future<void> _editImage(Map<String, dynamic> image) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ImageDataDialog(
        initialTitle: image['title'],
        initialTechnique: image['technique'],
        initialSize: image['size'],
        initialYear: image['year'],
      ),
    );

    if (result == null) return;

    try {
      await SupabaseService.updateGalleryImage(
        id: image['id'],
        title: result['title'],
        technique: result['technique'],
        size: result['size'],
        year: result['year'],
      );
      await _loadImages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteImage(Map<String, dynamic> image) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar imagen',
          style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
        ),
        content: const Text('¿Estás segura de que quieres eliminar esta imagen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupabaseService.deleteGalleryImage(image['id'], image['image_url']);
      await _loadImages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen eliminada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Column(
      children: [
        // Header con botón de subir
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${_images.length} imagen(es) en Supabase',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _uploadImage,
                icon: const Icon(Icons.add_photo_alternate, size: 20),
                label: const Text('Subir imagen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3845),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Lista de imágenes
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _images.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: Colors.black26,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay imágenes en Supabase',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Las imágenes de assets seguirán mostrándose',
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isDesktop ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        final image = _images[index];
                        return _ImageCard(
                          image: image,
                          onEdit: () => _editImage(image),
                          onDelete: () => _deleteImage(image),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({
    required this.image,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> image;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                image['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  image['title'] ?? 'Sin titulo',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  image['size'] ?? '',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          side: const BorderSide(color: Colors.black26),
                        ),
                        child: Text(
                          'Editar',
                          style: GoogleFonts.roboto(fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red[400],
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageDataDialog extends StatefulWidget {
  const _ImageDataDialog({
    this.initialTitle,
    this.initialTechnique,
    this.initialSize,
    this.initialYear,
  });

  final String? initialTitle;
  final String? initialTechnique;
  final String? initialSize;
  final String? initialYear;

  @override
  State<_ImageDataDialog> createState() => _ImageDataDialogState();
}

class _ImageDataDialogState extends State<_ImageDataDialog> {
  late TextEditingController _titleController;
  late TextEditingController _techniqueController;
  late TextEditingController _sizeController;
  late TextEditingController _yearController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? 'Sin titulo');
    _techniqueController =
        TextEditingController(text: widget.initialTechnique ?? 'Oleo sobre lienzo');
    _sizeController = TextEditingController(text: widget.initialSize ?? '');
    _yearController = TextEditingController(text: widget.initialYear ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _techniqueController.dispose();
    _sizeController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialTitle != null ? 'Editar imagen' : 'Datos de la imagen',
        style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Sin titulo',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _techniqueController,
              decoration: const InputDecoration(
                labelText: 'Técnica',
                hintText: 'Oleo sobre lienzo',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sizeController,
              decoration: const InputDecoration(
                labelText: 'Tamaño',
                hintText: '29 x 44 cm',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Año',
                hintText: '2024',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'title': _titleController.text,
              'technique': _techniqueController.text,
              'size': _sizeController.text,
              'year': _yearController.text,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3845),
          ),
          child: const Text('Guardar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ==================== BIO TAB ====================

class _BioTab extends StatefulWidget {
  const _BioTab();

  @override
  State<_BioTab> createState() => _BioTabState();
}

class _BioTabState extends State<_BioTab> {
  late quill.QuillController _esController;
  late quill.QuillController _enController;
  final _esFocus = FocusNode();
  final _enFocus = FocusNode();
  final _esScroll = ScrollController();
  final _enScroll = ScrollController();
  String? _bioId;
  bool _isLoading = true;
  bool _isSaving = false;

  quill.Document _parseBio(String? raw) {
    if (raw == null || raw.isEmpty) {
      return quill.Document()..insert(0, '');
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return quill.Document.fromJson(decoded);
      }
    } catch (_) {
      // Ignorar
    }
    return quill.Document()..insert(0, raw);
  }

  String _encodeBio(quill.QuillController controller) {
    return jsonEncode(controller.document.toDelta().toJson());
  }

  quill.QuillController _emptyController() => quill.QuillController(
        document: quill.Document()..insert(0, ''),
        selection: const TextSelection.collapsed(offset: 0),
      );

  @override
  void initState() {
    super.initState();
    _esController = _emptyController();
    _enController = _emptyController();
    _loadBio();
  }

  @override
  void dispose() {
    _esController.dispose();
    _enController.dispose();
    _esFocus.dispose();
    _enFocus.dispose();
    _esScroll.dispose();
    _enScroll.dispose();
    super.dispose();
  }

  Future<void> _loadBio() async {
    setState(() => _isLoading = true);
    try {
      final bio = await SupabaseService.getBioContent();
      if (bio != null) {
        _bioId = bio['id'];
        setState(() {
          _esController = quill.QuillController(
            document: _parseBio(bio['content_es']),
            selection: const TextSelection.collapsed(offset: 0),
          );
          _enController = quill.QuillController(
            document: _parseBio(bio['content_en']),
            selection: const TextSelection.collapsed(offset: 0),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar bio: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBio() async {
    if (_bioId == null) return;

    setState(() => _isSaving = true);
    try {
      await SupabaseService.updateBioContent(
        id: _bioId!,
        contentEs: _encodeBio(_esController),
        contentEn: _encodeBio(_enController),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biografía guardada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Español
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3845),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ES',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Biografía en Español',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                quill.QuillProvider(
                  configurations: quill.QuillConfigurations(
                    controller: _esController,
                    sharedConfigurations: quill.QuillSharedConfigurations(
                      locale: Localizations.maybeLocaleOf(context),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.text_format, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(
                            'Formato rápido',
                            style: GoogleFonts.roboto(fontSize: 12, color: Colors.black54),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Column(
                          children: [
                            quill.QuillToolbar(
                              configurations: quill.QuillToolbarConfigurations(
                                showBoldButton: true,
                                showItalicButton: true,
                                showUnderLineButton: true,
                                showStrikeThrough: false,
                                showInlineCode: false,
                                showColorButton: true,
                                showBackgroundColorButton: false,
                                showClearFormat: true,
                                showAlignmentButtons: false,
                                showHeaderStyle: false,
                                showListNumbers: false,
                                showListBullets: false,
                                showListCheck: false,
                                showCodeBlock: false,
                                showQuote: false,
                                showIndent: false,
                                showLink: false,
                                showSearchButton: false,
                                showFontFamily: true,
                                showFontSize: true,
                                showUndo: false,
                                showRedo: false,
                                showDividers: true,
                                multiRowsDisplay: false,
                                fontFamilyValues: const {
                                  'Roboto': 'Roboto',
                                  'Playfair Display': 'Playfair Display',
                                  'Georgia': 'Georgia',
                                  'Courier New': 'Courier New',
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              child: quill.QuillEditor(
                                focusNode: _esFocus,
                                scrollController: _esScroll,
                                configurations: quill.QuillEditorConfigurations(
                                  readOnly: false,
                                  placeholder: 'Escribe la biografía en español...',
                                  padding: EdgeInsets.zero,
                                  customStyles: quill.DefaultStyles(
                                    paragraph: quill.DefaultTextBlockStyle(
                                      GoogleFonts.roboto(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                        height: 1.6,
                                        letterSpacing: 0.4,
                                      ),
                                      const quill.VerticalSpacing(0, 0),
                                      const quill.VerticalSpacing(0, 0),
                                      null,
                                    ),
                                  ),
                                  customStyleBuilder: _editorStyleForAttr,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Inglés
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3845),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'EN',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Biography in English',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                quill.QuillProvider(
                  configurations: quill.QuillConfigurations(
                    controller: _enController,
                    sharedConfigurations: quill.QuillSharedConfigurations(
                      locale: Localizations.maybeLocaleOf(context),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.text_format, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(
                            'Quick format',
                            style: GoogleFonts.roboto(fontSize: 12, color: Colors.black54),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Column(
                          children: [
                            quill.QuillToolbar(
                              configurations: quill.QuillToolbarConfigurations(
                                showBoldButton: true,
                                showItalicButton: true,
                                showUnderLineButton: true,
                                showStrikeThrough: false,
                                showInlineCode: false,
                                showColorButton: true,
                                showBackgroundColorButton: false,
                                showClearFormat: true,
                                showAlignmentButtons: false,
                                showHeaderStyle: false,
                                showListNumbers: false,
                                showListBullets: false,
                                showListCheck: false,
                                showCodeBlock: false,
                                showQuote: false,
                                showIndent: false,
                                showLink: false,
                                showSearchButton: false,
                                showFontFamily: true,
                                showFontSize: true,
                                showUndo: false,
                                showRedo: false,
                                showDividers: true,
                                multiRowsDisplay: false,
                                fontFamilyValues: const {
                                  'Roboto': 'Roboto',
                                  'Playfair Display': 'Playfair Display',
                                  'Georgia': 'Georgia',
                                  'Courier New': 'Courier New',
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              child: quill.QuillEditor(
                                focusNode: _enFocus,
                                scrollController: _enScroll,
                                configurations: quill.QuillEditorConfigurations(
                                  readOnly: false,
                                  placeholder: 'Write the biography in English...',
                                  padding: EdgeInsets.zero,
                                  customStyles: quill.DefaultStyles(
                                    paragraph: quill.DefaultTextBlockStyle(
                                      GoogleFonts.roboto(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                        height: 1.6,
                                        letterSpacing: 0.4,
                                      ),
                                      const quill.VerticalSpacing(0, 0),
                                      const quill.VerticalSpacing(0, 0),
                                      null,
                                    ),
                                  ),
                                  customStyleBuilder: _editorStyleForAttr,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botón guardar
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveBio,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3845),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Guardar cambios',
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
