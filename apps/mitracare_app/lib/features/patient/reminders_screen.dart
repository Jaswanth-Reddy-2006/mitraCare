import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/design_system.dart';
import 'patient_providers.dart';
import 'package:mitracare_app/widgets/patient_bottom_nav_bar.dart';
import 'package:mitracare_app/services/localization_service.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  String _selectedFilter = 'ALL'; // 'ALL', 'MEDICINE', 'WATER', 'ACTIVITY'

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(remindersProvider);
    final textScale = MediaQuery.of(context).textScaleFactor;
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: DesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text(
          LocalizationService.translate('reminders_label', lang),
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
        child: Column(
          children: [
            // Filter row
            _buildFilterRow(textScale, lang),
            
            Expanded(
              child: remindersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: DesignSystem.primaryGreen),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 64 * textScale, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          "Could not fetch reminders.\nPlease retry.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18 * textScale, color: DesignSystem.textSubtle),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(remindersProvider.notifier).fetchReminders(),
                          style: ElevatedButton.styleFrom(backgroundColor: DesignSystem.primaryGreen),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (reminders) {
                  // Filter list
                  final filtered = reminders.where((r) {
                    if (_selectedFilter == 'ALL') return true;
                    return r['type'] == _selectedFilter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        "No reminders match this filter.",
                        style: TextStyle(fontSize: 18 * textScale, color: DesignSystem.textSubtle),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildReminderCard(filtered[index], textScale, lang);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PatientBottomNavBar(currentTab: 'none'),
    );
  }

  Widget _buildFilterRow(double textScale, String lang) {
    final filters = [
      {'label': LocalizationService.translate('filter_all', lang), 'code': 'ALL'},
      {'label': LocalizationService.translate('filter_meds', lang), 'code': 'MEDICINE'},
      {'label': LocalizationService.translate('filter_water', lang), 'code': 'WATER'},
      {'label': LocalizationService.translate('filter_acts', lang), 'code': 'ACTIVITY'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedFilter == f['code'];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(
                  f['label']!,
                  style: TextStyle(
                    fontSize: 14 * textScale,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : DesignSystem.textDark,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFilter = f['code']!);
                  }
                },
                selectedColor: DesignSystem.primaryGreen,
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                ),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder, double textScale, String lang) {
    final id = reminder['id'];
    final title = reminder['title'] ?? '';
    final desc = reminder['description'] ?? '';
    final type = reminder['type'] ?? 'MEDICINE';
    final scheduledAtStr = reminder['scheduled_at'] ?? '';
    final status = reminder['status'] ?? 'PENDING';
    final isCompleted = status == 'COMPLETED';

    DateTime? scheduledAt;
    try {
      scheduledAt = DateTime.parse(scheduledAtStr).toLocal();
    } catch (_) {}

    final timeFormatted = scheduledAt != null 
        ? DateFormat('h:mm a').format(scheduledAt)
        : '';

    IconData typeIcon = Icons.notifications;
    Color colorTheme = DesignSystem.primaryGreen;

    if (type == 'MEDICINE') {
      typeIcon = Icons.medical_services;
      colorTheme = Colors.red.shade400;
    } else if (type == 'WATER') {
      typeIcon = Icons.local_drink;
      colorTheme = Colors.blue.shade400;
    } else if (type == 'ACTIVITY') {
      typeIcon = Icons.psychology;
      colorTheme = Colors.purple.shade400;
    } else if (type == 'APPOINTMENT') {
      typeIcon = Icons.local_hospital;
      colorTheme = Colors.teal.shade400;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: DesignSystem.softShadow,
        border: Border.all(
          color: isCompleted ? Colors.green.shade100 : Colors.grey.shade100,
          width: isCompleted ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorTheme.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: colorTheme, size: 28 * textScale),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        timeFormatted,
                        style: TextStyle(
                          fontSize: 14 * textScale,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green.shade700 : colorTheme,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 8),
                        Text(
                          LocalizationService.translate('completed', lang),
                          style: TextStyle(
                            fontSize: 12 * textScale,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    LocalizationService.translateDynamic(title, lang),
                    style: TextStyle(
                      fontSize: 18 * textScale,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.grey.shade500 : DesignSystem.textDark,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      LocalizationService.translateDynamic(desc, lang),
                      style: TextStyle(
                        fontSize: 14 * textScale,
                        color: DesignSystem.textSubtle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isCompleted)
              ElevatedButton(
                onPressed: () {
                  ref.read(remindersProvider.notifier).completeReminder(id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorTheme,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  LocalizationService.translate('take_now', lang),
                  style: TextStyle(
                    fontSize: 12 * textScale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
