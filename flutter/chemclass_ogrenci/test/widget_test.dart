import 'package:flutter_test/flutter_test.dart';
import 'package:chemclass_ogrenci/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Temel derleme testi
    expect(ChemClassOgrenciApp, isNotNull);
  });
}
