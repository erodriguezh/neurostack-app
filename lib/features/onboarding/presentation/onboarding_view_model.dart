import 'package:flutter/foundation.dart';
import 'package:neurostack/core/utils/navigation/navigation_intent_store.dart';
import 'package:neurostack/core/utils/navigation/route_data.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/auth/domain/auth_state.dart';
import 'package:neurostack/features/onboarding/data/onboarding_store.dart';
import 'package:neurostack/features/onboarding/domain/onboarding_step.dart';

/// Immutable state for the onboarding flow.
class OnboardingState {
  const OnboardingState({
    this.currentStep = OnboardingStep.hook,
    this.disclaimerAccepted = false,
  });

  final OnboardingStep currentStep;
  final bool disclaimerAccepted;

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    bool? disclaimerAccepted,
  }) => OnboardingState(
    currentStep: currentStep ?? this.currentStep,
    disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
  );
}

/// ViewModel for the onboarding flow.
///
/// Manages step navigation and completion state.
class OnboardingViewModel {
  OnboardingViewModel({
    required OnboardingStore store,
    required NavigationIntentStore navigationIntentStore,
    required RouterService routerService,
    required AuthService authService,
  }) : _store = store,
       _navigationIntentStore = navigationIntentStore,
       _routerService = routerService,
       _authService = authService;

  final OnboardingStore _store;
  final NavigationIntentStore _navigationIntentStore;
  final RouterService _routerService;
  final AuthService _authService;

  final ValueNotifier<OnboardingState> state = ValueNotifier(
    const OnboardingState(),
  );

  bool _isCompleting = false;

  /// Navigate to a specific step.
  void goToStep(OnboardingStep step) {
    state.value = state.value.copyWith(currentStep: step);
  }

  /// Navigate to the next step.
  void nextStep() {
    final currentIndex = state.value.currentStep.index;
    if (currentIndex < OnboardingStep.values.length - 1) {
      state.value = state.value.copyWith(
        currentStep: OnboardingStep.values[currentIndex + 1],
      );
    }
  }

  /// Navigate to the previous step.
  /// Returns true if step changed, false if already on first screen.
  bool previousStep() {
    final currentIndex = state.value.currentStep.index;
    if (currentIndex > 0) {
      state.value = state.value.copyWith(
        currentStep: OnboardingStep.values[currentIndex - 1],
      );
      return true;
    }
    return false;
  }

  /// Update disclaimer acceptance state.
  void setDisclaimerAccepted(bool value) {
    state.value = state.value.copyWith(disclaimerAccepted: value);
  }

  /// Complete onboarding and navigate based on auth state.
  ///
  /// This method:
  /// 1. Marks onboarding as completed
  /// 2. Clears the force onboarding flag
  /// 3. Initializes auth
  /// 4. Routes based on auth state
  Future<void> completeOnboarding() async {
    if (_isCompleting) return; // Guard against double-tap
    _isCompleting = true;

    try {
      await _store.markCompleted();
      await _navigationIntentStore.clearForceOnboarding();
      await _authService.init();

      // Handle all auth states explicitly
      final authState = _authService.authState.value;
      switch (authState) {
        case AuthenticatedOnline():
          // AuthService._handlePostAuthNavigation() handles this
          // It will consume intended route if present
          break;
        case AuthenticatedOffline():
          // Offline cached users - route to home
          // Clear intended route to prevent stale deep links being replayed later
          await _navigationIntentStore.clearIntendedRoute();
          _routerService.replaceAll([Path(name: '/')]);
        case OfflineNoUser():
          // No cached user, offline - route to dedicated offline screen
          await _navigationIntentStore.clearIntendedRoute();
          _routerService.replaceAll([Path(name: '/offline')]);
        case Unauthenticated():
          // Keep intended route - will be replayed after auth completes
          _routerService.replaceAll([Path(name: '/auth')]);
        case AuthUnknown():
        case Authenticating():
          // Auth state not settled - route to auth and let user retry
          _routerService.replaceAll([Path(name: '/auth')]);
      }
    } catch (e) {
      // Auth init failed - route to auth and let user retry
      _routerService.replaceAll([Path(name: '/auth')]);
    } finally {
      _isCompleting = false;
    }
  }

  void dispose() {
    state.dispose();
  }
}
