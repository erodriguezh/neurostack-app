import 'dart:async';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/utils/app_environment.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/l10n/translate_extension.dart';
import 'package:neurostack/core/utils/navigation/navigation_intent_store.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/presentation/auth_view_model.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  late final AuthViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AuthViewModel(
      navigationIntentStore: locator<NavigationIntentStore>(),
      routerService: locator<RouterService>(),
      notifyService: locator<NotifyService>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.translate.authTitle,
                style: context.textStyles.xxxl,
              ),
              SizedBox(height: context.spacing.sm),
              Text(
                context.translate.authSubtitle,
                style: context.textStyles.standard,
              ),
              SizedBox(height: context.spacing.xl),
              _MagicLinkAuth(
                key: const ValueKey('auth_magic_link'),
                redirectUrl: _redirectUrl(),
                localization: const SupaMagicAuthLocalization(),
                onSuccess: (_) {},
                onMagicLinkSent: _viewModel.handleMagicLinkSent,
                onError: _viewModel.handleAuthError,
              ),
            ],
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

class _MagicLinkAuth extends SupaMagicAuth {
  const _MagicLinkAuth({
    super.key,
    required super.onSuccess,
    required this.onMagicLinkSent,
    super.onError,
    super.redirectUrl,
    super.localization = const SupaMagicAuthLocalization(),
  });

  final void Function(String email) onMagicLinkSent;

  @override
  State<_MagicLinkAuth> createState() => _MagicLinkAuthState();
}

class _MagicLinkAuthState extends State<_MagicLinkAuth> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  late final StreamSubscription<AuthState> _gotrueSubscription;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _gotrueSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && mounted) {
        widget.onSuccess(session);
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _gotrueSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = widget.localization;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (value) {
              final email = _email.text.trim();
              if (value == null ||
                  value.isEmpty ||
                  !EmailValidator.validate(email)) {
                return localization.validEmailError;
              }
              return null;
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email),
              label: Text(localization.enterEmail),
            ),
            controller: _email,
          ),
          SizedBox(height: context.spacing.md),
          FilledButton(
            onPressed: _isLoading ? null : _sendMagicLink,
            child: _isLoading
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                      strokeWidth: 1.5,
                    ),
                  )
                : Text(
                    localization.continueWithMagicLink,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMagicLink() async {
    if (!_formKey.currentState!.validate()) {
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
      if (widget.onError == null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      } else {
        widget.onError?.call(error);
      }
    } catch (error) {
      if (widget.onError == null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: $error')),
        );
      } else {
        widget.onError?.call(error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
