import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/supabase_service.dart';
import 'screens/admin_login_screen.dart';

enum AppLanguage { es, en }

class LanguageController extends ChangeNotifier {
  AppLanguage language = AppLanguage.es;

  void toggle() {
    language = language == AppLanguage.es ? AppLanguage.en : AppLanguage.es;
    notifyListeners();
  }

  void setLanguage(AppLanguage value) {
    if (language == value) return;
    language = value;
    notifyListeners();
  }
}

class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    super.key,
    required LanguageController notifier,
    required super.child,
  }) : super(notifier: notifier);

  static LanguageController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    assert(scope != null, 'LanguageScope not found in context');
    return scope!.notifier!;
  }

  static AppLanguage languageOf(BuildContext context) => of(context).language;
}

String tr(BuildContext context, {required String es, required String en}) {
  return LanguageScope.languageOf(context) == AppLanguage.es ? es : en;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SupabaseService.init();
  runApp(const LujanPortfolioApp());
}

class LujanPortfolioApp extends StatefulWidget {
  const LujanPortfolioApp({super.key});

  @override
  State<LujanPortfolioApp> createState() => _LujanPortfolioAppState();
}

class _LujanPortfolioAppState extends State<LujanPortfolioApp> {
  final LanguageController _languageController = LanguageController();

  @override
  void dispose() {
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      notifier: _languageController,
      child: MaterialApp(
        title: 'Lujan Allemand Portfolio',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
        ),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _hoveredZone;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      body: Stack(
        children: [
          // Background - color that matches the painting
          Positioned.fill(
            child: Container(color: const Color(0xFFAB9090)),
          ),
          // Background image - rotated -90 degrees, full image visible
          Positioned.fill(
            child: RotatedBox(
              quarterTurns: -1,
              child: Image.asset(
                'assets/home_bg.jpeg',
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Title overlay
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lujan Allemand',
                    style: GoogleFonts.roboto(
                      fontSize: isDesktop ? 72 : 36,
                      fontWeight: FontWeight.w100,
                      color: Colors.white,
                      letterSpacing: 8,
                      shadows: [
                        Shadow(
                          offset: const Offset(2, 2),
                          blurRadius: 8,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'portfolio',
                    style: GoogleFonts.roboto(
                      fontSize: isDesktop ? 24 : 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 12,
                      shadows: [
                        Shadow(
                          offset: const Offset(1, 1),
                          blurRadius: 4,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Interactive zones - subtle hover areas
          // Bio zone (blue jacket area - upper right where the boy is)
          _InteractiveZone(
            left: size.width * 0.55,
            top: size.height * 0.15,
            width: size.width * 0.35,
            height: size.height * 0.45,
            label: tr(context, es: 'bio', en: 'bio'),
            isHovered: _hoveredZone == 'bio',
            onHover: (isHovering) => setState(() => _hoveredZone = isHovering ? 'bio' : null),
            onTap: () => _handleZoneTap('bio', const BioScreen()),
            hoverColor: Colors.blue.withValues(alpha: 0.12),
            isDesktop: isDesktop,
          ),
          // Gallery zone (chicken area - left/center where chickens are)
          _InteractiveZone(
            left: size.width * 0.02,
            top: size.height * 0.25,
            width: size.width * 0.45,
            height: size.height * 0.55,
            label: tr(context, es: 'galeria', en: 'gallery'),
            isHovered: _hoveredZone == 'galeria',
            onHover: (isHovering) => setState(() => _hoveredZone = isHovering ? 'galeria' : null),
            onTap: () => _handleZoneTap('galeria', const GalleryScreen()),
            hoverColor: Colors.orange.withValues(alpha: 0.12),
            isDesktop: isDesktop,
          ),
          // Contact zone (blue sky area - top right corner)
          _InteractiveZone(
            left: size.width * 0.7,
            top: 0,
            width: size.width * 0.3,
            height: size.height * 0.25,
            label: tr(context, es: 'contacto', en: 'contact'),
            isHovered: _hoveredZone == 'contacto',
            onHover: (isHovering) => setState(() => _hoveredZone = isHovering ? 'contacto' : null),
            onTap: () => _handleZoneTap('contacto', const ContactScreen()),
            hoverColor: Colors.cyan.withValues(alpha: 0.12),
            isDesktop: isDesktop,
          ),
          // Hint text at bottom
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _hoveredZone == null ? 0.4 : 0.0,
              child: Center(
                child: Text(
                  isDesktop
                      ? tr(context, es: 'explora la imagen', en: 'explore the image')
                      : tr(context, es: 'toca para explorar', en: 'tap to explore'),
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: Colors.black,
                    letterSpacing: 8,
                  ),
                ),
              ),
            ),
          ),
          _LanguageToggleButton(isDesktop: isDesktop, alignRight: false),
          // Botón Admin
          Positioned(
            bottom: 16,
            right: 16,
            child: SafeArea(
              child: _AdminButton(isDesktop: isDesktop),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    )
        .then((_) {
      if (mounted) {
        setState(() => _hoveredZone = null);
      }
    });
  }

  void _handleZoneTap(String zone, Widget screen) {
    setState(() => _hoveredZone = zone);
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) {
        _navigateTo(context, screen);
      }
    });
  }
}

class _InteractiveZone extends StatelessWidget {
  const _InteractiveZone({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.label,
    required this.isHovered,
    required this.onHover,
    required this.onTap,
    required this.hoverColor,
    required this.isDesktop,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final String label;
  final bool isHovered;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;
  final Color hoverColor;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => onHover(true),
          onTapCancel: () => onHover(false),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isHovered ? hoverColor : Colors.transparent,
            ),
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isHovered ? 1 : 0,
                curve: Curves.easeOut,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 260),
                scale: isHovered ? 1.06 : 0.9,
                curve: Curves.easeOut,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.roboto(
                      fontSize: isDesktop ? 28 : 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      letterSpacing: isDesktop ? 8 : 4,
                      shadows: [
                        Shadow(
                          offset: const Offset(1, 1),
                          blurRadius: 6,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _LanguageToggleButton extends StatelessWidget {
  const _LanguageToggleButton({
    required this.isDesktop,
    this.alignRight = true,
  });

  final bool isDesktop;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final controller = LanguageScope.of(context);
    final isSpanish = controller.language == AppLanguage.es;

    Widget chip(String label, bool active, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 12 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: active ? Colors.black.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? Colors.black : Colors.black.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: isDesktop ? 12 : 11,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : Colors.black87,
              letterSpacing: 0.8,
            ),
          ),
        ),
      );
    }

    return Positioned(
      top: 16,
      right: alignRight ? 16 : null,
      left: alignRight ? null : 16,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          elevation: isDesktop ? 12 : 8,
          shadowColor: Colors.black.withValues(alpha: 0.14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                chip('ES', isSpanish, () => controller.setLanguage(AppLanguage.es)),
                const SizedBox(width: 6),
                chip('EN', !isSpanish, () => controller.setLanguage(AppLanguage.en)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Bio Screen - Museum minimalist style
class BioScreen extends StatefulWidget {
  const BioScreen({super.key});

  @override
  State<BioScreen> createState() => _BioScreenState();
}

class _BioScreenState extends State<BioScreen> {
  String? _bioEs;
  String? _bioEn;

  // Fallback hardcodeado
  static const _defaultBioEs =
      'Lujan Allemand nacio en 1983, en Lincoln, Buenos Aires, Argentina. '
      'En 2003 se traslado a la ciudad de Rosario, Santa Fe, donde reside actualmente. '
      'En 2004 estudio Fotografia en el Iset N 18. '
      'Desde 2018 concurre al taller Un triangulo y una calavera, a traves del cual participo en muestras colectivas: '
      'Mithila Power, biblioteca La Potencia, 2018; Piedra, Hoja, Rama, Fruto, Caracol, libreria Mal de Archivo, 2019; '
      'Banda de Banderas, parque de Las Colectividades, 2019; Artilleria Grafica, Museo Marc, 2020; '
      'Friki Flash Tarot, Club 856, 2021; Pua y plumin, Alianza Francesa, 2024. '
      'Desde 2019 cursa la carrera Licenciatura en Bellas Artes, en la Universidad Nacional de Rosario. '
      'En 2025 fue becaria en la Universidad del Tolima, Colombia.';

  static const _defaultBioEn =
      'Lujan Allemand was born in 1983 in Lincoln, Buenos Aires, Argentina. '
      'In 2003 she moved to Rosario, Santa Fe, where she currently lives. '
      'In 2004 she studied Photography at Iset N 18. '
      'Since 2018 she has attended the workshop Un triangulo y una calavera, through which she took part in group shows: '
      'Mithila Power, biblioteca La Potencia, 2018; Piedra, Hoja, Rama, Fruto, Caracol, libreria Mal de Archivo, 2019; '
      'Banda de Banderas, parque de Las Colectividades, 2019; Artilleria Grafica, Museo Marc, 2020; '
      'Friki Flash Tarot, Club 856, 2021; Pua y plumin, Alianza Francesa, 2024. '
      'Since 2019 she has been studying for a Bachelor of Fine Arts at the Universidad Nacional de Rosario. '
      'In 2025 she was awarded a scholarship at Universidad del Tolima, Colombia.';

  @override
  void initState() {
    super.initState();
    _loadBio();
  }

  Future<void> _loadBio() async {
    try {
      final bio = await SupabaseService.getBioContent();
      if (bio != null && mounted) {
        setState(() {
          _bioEs = bio['content_es'];
          _bioEn = bio['content_en'];
        });
      }
    } catch (e) {
      // Usar fallback hardcodeado
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? size.width * 0.2 : 32,
                vertical: 64,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lujan Allemand',
                    style: GoogleFonts.roboto(
                      fontSize: isDesktop ? 48 : 28,
                      fontWeight: FontWeight.w100,
                      color: Colors.black87,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    tr(
                      context,
                      es: _bioEs ?? _defaultBioEs,
                      en: _bioEn ?? _defaultBioEn,
                    ),
                    style: GoogleFonts.roboto(
                      fontSize: isDesktop ? 18 : 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.black54,
                      height: 1.8,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Back button - subtle
          _BackButton(isDesktop: isDesktop),
          _LanguageToggleButton(isDesktop: isDesktop),
        ],
      ),
    );
  }
}

// Gallery Screen - Contemporary art museum style
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isVerticalView = true;
  List<Map<String, dynamic>> _supabaseItems = [];

  // Datos de las obras de assets: imagen, título, medidas, rotación
  final List<Map<String, dynamic>> _assetGalleryItems = [
    {
      'image': 'assets/gallery_1.jpeg',
      'title': 'Sin titulo',
      'size': '30 x 40 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '2024',
      'rotation': -1,
    },
    {
      'image': 'assets/gallery_2.jpeg',
      'title': 'Sin titulo',
      'size': '30 x 40 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '2024',
      'rotation': -1,
    },
    {
      'image': 'assets/gallery_3.jpeg',
      'title': 'Sin titulo',
      'size': '30 x 40 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '2024',
      'rotation': -1,
    },
    {
      'image': 'assets/gallery_4.jpeg',
      'title': 'Sin titulo',
      'size': '30 x 40 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '2024',
      'rotation': -1,
    },
    {
      'image': 'assets/6- 21x29 cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '21 x 29 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/7- 29 x 44 cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '29 x 44 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/8 - 29x 44 cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '29 x 44 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/9 - 29 x44 cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '29 x 44 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/10 -21x29 cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '21 x 29 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/11 -29 x 44cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '29 x 44 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/12- 21x29 cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '21 x 29 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/13 - 21x29 cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '21 x 29 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/14 - 20x30 cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '20 x 30 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/15 - 21x21 cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '21 x 21 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/16 - 29 x 44  cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '29 x 44 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/17- 29x44 cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '29 x 44 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/18 - 29x44 cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '29 x 44 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/19 - 29x44 cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '29 x 44 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/20 - 29x44 cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '29 x 44 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/21 - 29x44 cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '29 x 44 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
    {
      'image': 'assets/22- 29x44 cm oleo sobre lienzo.jpg',
      'title': 'Sin titulo',
      'size': '29 x 44 cm',
      'technique': 'Oleo sobre lienzo',
      'year': '',
      'rotation': 0,
    },
  ];

  // Combinar assets + supabase
  List<Map<String, dynamic>> get _galleryItems => [
        ..._assetGalleryItems,
        ..._supabaseItems,
      ];

  @override
  void initState() {
    super.initState();
    _loadSupabaseImages();
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheGalleryImages(context));
  }

  Future<void> _loadSupabaseImages() async {
    try {
      final images = await SupabaseService.getGalleryImages();
      if (mounted) {
        setState(() {
          _supabaseItems = images.map((img) => {
                'image': img['image_url'],
                'title': img['title'] ?? 'Sin titulo',
                'size': img['size'] ?? '',
                'technique': img['technique'] ?? 'Oleo sobre lienzo',
                'year': img['year'] ?? '',
                'rotation': img['rotation'] ?? 0,
                'isNetwork': true,
              }).toList();
        });
      }
    } catch (e) {
      // Silently fail - show only asset images
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _translateTitle(BuildContext context, String title) {
    if (title.toLowerCase() == 'sin titulo') {
      return tr(context, es: 'Sin titulo', en: 'Untitled');
    }
    return title;
  }

  String _translateTechnique(BuildContext context, String technique) {
    if (technique.toLowerCase() == 'oleo sobre lienzo') {
      return tr(context, es: 'Oleo sobre lienzo', en: 'Oil on canvas');
    }
    return technique;
  }

  Widget _buildFramedImage(
    BuildContext context,
    Map<String, dynamic> item, {
    double maxWidthFactor = 0.96,
    double maxHeightFactor = 0.75,
    List<BoxShadow>? shadows,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth * maxWidthFactor;
        final maxHeight = constraints.maxHeight * maxHeightFactor;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: shadows ??
                    [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 32,
                        spreadRadius: 0,
                        offset: const Offset(0, 16),
                      ),
                    ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: RotatedBox(
                    quarterTurns: (item['rotation'] ?? 0) as int,
                    child: item['isNetwork'] == true
                        ? Image.network(
                            item['image']!,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            ),
                          )
                        : Image.asset(
                            item['image']!,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final isMobileVertical = !isDesktop && _isVerticalView;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Stack(
        children: [
          // Gallery images - fullscreen, museum style
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _galleryItems.length,
            itemBuilder: (context, index) {
              final item = _galleryItems[index];
              final title = _translateTitle(context, item['title']!);
              final technique = _translateTechnique(context, item['technique']!);

              // Desktop: obra casi full screen con caption flotante
              if (isDesktop) {
                return SafeArea(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Center(
                          child: _buildFramedImage(
                            context,
                            item,
                            maxWidthFactor: 0.96,
                            maxHeightFactor: 0.96,
                            shadows: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 50,
                                spreadRadius: 0,
                                offset: const Offset(0, 24),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 32,
                        right: 32,
                        bottom: 36,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      title,
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF1a1a1a),
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item['year']!.isNotEmpty
                                          ? '$technique · ${item['size']} · ${item['year']}'
                                          : '$technique · ${item['size']}',
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w300,
                                        color: const Color(0xF0252121),
                                        letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Mobile vertical: columna
              if (isMobileVertical) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: _buildFramedImage(
                              context,
                              item,
                              maxWidthFactor: 0.98,
                              maxHeightFactor: 0.72,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 16,
                                spreadRadius: 0,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF1a1a1a),
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['year']!.isNotEmpty
                                    ? '$technique · ${item['size']} · ${item['year']}'
                                    : '$technique · ${item['size']}',
                                style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w300,
                                  color: const Color(0xFF888888),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                );
              }

              // Mobile horizontal: fila con texto al costado
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: _buildFramedImage(
                            context,
                            item,
                            maxWidthFactor: 0.9,
                            maxHeightFactor: 0.82,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 16,
                                spreadRadius: 0,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF1a1a1a),
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['year']!.isNotEmpty
                                    ? '$technique · ${item['size']} · ${item['year']}'
                                    : '$technique · ${item['size']}',
                                style: GoogleFonts.roboto(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w300,
                                  color: const Color(0xFF888888),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Page indicator - minimal line style
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _galleryItems.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: _currentPage == index ? 32 : 12,
                  height: 2,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.black45
                        : Colors.black12,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),
          // Navigation arrows - subtle, only on desktop
          if (isDesktop) ...[
            _GalleryArrow(
              isLeft: true,
              isEnabled: _currentPage > 0,
              onTap: () {
                if (_currentPage > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
            _GalleryArrow(
              isLeft: false,
              isEnabled: _currentPage < _galleryItems.length - 1,
              onTap: () {
                if (_currentPage < _galleryItems.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ],
          if (!isDesktop)
            Positioned(
              top: 32,
              right: 32,
              child: _OrientationToggle(
                isVertical: _isVerticalView,
                onToggle: () => setState(() => _isVerticalView = !_isVerticalView),
              ),
            ),
          // Back button
          _BackButton(isDesktop: isDesktop),
          _LanguageToggleButton(isDesktop: isDesktop),
        ],
      ),
    );
  }

  void _precacheGalleryImages(BuildContext context) {
    // Precargar imagen actual y las siguientes 2 primero (prioridad alta)
    for (int i = 0; i < _galleryItems.length && i < 3; i++) {
      final asset = AssetImage(_galleryItems[i]['image']!);
      precacheImage(asset, context);
    }
    // Luego precargar el resto en background
    Future.delayed(const Duration(milliseconds: 100), () {
      for (int i = 3; i < _galleryItems.length; i++) {
        final asset = AssetImage(_galleryItems[i]['image']!);
        precacheImage(asset, context);
      }
    });
  }

  void _precacheNearbyImages(BuildContext context, int currentIndex) {
    // Precargar las imágenes cercanas cuando cambia la página
    final indicesToPreload = [
      currentIndex - 1,
      currentIndex + 1,
      currentIndex + 2,
    ].where((i) => i >= 0 && i < _galleryItems.length);

    for (final i in indicesToPreload) {
      final asset = AssetImage(_galleryItems[i]['image']!);
      precacheImage(asset, context);
    }
  }
}

class _GalleryArrow extends StatefulWidget {
  const _GalleryArrow({
    required this.isLeft,
    required this.isEnabled,
    required this.onTap,
  });

  final bool isLeft;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  State<_GalleryArrow> createState() => _GalleryArrowState();
}

class _GalleryArrowState extends State<_GalleryArrow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.isLeft ? 24 : null,
      right: widget.isLeft ? null : 24,
      top: 0,
      bottom: 0,
      child: Center(
        child: MouseRegion(
          cursor: widget.isEnabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isHovered && widget.isEnabled
                    ? Colors.black.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                widget.isLeft ? Icons.chevron_left : Icons.chevron_right,
                color: widget.isEnabled
                    ? (_isHovered ? Colors.black54 : Colors.black26)
                    : Colors.black12,
                size: 36,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrientationToggle extends StatelessWidget {
  const _OrientationToggle({
    required this.isVertical,
    required this.onToggle,
  });

  final bool isVertical;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(12),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVertical ? Icons.stay_current_portrait : Icons.stay_current_landscape,
                size: 18,
                color: const Color(0xFF333333),
              ),
              const SizedBox(width: 8),
              Text(
                isVertical
                    ? tr(context, es: 'vertical', en: 'vertical')
                    : tr(context, es: 'horizontal', en: 'horizontal'),
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Contact Screen - Minimalist with painting colors
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF1E3845),
      body: Stack(
        children: [
          // Full background color
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1E3845),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? size.width * 0.2 : 22,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    tr(context, es: 'contacto', en: 'contact'),
                    style: GoogleFonts.roboto(
                      fontSize: isDesktop ? 20 : 10,
                      fontWeight: FontWeight.w100,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Lujan Allemand',
                    style: GoogleFonts.roboto(
                      fontSize: isDesktop ? 22 : 18,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rosario, Santa Fe, Argentina',
                    style: GoogleFonts.roboto(
                      fontSize: isDesktop ? 14 : 12,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    width: 40,
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 48),
                  // Social buttons - Row on desktop, Column on mobile
                  if (isDesktop)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ContactButton(
                          icon: Icons.camera_alt_outlined,
                          label: '@lujanallemand',
                          onTap: () async {
                            final uri = Uri.parse('https://instagram.com/lujanallemand');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          isDesktop: isDesktop,
                        ),
                        const SizedBox(width: 32),
                        _ContactButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'WhatsApp',
                          onTap: () async {
                            final uri = Uri.parse('https://wa.me/5493415315939');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          isDesktop: isDesktop,
                          isWhatsApp: true,
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _ContactButton(
                          icon: Icons.camera_alt_outlined,
                          label: '@lujanallemand',
                          onTap: () async {
                            final uri = Uri.parse('https://instagram.com/lujanallemand');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          isDesktop: isDesktop,
                        ),
                        const SizedBox(height: 16),
                        _ContactButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'WhatsApp',
                          onTap: () async {
                            final uri = Uri.parse('https://wa.me/5493415315939');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          isDesktop: isDesktop,
                          isWhatsApp: true,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          // Back button (light version for dark background)
          _BackButtonLight(isDesktop: isDesktop),
          _LanguageToggleButton(isDesktop: isDesktop),
        ],
      ),
    );
  }
}

class _ContactButton extends StatefulWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDesktop,
    this.isWhatsApp = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDesktop;
  final bool isWhatsApp;

  @override
  State<_ContactButton> createState() => _ContactButtonState();
}

class _ContactButtonState extends State<_ContactButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const baseColor = Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isDesktop ? 24 : 16,
            vertical: widget.isDesktop ? 14 : 10,
          ),
          decoration: BoxDecoration(
            color: _isHovered
                ? baseColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: baseColor.withValues(alpha: _isHovered ? 0.5 : 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: widget.isDesktop ? 20 : 16,
                color: baseColor.withValues(alpha: 0.85),
              ),
              SizedBox(width: widget.isDesktop ? 10 : 8),
              Text(
                widget.label,
                style: GoogleFonts.roboto(
                  fontSize: widget.isDesktop ? 14 : 12,
                  fontWeight: FontWeight.w300,
                  color: baseColor.withValues(alpha: 0.85),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Light back button for dark backgrounds
class _BackButtonLight extends StatefulWidget {
  const _BackButtonLight({required this.isDesktop});

  final bool isDesktop;

  @override
  State<_BackButtonLight> createState() => _BackButtonLightState();
}

class _BackButtonLightState extends State<_BackButtonLight> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      child: SafeArea(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _isHovered
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back,
                    color: _isHovered
                        ? Colors.white.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.85),
                    size: widget.isDesktop ? 20 : 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tr(context, es: 'INICIO', en: 'HOME'),
                    style: GoogleFonts.roboto(
                      fontSize: widget.isDesktop ? 13 : 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable back button
class _BackButton extends StatefulWidget {
  const _BackButton({required this.isDesktop});

  final bool isDesktop;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      child: SafeArea(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _isHovered
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back,
                    color: Colors.black.withValues(alpha: 0.6),
                    size: widget.isDesktop ? 20 : 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tr(context, es: 'INICIO', en: 'HOME'),
                    style: GoogleFonts.roboto(
                      fontSize: widget.isDesktop ? 13 : 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.75),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Botón Admin para acceder al panel
class _AdminButton extends StatefulWidget {
  const _AdminButton({required this.isDesktop});

  final bool isDesktop;

  @override
  State<_AdminButton> createState() => _AdminButtonState();
}

class _AdminButtonState extends State<_AdminButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
          );
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isHovered ? 0.7 : 0.25,
          child: Icon(
            Icons.settings_outlined,
            color: Colors.white,
            size: widget.isDesktop ? 22 : 20,
          ),
        ),
      ),
    );
  }
}
