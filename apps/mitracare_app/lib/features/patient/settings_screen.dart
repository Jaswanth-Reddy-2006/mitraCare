import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitracare_app/core/theme/design_system.dart';
import 'package:mitracare_app/features/patient/patient_providers.dart';
import 'package:mitracare_app/services/localization_service.dart';

class PatientSettingsScreen extends ConsumerWidget {
  const PatientSettingsScreen({super.key});

  void _showLanguageSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final currentLang = ref.watch(languageProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 8.0),
                child: Text(
                  "Choose Language / भाषा चुनें",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DesignSystem.textDark,
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: LocalizationService.languages.length,
                  itemBuilder: (context, index) {
                    final lang = LocalizationService.languages[index];
                    final isSelected = currentLang == lang['code'];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                      leading: Icon(
                        Icons.check,
                        color: isSelected ? DesignSystem.primaryGreen : Colors.transparent,
                      ),
                      title: Text(
                        lang['native']!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? DesignSystem.primaryGreen : DesignSystem.textDark,
                        ),
                      ),
                      trailing: Text(
                        lang['name']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: DesignSystem.textSubtle,
                        ),
                      ),
                      onTap: () {
                        ref.read(languageProvider.notifier).setLanguage(lang['code']!);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double textScale = MediaQuery.of(context).textScaleFactor;
    final lang = ref.watch(languageProvider);
    final accessibility = ref.watch(accessibilityProvider);
    final accessNotifier = ref.read(accessibilityProvider.notifier);

    final currentLangName = LocalizationService.languages
        .firstWhere((l) => l['code'] == lang, orElse: () => {'native': 'English'})['native']!;

    return Scaffold(
      backgroundColor: DesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            color: DesignSystem.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 22.0 * textScale,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignSystem.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Settings Header
            Text(
              "Accessibility Options",
              style: TextStyle(
                fontSize: 18 * textScale,
                fontWeight: FontWeight.bold,
                color: DesignSystem.textSubtle,
              ),
            ),
            const SizedBox(height: 16),

            // Text Size Slider Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.text_fields, color: DesignSystem.primaryGreen),
                            const SizedBox(width: 12),
                            Text(
                              "Text Size Scale",
                              style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                            ),
                          ],
                        ),
                        Text(
                          accessibility.textScaleFactor.toStringAsFixed(1),
                          style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.primaryGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: accessibility.textScaleFactor,
                      min: 0.8,
                      max: 1.6,
                      divisions: 8,
                      activeColor: DesignSystem.primaryGreen,
                      onChanged: (val) {
                        accessNotifier.setTextScale(val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // High Contrast Switch Card
            Card(
              child: SwitchListTile(
                title: Text(
                  "High Contrast Mode",
                  style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                ),
                subtitle: const Text("Increases readability of text and buttons"),
                secondary: const Icon(Icons.contrast, color: DesignSystem.primaryGreen),
                value: accessibility.isHighContrast,
                activeColor: DesignSystem.primaryGreen,
                onChanged: (val) {
                  accessNotifier.toggleHighContrast(val);
                },
              ),
            ),
            const SizedBox(height: 12),

            // Easy-Read Font Switch Card
            Card(
              child: SwitchListTile(
                title: Text(
                  "Easy-Read Dyslexic Font",
                  style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                ),
                subtitle: const Text("Uses a clean monospace font for easier reading"),
                secondary: const Icon(Icons.font_download_outlined, color: DesignSystem.primaryGreen),
                value: accessibility.isEasyReadFont,
                activeColor: DesignSystem.primaryGreen,
                onChanged: (val) {
                  accessNotifier.toggleEasyRead(val);
                },
              ),
            ),
            const SizedBox(height: 12),

            // Language Selector Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.language, color: DesignSystem.primaryGreen),
                title: Text(
                  "Preferred Language",
                  style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentLangName,
                      style: TextStyle(fontSize: 14 * textScale, color: DesignSystem.textSubtle),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => _showLanguageSelector(context, ref),
              ),
            ),
            const SizedBox(height: 36),

            Text(
              "Account Connections",
              style: TextStyle(
                fontSize: 18 * textScale,
                fontWeight: FontWeight.bold,
                color: DesignSystem.textSubtle,
              ),
            ),
            const SizedBox(height: 16),

            // My ID Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.qr_code, color: DesignSystem.primaryGreen),
                title: Text(
                  "My MitraCare ID / QR",
                  style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
                ),
                subtitle: const Text("Show code or QR to connect with a caregiver"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/patient/my-id'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
