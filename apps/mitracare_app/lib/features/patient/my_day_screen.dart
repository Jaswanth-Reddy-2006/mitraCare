import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_system.dart';
import 'patient_providers.dart';
import 'package:mitracare_app/widgets/patient_bottom_nav_bar.dart';
import 'package:mitracare_app/services/localization_service.dart';

class MyDayScreen extends ConsumerWidget {
  const MyDayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(myDayTasksProvider);
    final textScale = MediaQuery.of(context).textScaleFactor;
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: DesignSystem.backgroundLight,
      appBar: AppBar(
        title: Text(
          LocalizationService.translate('my_day_label', lang),
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
            Expanded(
              child: tasksAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: DesignSystem.primaryGreen),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off, size: 64 * textScale, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          "Couldn't load today's schedule.\nMake sure the backend is active.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18 * textScale, color: DesignSystem.textSubtle),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(myDayTasksProvider.notifier).fetchTasks(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignSystem.primaryGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text("Try Again", style: TextStyle(fontSize: 16 * textScale)),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        "You have no tasks scheduled for today.",
                        style: TextStyle(fontSize: 18 * textScale, color: DesignSystem.textSubtle),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          LocalizationService.translate('your_tasks_today', lang),
                          style: TextStyle(
                            fontSize: 18 * textScale,
                            color: DesignSystem.textSubtle,
                          ),
                        ),
                      ),
                      ...tasks.map((task) => _buildTaskItem(context, ref, task, textScale, lang)),
                    ],
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

  Widget _buildTaskItem(BuildContext context, WidgetRef ref, Map<String, dynamic> task, double textScale, String lang) {
    final id = task['id'];
    final title = task['title'] ?? '';
    final timeStr = task['scheduled_time'] ?? '';
    final status = task['status'] ?? 'PENDING';
    final taskType = task['task_type'] ?? 'CUSTOM';

    final isCompleted = status == 'COMPLETED';

    IconData typeIcon = Icons.task_alt;
    Color iconColor = Colors.green;

    if (taskType == 'MEDICATION') {
      typeIcon = Icons.medical_services;
      iconColor = Colors.red.shade400;
    } else if (taskType == 'HYDRATION') {
      typeIcon = Icons.local_drink;
      iconColor = Colors.blue.shade400;
    } else if (taskType == 'ACTIVITY') {
      typeIcon = Icons.psychology;
      iconColor = Colors.purple.shade400;
    } else if (taskType == 'APPOINTMENT') {
      typeIcon = Icons.local_hospital;
      iconColor = Colors.teal.shade400;
    } else if (taskType == 'DAILY_ROUTINE') {
      typeIcon = Icons.directions_walk;
      iconColor = Colors.orange.shade400;
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: DesignSystem.softShadow,
          border: Border.all(
            color: isCompleted ? Colors.green.shade100 : Colors.grey.shade100,
            width: isCompleted ? 1.5 : 1.0,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, color: iconColor, size: 24 * textScale),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 14 * textScale,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.green.shade700 : DesignSystem.textSubtle,
                ),
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
            ],
          ),
          trailing: isCompleted
              ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 18),
                )
              : GestureDetector(
                  onTap: () => _showTaskOptions(context, ref, id, title, lang),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade600, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.orange,
                      size: 18,
                    ),
                  ),
                ),
        ),
      ),
    );
  }


  void _showTaskOptions(BuildContext context, WidgetRef ref, String taskId, String title, String lang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocalizationService.translateDynamic(title, lang),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DesignSystem.textDark),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(myDayTasksProvider.notifier).completeTask(taskId);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_outline),
                label: Text(LocalizationService.translate('completed', lang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.primaryGreen,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(myDayTasksProvider.notifier).skipTask(taskId);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.block),
                label: Text(LocalizationService.translate('skip', lang)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
