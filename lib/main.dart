import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/injection_container.dart';
import 'presentation/viewmodels/tuner_view_model.dart';
import 'presentation/views/tuner_view.dart';

void main() {
  setupDependencies();
  runApp(const AfinadorApp());
}

class AfinadorApp extends StatelessWidget {
  const AfinadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Afinador',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: ChangeNotifierProvider(
        create: (_) => sl<TunerViewModel>(),
        child: const TunerView(),
      ),
    );
  }
}
