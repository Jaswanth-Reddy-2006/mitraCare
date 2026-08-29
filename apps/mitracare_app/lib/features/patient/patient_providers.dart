import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../services/voice_service.dart';
import 'patient_repository.dart';
import 'package:intl/intl.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ActivityRepository(apiService);
});

final dailyTaskRepositoryProvider = Provider<DailyTaskRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DailyTaskRepository(apiService);
});

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReminderRepository(apiService);
});

final voiceServiceProvider = ChangeNotifierProvider<VoiceService>((ref) {
  return VoiceService();
});

final activitiesProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(activityRepositoryProvider);
  return await repo.getActivities();
});

final activityHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(activityRepositoryProvider);
  return await repo.getHistory();
});

// My Day state notifier
class MyDayTasksNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final DailyTaskRepository _repository;
  final String _todayStr;

  MyDayTasksNotifier(this._repository)
      : _todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now()),
        super(const AsyncValue.loading()) {
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _repository.getMyDay(_todayStr);
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> completeTask(String taskId) async {
    try {
      final updatedTask = await _repository.completeTask(taskId);
      state.whenData((tasks) {
        state = AsyncValue.data(
          tasks.map((t) => t['id'] == taskId ? updatedTask : t).toList(),
        );
      });
    } catch (e) {
      // Keep state but log error
    }
  }

  Future<void> skipTask(String taskId) async {
    try {
      final updatedTask = await _repository.skipTask(taskId);
      state.whenData((tasks) {
        state = AsyncValue.data(
          tasks.map((t) => t['id'] == taskId ? updatedTask : t).toList(),
        );
      });
    } catch (e) {
      // Keep state
    }
  }

  Future<void> snoozeTask(String taskId) async {
    try {
      final updatedTask = await _repository.snoozeTask(taskId);
      state.whenData((tasks) {
        state = AsyncValue.data(
          tasks.map((t) => t['id'] == taskId ? updatedTask : t).toList(),
        );
      });
    } catch (e) {
      // Keep state
    }
  }
}

final myDayTasksProvider = StateNotifierProvider<MyDayTasksNotifier, AsyncValue<List<dynamic>>>((ref) {
  final repo = ref.watch(dailyTaskRepositoryProvider);
  return MyDayTasksNotifier(repo);
});

// Reminders state notifier
class RemindersNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final ReminderRepository _repository;

  RemindersNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchReminders();
  }

  Future<void> fetchReminders() async {
    state = const AsyncValue.loading();
    try {
      final reminders = await _repository.getRemindersForToday();
      state = AsyncValue.data(reminders);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> completeReminder(String reminderId) async {
    try {
      final updatedReminder = await _repository.completeReminder(reminderId);
      state.whenData((reminders) {
        state = AsyncValue.data(
          reminders.map((r) => r['id'] == reminderId ? updatedReminder : r).toList(),
        );
      });
    } catch (e) {
      // Keep state
    }
  }

  Future<void> snoozeReminder(String reminderId) async {
    try {
      final updatedReminder = await _repository.snoozeReminder(reminderId);
      state.whenData((reminders) {
        state = AsyncValue.data(
          reminders.map((r) => r['id'] == reminderId ? updatedReminder : r).toList(),
        );
      });
    } catch (e) {
      // Keep state
    }
  }
}

final remindersProvider = StateNotifierProvider<RemindersNotifier, AsyncValue<List<dynamic>>>((ref) {
  final repo = ref.watch(reminderRepositoryProvider);
  return RemindersNotifier(repo);
});

class AccessibilitySettings {
  final bool isHighContrast;
  final double textScaleFactor;
  final bool isEasyReadFont;

  AccessibilitySettings({
    this.isHighContrast = false,
    this.textScaleFactor = 1.0,
    this.isEasyReadFont = false,
  });

  AccessibilitySettings copyWith({
    bool? isHighContrast,
    double? textScaleFactor,
    bool? isEasyReadFont,
  }) {
    return AccessibilitySettings(
      isHighContrast: isHighContrast ?? this.isHighContrast,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      isEasyReadFont: isEasyReadFont ?? this.isEasyReadFont,
    );
  }
}

class AccessibilityNotifier extends StateNotifier<AccessibilitySettings> {
  final _storage = const _FakeStorage();

  AccessibilityNotifier() : super(AccessibilitySettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final contrast = await _storage.read('accessibility_high_contrast');
    final scale = await _storage.read('accessibility_text_scale');
    final easyRead = await _storage.read('accessibility_easy_read');

    state = AccessibilitySettings(
      isHighContrast: contrast == 'true',
      textScaleFactor: double.tryParse(scale ?? '1.0') ?? 1.0,
      isEasyReadFont: easyRead == 'true',
    );
  }

  Future<void> toggleHighContrast(bool value) async {
    state = state.copyWith(isHighContrast: value);
    await _storage.write('accessibility_high_contrast', value.toString());
  }

  Future<void> setTextScale(double value) async {
    state = state.copyWith(textScaleFactor: value);
    await _storage.write('accessibility_text_scale', value.toString());
  }

  Future<void> toggleEasyRead(bool value) async {
    state = state.copyWith(isEasyReadFont: value);
    await _storage.write('accessibility_easy_read', value.toString());
  }
}

class _FakeStorage {
  static final Map<String, String> _data = {};
  const _FakeStorage();
  Future<String?> read(String key) async => _data[key];
  Future<void> write(String key, String value) async => _data[key] = value;
}

final accessibilityProvider = StateNotifierProvider<AccessibilityNotifier, AccessibilitySettings>((ref) {
  return AccessibilityNotifier();
});
