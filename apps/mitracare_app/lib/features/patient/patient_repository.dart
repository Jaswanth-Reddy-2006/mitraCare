import 'package:dio/dio.dart';
import '../../services/api_service.dart';

class ActivityRepository {
  final ApiService _apiService;
  ActivityRepository(this._apiService);

  Future<List<dynamic>> getActivities() async {
    try {
      final response = await _apiService.dio.get("/patient/activities");
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> startSession(String activityId, {String? difficulty}) async {
    try {
      final response = await _apiService.dio.post("/patient/activity-sessions", data: {
        "activity_id": activityId,
        "difficulty_level": difficulty ?? "MEDIUM",
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> submitResult({
    required String sessionId,
    required int score,
    required double accuracy,
    int? responseTime,
    int mistakes = 0,
    int hintsUsed = 0,
    String? metadata,
  }) async {
    try {
      final response = await _apiService.dio.post(
        "/patient/activity-sessions/$sessionId/result",
        data: {
          "score": score,
          "accuracy": accuracy,
          "response_time": responseTime,
          "mistakes": mistakes,
          "hints_used": hintsUsed,
          "metadata_json": metadata,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getHistory() async {
    try {
      final response = await _apiService.dio.get("/patient/activity-history");
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}

class DailyTaskRepository {
  final ApiService _apiService;
  DailyTaskRepository(this._apiService);

  Future<List<dynamic>> getMyDay(String dateStr) async {
    try {
      final response = await _apiService.dio.get("/patient/my-day", queryParameters: {
        "date": dateStr,
      });
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> completeTask(String taskId) async {
    try {
      final response = await _apiService.dio.post("/patient/my-day/tasks/$taskId/complete");
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> skipTask(String taskId) async {
    try {
      final response = await _apiService.dio.post("/patient/my-day/tasks/$taskId/skip");
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> snoozeTask(String taskId) async {
    try {
      final response = await _apiService.dio.post("/patient/my-day/tasks/$taskId/snooze");
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}

class ReminderRepository {
  final ApiService _apiService;
  ReminderRepository(this._apiService);

  Future<List<dynamic>> getRemindersForToday() async {
    try {
      final response = await _apiService.dio.get("/patient/reminders/today");
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> completeReminder(String reminderId) async {
    try {
      final response = await _apiService.dio.post("/patient/reminders/$reminderId/complete");
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> snoozeReminder(String reminderId) async {
    try {
      final response = await _apiService.dio.post("/patient/reminders/$reminderId/snooze");
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}

Exception _handleError(DioException e) {
  final message = e.response?.data?["detail"] ?? e.message ?? "An unknown error occurred";
  return Exception(message);
}
