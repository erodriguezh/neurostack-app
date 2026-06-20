import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/curves.dart';
import 'package:neurostack/core/ui/constants/durations.dart';
import 'package:neurostack/core/ui/constants/widget_keys.dart';
import 'package:neurostack/core/utils/app_environment.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/l10n/translate_extension.dart';
import 'package:neurostack/core/utils/navigation/navigation_intent_store.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/presentation/auth_view_model.dart';
import 'package:neurostack/features/auth/presentation/widgets/auth_background.dart';
import 'package:neurostack/core/ui/widgets/app_primary_cta.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView>
    with SingleTickerProviderStateMixin {
  late final AuthViewModel _viewModel;
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _viewModel = AuthViewModel(
      navigationIntentStore: locator<NavigationIntentStore>(),
      routerService: locator<RouterService>(),
      notifyService: locator<NotifyService>(),
    );
    _entranceController = AnimationController(
      duration: CustomDurations.instance.duration500,
      vsync: this,
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: CustomCurves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: CustomCurves.easeOut,
          ),
        );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final textTheme = context.theme.textTheme;

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
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
                        SizedBox(height: context.spacing.xxl),
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: kitColors.brandSky.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            'assets/logo.svg',
                            width: 40,
                            height: 40,
                            colorFilter: ColorFilter.mode(
                              kitColors.brandSky,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        SizedBox(height: context.spacing.xl),
                        Text(
                          context.translate.authTitle,
                          style: textTheme.headlineLarge?.copyWith(
                            color: kitColors.white90,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: context.spacing.sm),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Text(
                            context.translate.authSubtitle,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w300,
                              color: kitColors.white50,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: context.spacing.xxl),
                        _MagicLinkAuth(
                          key: const ValueKey('auth_magic_link'),
                          redirectUrl: _redirectUrl(),
                          localization: const _MagicAuthLocalization(),
                          onMagicLinkSent: _viewModel.handleMagicLinkSent,
                          onError: _viewModel.handleAuthError,
                        ),
                        SizedBox(height: context.spacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _redirectUrl() {
    if (AppEnvironment.isDev) {
      return 'https://getneurostack.app/auth/callback?env=dev';
    }
    return 'https://getneurostack.app/auth/callback';
  }
}

class _MagicAuthLocalization {
  const _MagicAuthLocalization();

  String get enterEmail => 'Enter your email';
  String get validEmailError => 'Please enter a valid email address';
  String get continueWithMagicLink => 'Continue with magic Link';
}

class _MagicLinkAuth extends StatefulWidget {
  const _MagicLinkAuth({
    super.key,
    required this.onMagicLinkSent,
    this.onError,
    this.redirectUrl,
    this.localization = const _MagicAuthLocalization(),
  });

  final void Function(String email) onMagicLinkSent;
  final void Function(Object error)? onError;
  final String? redirectUrl;
  final _MagicAuthLocalization localization;

  @override
  State<_MagicLinkAuth> createState() => _MagicLinkAuthState();
}

class _MagicLinkAuthState extends State<_MagicLinkAuth> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _emailFocusNode = FocusNode();

  bool _isLoading = false;
  bool _hasText = false;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(_handleEmailChanged);
    _emailFocusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _email.removeListener(_handleEmailChanged);
    _emailFocusNode.removeListener(_handleFocusChanged);
    _email.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;
    final textTheme = context.theme.textTheme;
    final localization = widget.localization;
    final isEnabled = !_isLoading && _isValidEmail();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            localization.enterEmail.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: kitColors.white40,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: context.spacing.sm),
          AnimatedContainer(
            duration: context.durations.duration200,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: context.borderRadius.xxl,
              boxShadow: _emailFocusNode.hasFocus
                  ? [
                      BoxShadow(
                        color: kitColors.brandSky.withValues(alpha: 0.1),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : const [],
            ),
            child: TextFormField(
              key: WidgetKeys.authEmailField,
              controller: _email,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.send,
              autofillHints: const [AutofillHints.email],
              autovalidateMode: _showError
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
              validator: (_) {
                if (!_isValidEmail()) {
                  return localization.validEmailError;
                }
                return null;
              },
              onFieldSubmitted: (_) => _sendMagicLink(),
              style: textTheme.bodyLarge?.copyWith(
                color: kitColors.white90,
                fontWeight: FontWeight.w400,
              ),
              cursorColor: kitColors.brandSky,
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: kitColors.white30,
                ),
                prefixIcon: Icon(
                  Icons.email_outlined,
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
          ),
          SizedBox(height: context.spacing.lg),
          AppPrimaryCta(
            key: WidgetKeys.authSubmitButton,
            label: localization.continueWithMagicLink,
            onPressed: _sendMagicLink,
            enabled: isEnabled,
            loading: _isLoading,
          ),
          SizedBox(height: context.spacing.lg),
        ],
      ),
    );
  }

  void _handleEmailChanged() {
    final trimmed = _email.text.trim();
    final hasText = trimmed.isNotEmpty;
    final showError = hasText && !EmailValidator.validate(trimmed);
    if (hasText == _hasText && showError == _showError) {
      return;
    }
    setState(() {
      _hasText = hasText;
      _showError = showError;
    });
  }

  void _handleFocusChanged() {
    setState(() {});
  }

  bool _isValidEmail() {
    return EmailValidator.validate(_email.text.trim());
  }

  Future<void> _sendMagicLink() async {
    if (!_isValidEmail()) {
      setState(() {
        _showError = true;
      });
      _formKey.currentState?.validate();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _email.text.trim();
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: widget.redirectUrl,
      );
      if (mounted) {
        widget.onMagicLinkSent(email);
      }
    } on AuthException catch (error) {
      _handleSignInError(error, error.message);
    } catch (error) {
      _handleSignInError(error, 'Unexpected error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleSignInError(Object error, String fallbackMessage) {
    final onError = widget.onError;
    if (onError != null) {
      onError(error);
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(fallbackMessage)),
    );
  }
}
