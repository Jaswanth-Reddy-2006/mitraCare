import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitracare_app/core/theme/design_system.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String _selectedLang = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English', 'tag': 'Default'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी', 'tag': ''},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी', 'tag': ''},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்', 'tag': ''},
    {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు', 'tag': ''},
    {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা', 'tag': ''},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedLang = 'en';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignSystem.textDark),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Choose Language",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "Select your preferred language",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final lang = _languages[index];
                    final isSelected = _selectedLang == lang['code'];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      decoration: BoxDecoration(
                        boxShadow: DesignSystem.softShadow,
                      ),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected ? DesignSystem.primaryGreen : Colors.grey.shade200,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: RadioListTile<String>(
                        value: lang['code']!,
                        groupValue: _selectedLang,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedLang = val);
                          }
                        },
                        activeColor: DesignSystem.primaryGreen,
                        title: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang['native']!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    lang['name']!,
                                    style: const TextStyle(
                                      color: DesignSystem.textSubtle,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (lang['tag']!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Text(
                                  lang['tag']!,
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.pop();
                },
                child: const Text("Continue"),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
