import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseClient? get _clientOrNull {
    try {
      return Supabase.instance.client;
    } catch (e) {
      return null;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  // ==================== AUTH ====================

  static Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static User? get currentUser => client.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;

  // ==================== GALLERY ====================

  static Future<List<Map<String, dynamic>>> getGalleryImages() async {
    if (_clientOrNull == null) return [];
    try {
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
    if (_clientOrNull == null) return null;
    try {
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
    await client.from('bio_content').update({
      'content_es': contentEs,
      'content_en': contentEn,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
