import 'package:flutter_test/flutter_test.dart';

import 'package:afinador_flutter/core/di/injection_container.dart';
import 'package:afinador_flutter/main.dart';

void main() {
  setupDependencies();

  testWidgets('Tela do afinador é exibida', (WidgetTester tester) async {
    await tester.pumpWidget(const AfinadorApp());

    expect(find.text('Afinador'), findsOneWidget);
    expect(find.text('Iniciar'), findsOneWidget);
    expect(find.text('TOQUE UMA NOTA'), findsOneWidget);
  });
}
