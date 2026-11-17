import 'package:flutter_test/flutter_test.dart';
import 'package:geofluxo/main.dart';

void main() {
  testWidgets('GeoFluxo renders main territorial dashboard shell', (tester) async {
    await tester.pumpWidget(const GeoFluxoApp());
    await tester.pump();

    expect(find.text('Painel Territorial'), findsOneWidget);
    expect(find.text('Painel'), findsOneWidget);
    expect(find.text('Alertas'), findsOneWidget);
  });
}
