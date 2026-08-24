
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Deja las fotos livianas ANTES de subirlas al bucket.
///
/// Supabase solo transforma imagenes en los planes pagos, asi que la
/// optimizacion se hace aca: la obra entra al bucket ya optimizada y cada
/// visita a la galeria descarga mucho menos.
///
/// El criterio es no tocar la calidad que se ve: se recorta el exceso de
/// pixeles (una obra de 4000 px se muestra igual que una de 1800 en pantalla)
/// y se reencoda en JPEG alto. Si el archivo ya venia liviano y en medida,
/// se sube tal cual para no reencodear de gusto y perder nitidez al pedo.
class CompresorImagen {
  /// Lado mas largo que se conserva. 1800 px cubre pantallas 4K a pantalla
  /// completa; arriba de eso el visitante descarga pixeles que no ve.
  static const int ladoMaximo = 1800;

  /// Calidad JPEG. De 88 para arriba la diferencia con el original no se
  /// distingue a simple vista, y pesa una fraccion.
  static const int calidadJpeg = 88;

  /// Por debajo de esto no vale la pena reencodear.
  static const int pesoQueYaEstaBien = 400 * 1024;

  /// Devuelve los bytes optimizados y el nombre de archivo que corresponde.
  /// Si algo falla, devuelve el original: nunca frena una subida.
  static Future<({Uint8List bytes, String nombre})> optimizar(
    Uint8List original,
    String nombreOriginal,
  ) async {
    try {
      final resultado = await compute(
        _optimizarEnSegundoPlano,
        (bytes: original, nombre: nombreOriginal),
      );
      return resultado;
    } catch (_) {
      return (bytes: original, nombre: _sanear(nombreOriginal));
    }
  }

  static ({Uint8List bytes, String nombre}) _optimizarEnSegundoPlano(
    ({Uint8List bytes, String nombre}) entrada,
  ) {
    final nombreSaneado = _sanear(entrada.nombre);
    final imagen = img.decodeImage(entrada.bytes);

    // Formato que no se pudo leer: se sube tal cual.
    if (imagen == null) {
      return (bytes: entrada.bytes, nombre: nombreSaneado);
    }

    final ladoLargo =
        imagen.width > imagen.height ? imagen.width : imagen.height;

    // Ya viene chica y liviana: no la toco.
    if (ladoLargo <= ladoMaximo && entrada.bytes.length <= pesoQueYaEstaBien) {
      return (bytes: entrada.bytes, nombre: nombreSaneado);
    }

    final redimensionada = ladoLargo > ladoMaximo
        ? img.copyResize(
            imagen,
            width: imagen.width >= imagen.height ? ladoMaximo : null,
            height: imagen.height > imagen.width ? ladoMaximo : null,
            interpolation: img.Interpolation.cubic,
          )
        : imagen;

    final comprimida = img.encodeJpg(redimensionada, quality: calidadJpeg);

    // Si el "optimizado" pesa mas que el original, gana el original.
    if (comprimida.length >= entrada.bytes.length) {
      return (bytes: entrada.bytes, nombre: nombreSaneado);
    }

    return (
      bytes: Uint8List.fromList(comprimida),
      nombre: _conExtensionJpg(nombreSaneado),
    );
  }

  /// Los nombres del picker traen espacios, tildes y parentesis; en una URL
  /// publica eso es problema. Se deja solo lo que viaja tranquilo.
  static String _sanear(String nombre) {
    final limpio = nombre
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return limpio.isEmpty ? 'obra.jpg' : limpio;
  }

  static String _conExtensionJpg(String nombre) {
    final punto = nombre.lastIndexOf('.');
    final base = punto > 0 ? nombre.substring(0, punto) : nombre;
    return '$base.jpg';
  }
}
