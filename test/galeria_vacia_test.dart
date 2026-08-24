import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lujan/main.dart';

void main() {
  // Ahora que las obras salen solo de Supabase, la galeria puede quedarse sin
  // ninguna: si Lujan las borra todas desde el panel, o si Supabase no responde.
  // Antes eso dejaba un PageView de cero paginas.
  testWidgets('la galeria sin obras avisa en vez de quedar en blanco',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      LanguageScope(
        notifier: LanguageController(),
        child: const MaterialApp(home: GalleryScreen()),
      ),
    );

    // Primer frame: todavia esta consultando.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Sin Supabase disponible la consulta vuelve vacia.
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Muy pronto, obra nueva.'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });
}
