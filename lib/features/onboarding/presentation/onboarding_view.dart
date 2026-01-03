import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neurostack/core/ui/widgets/enum_page_view.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/navigation_intent_store.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/data/auth_service.dart';
import 'package:neurostack/features/onboarding/data/onboarding_store.dart';
import 'package:neurostack/features/onboarding/domain/onboarding_step.dart';
import 'package:neurostack/features/onboarding/presentation/onboarding_view_model.dart';
import 'package:neurostack/features/onboarding/presentation/widgets/screens/agitate_screen.dart';
import 'package:neurostack/features/onboarding/presentation/widgets/screens/disclaimer_screen.dart';
import 'package:neurostack/features/onboarding/presentation/widgets/screens/hook_screen.dart';
import 'package:neurostack/features/onboarding/presentation/widgets/screens/offer_screen.dart';

/// The main onboarding view that manages the 4-screen flow.
///
/// Uses EnumPageView for smooth page transitions and PopScope for back navigation.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late final OnboardingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Lock to portrait orientation
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _viewModel = OnboardingViewModel(
      store: locator<OnboardingStore>(),
      navigationIntentStore: locator<NavigationIntentStore>(),
      routerService: locator<RouterService>(),
      authService: locator<AuthService>(),
    );
  }

  @override
  void dispose() {
    // Restore all orientations
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<OnboardingState>(
      valueListenable: _viewModel.state,
      builder: (context, state, _) => PopScope(
        // Allow system back on first screen (exit to launcher)
        canPop: state.currentStep == OnboardingStep.hook,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return; // System handled it
          _viewModel.previousStep(); // Navigate back within onboarding
        },
        // EnumPageView MUST be inside the builder to react to step changes
        child: EnumPageView<OnboardingStep>(
          value: state.currentStep,
          values: OnboardingStep.values,
          builder: (step) => _buildScreen(step, state),
        ),
      ),
    );
  }

  Widget _buildScreen(OnboardingStep step, OnboardingState state) {
    return switch (step) {
      OnboardingStep.hook => HookScreen(
        onNext: _viewModel.nextStep,
      ),
      OnboardingStep.agitate => AgitateScreen(
        onNext: _viewModel.nextStep,
      ),
      OnboardingStep.offer => OfferScreen(
        onNext: _viewModel.nextStep,
      ),
      OnboardingStep.disclaimer => DisclaimerScreen(
        disclaimerAccepted: state.disclaimerAccepted,
        onDisclaimerChanged: _viewModel.setDisclaimerAccepted,
        onComplete: _viewModel.completeOnboarding,
      ),
    };
  }
}
