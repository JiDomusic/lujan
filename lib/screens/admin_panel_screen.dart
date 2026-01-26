import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GalleryTab(),
          _BioTab(),
        ],
      ),
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
  final _esController = TextEditingController();
  final _enController = TextEditingController();
  String? _bioId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBio();
  }

  @override
  void dispose() {
    _esController.dispose();
    _enController.dispose();
    super.dispose();
  }

  Future<void> _loadBio() async {
    setState(() => _isLoading = true);
    try {
      final bio = await SupabaseService.getBioContent();
      if (bio != null) {
        _bioId = bio['id'];
        _esController.text = bio['content_es'] ?? '';
        _enController.text = bio['content_en'] ?? '';
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
        contentEs: _esController.text,
        contentEn: _enController.text,
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
                TextField(
                  controller: _esController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Escribe la biografía en español...',
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    height: 1.6,
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
                TextField(
                  controller: _enController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Write the biography in English...',
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    height: 1.6,
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
