import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:afinador_flutter/core/di/injection_container.dart';
import 'package:afinador_flutter/main.dart';
import 'package:afinador_flutter/presentation/viewmodels/tuner_view_model.dart';
import 'package:afinador_flutter/presentation/views/tuner_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tocar no botão da corda reproduz o tom de referência',
      (tester) async {
    setupDependencies();

    await tester.pumpWidget(const AfinadorApp());
    await tester.pumpAndSettle();

    // Violão (default) mostra as cordas E2, A2, D3, G3, B3, E4 como botões.
    final stringButton = find.widgetWithText(ActionChip, 'E2');
    expect(stringButton, findsOneWidget);

    await tester.tap(stringButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final viewModel = Provider.of<TunerViewModel>(
      tester.element(find.byType(TunerView)),
      listen: false,
    );
    expect(viewModel.errorMessage, isNull);
  });
}
