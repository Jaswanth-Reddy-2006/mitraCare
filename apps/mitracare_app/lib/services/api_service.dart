import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  late final Dio _dio;
  final _secureStorage = const FlutterSecureStorage();

  Dio get dio => _dio;

  ApiService() {
    // Resolve base URL for local development:
    // Android emulator loops back to 10.0.2.2, standard web/desktop uses localhost.
    String baseUrl = "http://localhost:8000";
    if (!kIsWeb && Platform.isAndroid) {
      baseUrl = "http://10.0.2.2:8000";
    }

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: Headers.jsonContentType,
    ));

    // Interceptor to attach Authorization header automatically
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: "auth_token");
        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        debugPrint("API Error: ${e.response?.statusCode} - ${e.response?.data}");
        return handler.next(e);
      },
    ));
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: "auth_token");
  }

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: "auth_token", value: token);
  }

  Future<String?> getRole() async {
    return await _secureStorage.read(key: "auth_role");
  }

  Future<void> saveRole(String role) async {
    await _secureStorage.write(key: "auth_role", value: role);
  }

  Future<String?> getName() async {
    return await _secureStorage.read(key: "auth_name");
  }

  Future<void> saveName(String name) async {
    await _secureStorage.write(key: "auth_name", value: name);
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: "auth_token");
    await _secureStorage.delete(key: "auth_role");
    await _secureStorage.delete(key: "auth_name");
  }

  // Auth Endpoints
  Future<Map<String, dynamic>> register({
    required String name,
    required String role,
    required String password,
    String? email,
    String? phone,
    int? age,
    String? emergencyName,
    String? emergencyPhone,
    String? organization,
  }) async {
    try {
      final response = await _dio.post("/auth/register", data: {
        "name": name,
        "role": role,
        "password": password,
        "email": email?.isEmpty == true ? null : email,
        "phone": phone?.isEmpty == true ? null : phone,
        "age": age,
        "emergency_contact_name": emergencyName,
        "emergency_contact_phone": emergencyPhone,
        "organization": organization,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post("/auth/login", data: {
        "username": username,
        "password": password,
      });
      final data = response.data as Map<String, dynamic>;
      final token = data["access_token"] as String;
      await saveToken(token);
      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get("/auth/me");
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Connections Endpoints
  Future<Map<String, dynamic>> generateConnectionCode() async {
    try {
      final response = await _dio.post("/connections/generate-code");
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> joinConnection(String code) async {
    try {
      final response = await _dio.post("/connections/join", data: {
        "code": code,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getConnections() async {
    try {
      final response = await _dio.get("/connections");
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> inspectConnectionCode(String code) async {
    try {
      final response = await _dio.get("/connections/inspect", queryParameters: {
        "code": code,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update profile
  Future<Map<String, dynamic>> updatePatientProfile({
    int? age,
    String? emergencyName,
    String? emergencyPhone,
  }) async {
    try {
      final response = await _dio.put("/patients/me", data: {
        "age": age,
        "emergency_contact_name": emergencyName,
        "emergency_contact_phone": emergencyPhone,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Caregiver App API Methods
  Future<Map<String, dynamic>> getCaregiverDashboard(String patientId) async {
    try {
      final response = await _dio.get("/caregiver/dashboard-summary", queryParameters: {
        "patient_id": patientId,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCaregiverReports(String patientId, int rangeDays) async {
    try {
      final response = await _dio.get("/caregiver/reports", queryParameters: {
        "patient_id": patientId,
        "range_days": rangeDays,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addPatientTask(String patientId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/caregiver/patients/$patientId/tasks", data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deletePatientTask(String patientId, String taskId) async {
    try {
      final response = await _dio.delete("/caregiver/patients/$patientId/tasks/$taskId");
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> addPatientReminder(String patientId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/caregiver/patients/$patientId/reminders", data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> deletePatientReminder(String patientId, String reminderId) async {
    try {
      final response = await _dio.delete("/caregiver/patients/$patientId/reminders/$reminderId");
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getCaregiverAlerts() async {
    try {
      final response = await _dio.get("/caregiver/alerts");
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updatePatientProfileByCaregiver(String patientId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post("/caregiver/patients/$patientId/profile", data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch a patient's scheduled tasks for a given date (YYYY-MM-DD).
  Future<List<dynamic>> getPatientSchedule(String patientId, String date) async {
    try {
      final response = await _dio.get("/patient/my-day", queryParameters: {
        "patient_id": patientId,
        "date": date,
      });
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Fetch today's reminders for a given patient.
  Future<List<dynamic>> getPatientRemindersToday(String patientId) async {
    try {
      final response = await _dio.get("/patient/reminders/today", queryParameters: {
        "patient_id": patientId,
      });
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {

    final message = e.response?.data?["detail"] ?? e.message ?? "An unknown error occurred";
    return Exception(message);
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// A provider to cache current user authentication state
class AuthState {
  final bool isAuthenticated;
  final String? role;
  final String? name;
  final Map<String, dynamic>? userDetails;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.role,
    this.name,
    this.userDetails,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? role,
    String? name,
    Map<String, dynamic>? userDetails,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      name: name ?? this.name,
      userDetails: userDetails ?? this.userDetails,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final token = await _apiService.getToken();
    if (token == null) {
      state = AuthState();
      return;
    }

    final cachedRole = await _apiService.getRole();
    final cachedName = await _apiService.getName();

    if (cachedRole != null) {
      state = AuthState(
        isAuthenticated: true,
        role: cachedRole,
        name: cachedName,
      );
    }

    try {
      final user = await _apiService.getMe();
      if (user["role"] != null) {
        await _apiService.saveRole(user["role"]);
      }
      if (user["name"] != null) {
        await _apiService.saveName(user["name"]);
      }

      state = AuthState(
        isAuthenticated: true,
        role: user["role"],
        name: user["name"],
        userDetails: user,
      );
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          await _apiService.clearToken();
          state = AuthState();
          return;
        }
      }
      if (cachedRole != null) {
        state = AuthState(
          isAuthenticated: true,
          role: cachedRole,
          name: cachedName,
        );
      } else {
        await _apiService.clearToken();
        state = AuthState(error: e.toString());
      }
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      state = AuthState(error: null);
      final result = await _apiService.login(username: username, password: password);
      state = AuthState(
        isAuthenticated: true,
        role: result["role"],
        name: result["name"],
        userDetails: null, // will load in checkAuth or getMe
      );
      await checkAuth();
      return true;
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String role,
    required String password,
    String? email,
    String? phone,
    int? age,
    String? emergencyName,
    String? emergencyPhone,
    String? organization,
  }) async {
    try {
      state = AuthState(error: null);
      await _apiService.register(
        name: name,
        role: role,
        password: password,
        email: email,
        phone: phone,
        age: age,
        emergencyName: emergencyName,
        emergencyPhone: emergencyPhone,
        organization: organization,
      );
      
      // Auto login after registration
      return await login(email ?? phone ?? "", password);
    } catch (e) {
      state = AuthState(error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.clearToken();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(apiService);
});
