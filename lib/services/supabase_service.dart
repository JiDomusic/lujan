import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _initialized = true;
    } catch (_) {}
  }

  static Future<SupabaseClient> _getClientOrThrow() async {
    await init();
    if (!_initialized) {
      throw StateError('SupabaseService.init() must be called before using Supabase');
    }
    return Supabase.instance.client;
  }

  static SupabaseClient? get _clientOrNull {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (e) {
      return null;
    }
  }

  // ==================== AUTH ====================

  static Future<void> signIn(String email, String password) async {
    final client = await _getClientOrThrow();
    await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    final client = await _getClientOrThrow();
    await client.auth.signOut();
  }

  static User? get currentUser => _clientOrNull?.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;

  // ==================== GALLERY ====================

  static Future<List<Map<String, dynamic>>> getGalleryImages() async {
    try {
      final client = await _getClientOrThrow();
      final response = await client
          .from('gallery_images')
          .select()
          .order('display_order', ascending: true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  static Future<void> addGalleryImage({
    required String imageUrl,
    required String title,
    required String technique,
    required String size,
    String year = '',
    int rotation = 0,
    int displayOrder = 0,
  }) async {
    final client = await _getClientOrThrow();
    await client.from('gallery_images').insert({
      'image_url': imageUrl,
      'title': title,
      'technique': technique,
      'size': size,
      'year': year,
      'rotation': rotation,
      'display_order': displayOrder,
    });
  }

  static Future<void> updateGalleryImage({
    required String id,
    String? title,
    String? technique,
    String? size,
    String? year,
    int? rotation,
    int? displayOrder,
  }) async {
    final client = await _getClientOrThrow();
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (technique != null) updates['technique'] = technique;
    if (size != null) updates['size'] = size;
    if (year != null) updates['year'] = year;
    if (rotation != null) updates['rotation'] = rotation;
    if (displayOrder != null) updates['display_order'] = displayOrder;

    if (updates.isNotEmpty) {
      await client.from('gallery_images').update(updates).eq('id', id);
    }
  }

  static Future<void> deleteGalleryImage(String id, String imageUrl) async {
    final client = await _getClientOrThrow();
    // Eliminar de la base de datos
    await client.from('gallery_images').delete().eq('id', id);

    // Eliminar del storage si es una URL del bucket
    if (imageUrl.contains(SupabaseConfig.bucketName)) {
      try {
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf(SupabaseConfig.bucketName);
        if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
          final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
          await client.storage.from(SupabaseConfig.bucketName).remove([filePath]);
        }
      } catch (e) {
        // Ignorar errores de storage
      }
    }
  }

  // ==================== STORAGE ====================

  static Future<String> uploadImage(Uint8List bytes, String fileName) async {
    final client = await _getClientOrThrow();
    final String path = 'gallery/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await client.storage.from(SupabaseConfig.bucketName).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final String publicUrl =
        client.storage.from(SupabaseConfig.bucketName).getPublicUrl(path);

    return publicUrl;
  }

  // ==================== BIO ====================

  static Future<Map<String, dynamic>?> getBioContent() async {
    try {
      final client = await _getClientOrThrow();
      final response = await client.from('bio_content').select().limit(1).single();
      return response;
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateBioContent({
    required String id,
    required String contentEs,
    required String contentEn,
  }) async {
    final client = await _getClientOrThrow();
    await client.from('bio_content').update({
      'content_es': contentEs,
      'content_en': contentEn,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ==================== CURRENT WORKS ====================

  static Future<List<Map<String, dynamic>>> getCurrentWorks() async {
    try {
      final client = await _getClientOrThrow();
      final response = await client
          .from('current_works')
          .select()
          .order('display_order', ascending: true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  static Future<void> addCurrentWork({
    required String title,
    required String description,
    required String mediaType,
    required String mediaUrl,
    int displayOrder = 0,
  }) async {
    final client = await _getClientOrThrow();
    await client.from('current_works').insert({
      'title': title,
      'description': description,
      'media_type': mediaType,
      'media_url': mediaUrl,
      'display_order': displayOrder,
    });
  }

  static Future<void> updateCurrentWork({
    required String id,
    String? title,
    String? description,
    String? mediaUrl,
    int? displayOrder,
  }) async {
    final client = await _getClientOrThrow();
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (mediaUrl != null) updates['media_url'] = mediaUrl;
    if (displayOrder != null) updates['display_order'] = displayOrder;

    if (updates.isNotEmpty) {
      await client.from('current_works').update(updates).eq('id', id);
    }
  }

  static Future<void> deleteCurrentWork(String id, String mediaUrl, String mediaType) async {
    final client = await _getClientOrThrow();
    // Eliminar de la base de datos
    await client.from('current_works').delete().eq('id', id);

    // Eliminar del storage si es un video propio
    if (mediaType == 'video' && mediaUrl.contains(SupabaseConfig.bucketName)) {
      try {
        final uri = Uri.parse(mediaUrl);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf(SupabaseConfig.bucketName);
        if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
          final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
          await client.storage.from(SupabaseConfig.bucketName).remove([filePath]);
        }
      } catch (e) {
        // Ignorar errores de storage
      }
    }
  }

  static Future<String> uploadVideo(Uint8List bytes, String fileName) async {
    final client = await _getClientOrThrow();
    final String path = 'videos/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await client.storage.from(SupabaseConfig.bucketName).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final String publicUrl =
        client.storage.from(SupabaseConfig.bucketName).getPublicUrl(path);

    return publicUrl;
  }
}
