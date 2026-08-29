import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitracare_app/core/theme/design_system.dart';
import 'package:mitracare_app/routing/router.dart';
import 'package:mitracare_app/features/patient/patient_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MitraCareApp(),
    ),
  );
}

class MitraCareApp extends ConsumerWidget {
  const MitraCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final accessibility = ref.watch(accessibilityProvider);

    return MaterialApp.router(
      title: 'MitraCare',
      debugShowCheckedModeBanner: false,
      theme: DesignSystem.buildTheme(
        isHighContrast: accessibility.isHighContrast,
        textScaleFactor: accessibility.textScaleFactor,
        isEasyReadFont: accessibility.isEasyReadFont,
      ),
      routerConfig: router,
    );
  }
}
