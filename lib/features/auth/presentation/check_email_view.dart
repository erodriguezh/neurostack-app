import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/curves.dart';
import 'package:neurostack/core/ui/constants/widget_keys.dart';
import 'package:neurostack/core/ui/widgets/app_primary_cta.dart';
import 'package:neurostack/core/utils/data_source/data_source_abstraction.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/l10n/translate_extension.dart';
import 'package:neurostack/core/utils/navigation/navigation_intent_store.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/presentation/check_email_view_model.dart';
import 'package:neurostack/features/auth/presentation/widgets/auth_background.dart';

class CheckEmailView extends StatefulWidget {
  const CheckEmailView({super.key});

  @override
  State<CheckEmailView> createState() => _CheckEmailViewState();
}

class _CheckEmailViewState extends State<CheckEmailView>
    with TickerProviderStateMixin {
  late final CheckEmailViewModel _viewModel;
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = CheckEmailViewModel(
      navigationIntentStore: locator<NavigationIntentStore>(),
      routerService: locator<RouterService>(),
      dataSource: locator<DataSourceAbstraction>(),
      notifyService: locator<NotifyService>(),
    );
    _viewModel.init();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: CustomCurves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: CustomCurves.easeOut,
          ),
        );
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: CustomCurves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    _codeController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final textTheme = context.theme.textTheme;

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: context.spacing.lg * 3),
                            AnimatedBuilder(
                              animation: _floatAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatAnimation.value),
                                  child: child,
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: kitColors.brandSky.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 30,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.mail_outline,
                                  size: 64,
                                  color: kitColors.brandSky,
                                ),
                              ),
                            ),
                            SizedBox(height: context.spacing.lg),
                            Text(
                              context.translate.checkEmailTitle,
                              style: textTheme.headlineLarge?.copyWith(
                                fontSize: 28,
                                color: kitColors.white90,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: context.spacing.lg),
                            ValueListenableBuilder<String?>(
                              valueListenable: _viewModel.email,
                              builder: (context, value, _) {
                                final displayEmail =
                                    value ?? context.translate.authMissingEmail;
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.spacing.md,
                                    vertical: context.spacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kitColors.white02,
                                    borderRadius: context.borderRadius.xl,
                                    border: Border.all(
                                      color: kitColors.brandSky.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                    boxShadow: context.shadows.skyGlow,
                                  ),
                                  child: Text(
                                    displayEmail,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: kitColors.brandSky,
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: context.spacing.lg),
                            Text(
                              context.translate.checkEmailInstruction,
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: kitColors.white60,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: context.spacing.sm),
                            Text(
                              context.translate.checkEmailSpamHint,
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                fontStyle: FontStyle.italic,
                                color: kitColors.white30,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: context.spacing.xl),
                            _VerificationSection(
                              viewModel: _viewModel,
                              controller: _codeController,
                            ),
                            SizedBox(height: context.spacing.xl),
                            ValueListenableBuilder<int>(
                              valueListenable: _viewModel.cooldownSeconds,
                              builder: (context, seconds, _) {
                                final isEnabled = _viewModel.canResend;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: isEnabled
                                          ? _viewModel.resendCode
                                          : null,
                                      icon: Icon(
                                        _resendIcon(isEnabled),
                                        size: 16,
                                      ),
                                      label: Text(
                                        _resendLabel(
                                          context: context,
                                          isEnabled: isEnabled,
                                          seconds: seconds,
                                        ),
                                      ),
                                      style: _resendButtonStyle(context),
                                    ),
                                    SizedBox(height: context.spacing.md),
                                    TextButton.icon(
                                      onPressed: _viewModel.changeEmail,
                                      icon: Icon(
                                        Icons.arrow_back,
                                        size: 14,
                                        color: kitColors.white30,
                                      ),
                                      label: Text(
                                        context.translate.authChangeEmail,
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: kitColors.white40,
                                        minimumSize: const Size.fromHeight(44),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: context.spacing.xxl),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _resendButtonStyle(BuildContext context) {
    final kitColors = context.kitColors;

    return OutlinedButton.styleFrom(
      backgroundColor: kitColors.white02,
      padding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: context.borderRadius.full),
      textStyle: context.theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
    ).copyWith(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return kitColors.white30;
        }
        return kitColors.white70;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: kitColors.white10);
        }
        return BorderSide(color: kitColors.white10);
      }),
    );
  }

  String _formatSeconds(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }

  IconData _resendIcon(bool isEnabled) {
    if (isEnabled) {
      return Icons.refresh;
    }
    return Icons.schedule;
  }

  String _resendLabel({
    required BuildContext context,
    required bool isEnabled,
    required int seconds,
  }) {
    if (isEnabled) {
      return context.translate.authResendCode;
    }

    return '${context.translate.authResendAvailableIn} ${_formatSeconds(seconds)}';
  }
}

class _VerificationSection extends StatelessWidget {
  const _VerificationSection({
    required this.viewModel,
    required this.controller,
  });

  final CheckEmailViewModel viewModel;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: viewModel.verificationCompleted,
      builder: (context, completed, _) {
        if (completed) {
          return const _CompletionState();
        }

        return ValueListenableBuilder<bool>(
          valueListenable: viewModel.isVerifying,
          builder: (context, isVerifying, _) {
            return ValueListenableBuilder<String?>(
              valueListenable: viewModel.codeError,
              builder: (context, error, _) {
                return _CodeVerificationForm(
                  controller: controller,
                  isVerifying: isVerifying,
                  error: error,
                  onVerify: () => viewModel.verifyCode(controller.text),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CodeVerificationForm extends StatelessWidget {
  const _CodeVerificationForm({
    required this.controller,
    required this.isVerifying,
    required this.error,
    required this.onVerify,
  });

  final TextEditingController controller;
  final bool isVerifying;
  final String? error;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final textTheme = context.theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.translate.authCodeFieldLabel.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: kitColors.white40,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: context.spacing.sm),
        TextField(
          key: WidgetKeys.authCodeField,
          controller: controller,
          enabled: !isVerifying,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onSubmitted: (_) => onVerify(),
          style: textTheme.headlineSmall?.copyWith(
            color: kitColors.white90,
            letterSpacing: 0,
          ),
          cursorColor: kitColors.brandSky,
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
            errorText: error,
            hintStyle: textTheme.headlineSmall?.copyWith(
              color: kitColors.white20,
              letterSpacing: 0,
            ),
            prefixIcon: Icon(
              Icons.pin_outlined,
              color: kitColors.white30,
              size: 18,
            ),
            filled: true,
            fillColor: kitColors.white02,
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.spacing.md,
              vertical: context.spacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: context.borderRadius.xxl,
              borderSide: BorderSide(color: kitColors.white10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: context.borderRadius.xxl,
              borderSide: BorderSide(color: kitColors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: context.borderRadius.xxl,
              borderSide: BorderSide(
                color: kitColors.brandSky.withValues(alpha: 0.5),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: context.borderRadius.xxl,
              borderSide: BorderSide(
                color: kitColors.red400.withValues(alpha: 0.6),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: context.borderRadius.xxl,
              borderSide: BorderSide(
                color: kitColors.red400.withValues(alpha: 0.8),
              ),
            ),
            errorStyle: textTheme.bodySmall?.copyWith(
              color: kitColors.red300,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(height: context.spacing.lg),
        AppPrimaryCta(
          key: WidgetKeys.authVerifyButton,
          label: context.translate.authVerifyCode,
          onPressed: onVerify,
          enabled: !isVerifying,
          loading: isVerifying,
        ),
      ],
    );
  }
}

class _CompletionState extends StatelessWidget {
  const _CompletionState();

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;

    return Column(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: kitColors.brandSky,
            strokeWidth: 2,
          ),
        ),
        SizedBox(height: context.spacing.md),
        Text(
          context.translate.authCompletingSignIn,
          style: context.theme.textTheme.bodyMedium?.copyWith(
            color: kitColors.white60,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
