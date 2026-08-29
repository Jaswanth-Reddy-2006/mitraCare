import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitracare_app/services/api_service.dart';
import 'package:mitracare_app/features/auth/welcome_screen.dart';
import 'package:mitracare_app/features/auth/language_screen.dart';
import 'package:mitracare_app/features/auth/role_selection_screen.dart';
import 'package:mitracare_app/features/auth/login_screen.dart';
import 'package:mitracare_app/features/auth/register_screen.dart';
import 'package:mitracare_app/features/auth/register_success_screen.dart';
import 'package:mitracare_app/features/auth/forgot_password_screen.dart';
import 'package:mitracare_app/features/onboarding/patient_onboarding_screen.dart';
import 'package:mitracare_app/features/patient/home_screen.dart';
import 'package:mitracare_app/features/patient/activities_screen.dart';
import 'package:mitracare_app/features/patient/my_day_screen.dart';
import 'package:mitracare_app/features/patient/reminders_screen.dart';
import 'package:mitracare_app/features/patient/help_screen.dart';
import 'package:mitracare_app/features/patient/recall_memory_screen.dart';
import 'package:mitracare_app/features/patient/patient_id_screen.dart';
import 'package:mitracare_app/features/patient/settings_screen.dart';
import 'package:mitracare_app/features/patient/games/screens/choose_game_screen.dart';
import 'package:mitracare_app/features/patient/games/screens/cognitive_game_screen.dart';
import 'package:mitracare_app/features/patient/games/models/cognitive_game_models.dart';
import 'package:mitracare_app/features/auth/connect_handler_screen.dart';
import 'package:mitracare_app/features/caregiver/dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isGoingToAuth = state.matchedLocation.startsWith('/welcome') ||
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/language') ||
          state.matchedLocation.startsWith('/role-selection') ||
          state.matchedLocation.startsWith('/register-success') ||
          state.matchedLocation.startsWith('/forgot-password') ||
          state.matchedLocation.startsWith('/connect');

      if (!isLoggedIn) {
        // Not logged in -> send to auth screens
        if (isGoingToAuth) return null;
        return '/welcome';
      }

      // Logged in -> Guard routes based on role
      final role = authState.role;
      if (role == 'PATIENT') {
        // Patients need onboarding if they haven't set up profile details
        final userDetails = authState.userDetails;
        final patientProfile = userDetails?['patient_profile'];
        final needsOnboarding = patientProfile == null || 
                                patientProfile['age'] == null ||
                                patientProfile['emergency_contact_phone'] == null;
        
        if (needsOnboarding && !state.matchedLocation.startsWith('/onboarding')) {
          return '/onboarding';
        }
        
        if (!needsOnboarding && isGoingToAuth) {
          return '/patient-home';
        }
        
        // Prevent access to caregiver screens
        if (state.matchedLocation.startsWith('/caregiver')) {
          return '/patient-home';
        }
      } else if (role == 'CAREGIVER') {
        if (isGoingToAuth || state.matchedLocation.startsWith('/onboarding')) {
          return '/caregiver-dashboard';
        }
        
        // Prevent access to patient screens
        if (state.matchedLocation.startsWith('/patient')) {
          return '/caregiver-dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? 'PATIENT';
          return RegisterScreen(role: role);
        },
      ),
      GoRoute(
        path: '/register-success',
        builder: (context, state) => const RegisterSuccessScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const PatientOnboardingScreen(),
      ),
      GoRoute(
        path: '/patient-home',
        builder: (context, state) => const PatientHomeScreen(),
      ),
      GoRoute(
        path: '/patient/activities',
        builder: (context, state) => const ActivitiesScreen(),
      ),
      GoRoute(
        path: '/patient/game/choose',
        builder: (context, state) => const ChooseGameScreen(),
      ),
      GoRoute(
        path: '/patient/game/find-the-pair',
        builder: (context, state) {
          final actId = state.uri.queryParameters['activityId'] ?? 'pair_act_id';
          final diff = state.uri.queryParameters['difficulty'] ?? 'EASY';
          return CognitiveGameScreen(
            activityId: actId,
            gameMode: GameMode.pair,
            difficulty: diff,
          );
        },
      ),
      GoRoute(
        path: '/patient/game/find-the-triplet',
        builder: (context, state) {
          final actId = state.uri.queryParameters['activityId'] ?? 'triplet_act_id';
          final diff = state.uri.queryParameters['difficulty'] ?? 'EASY';
          return CognitiveGameScreen(
            activityId: actId,
            gameMode: GameMode.triplet,
            difficulty: diff,
          );
        },
      ),
      GoRoute(
        path: '/patient/my-day',
        builder: (context, state) => const MyDayScreen(),
      ),
      GoRoute(
        path: '/patient/reminders',
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: '/patient/recall-memory',
        builder: (context, state) => const RecallMemoryScreen(),
      ),
      GoRoute(
        path: '/patient/help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/patient/settings',
        builder: (context, state) => const PatientSettingsScreen(),
      ),
      GoRoute(
        path: '/patient/my-id',
        builder: (context, state) => const PatientIdScreen(),
      ),
      GoRoute(
        path: '/connect',
        builder: (context, state) {
          final token = state.uri.queryParameters['t'] ?? state.uri.queryParameters['token'] ?? state.uri.queryParameters['code'];
          return ConnectDeepLinkHandler(token: token);
        },
      ),
      GoRoute(
        path: '/caregiver-dashboard',
        builder: (context, state) => const CaregiverDashboardScreen(),
      ),
    ],
  );
});
