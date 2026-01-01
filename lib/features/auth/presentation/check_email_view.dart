import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/utils/data_source/data_source_abstraction.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/l10n/translate_extension.dart';
import 'package:neurostack/core/utils/navigation/navigation_intent_store.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/features/auth/presentation/check_email_view_model.dart';

class CheckEmailView extends StatefulWidget {
  const CheckEmailView({super.key});

  @override
  State<CheckEmailView> createState() => _CheckEmailViewState();
}

class _CheckEmailViewState extends State<CheckEmailView> {
  late final CheckEmailViewModel _viewModel;

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
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _viewModel.changeEmail,
        ),
        title: Text(context.translate.checkEmailTitle),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.translate.checkEmailInstruction,
              style: context.textStyles.standard,
            ),
            SizedBox(height: context.spacing.md),
            ValueListenableBuilder<String?>(
              valueListenable: _viewModel.email,
              builder: (context, value, _) {
                final displayEmail = value ?? context.translate.authMissingEmail;
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(context.spacing.md),
                  decoration: BoxDecoration(
                    color: context.theme.colorScheme.surfaceContainerHighest,
                    borderRadius: context.borderRadius.sm,
                  ),
                  child: Text(
                    displayEmail,
                    style: context.textStyles.lg,
                  ),
                );
              },
            ),
            SizedBox(height: context.spacing.md),
            Text(
              context.translate.checkEmailSpamHint,
              style: context.textStyles.standard,
            ),
            SizedBox(height: context.spacing.lg),
            ValueListenableBuilder<int>(
              valueListenable: _viewModel.cooldownSeconds,
              builder: (context, seconds, _) {
                final isEnabled = _viewModel.canResend;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton(
                      onPressed: isEnabled ? _viewModel.resendMagicLink : null,
                      child: Text(context.translate.authResendLink),
                    ),
                    if (seconds > 0)
                      Padding(
                        padding: EdgeInsets.only(top: context.spacing.sm),
                        child: Text(
                          '${context.translate.authResendAvailableIn} ${_formatSeconds(seconds)}',
                          style: context.textStyles.standard,
                        ),
                      ),
                    SizedBox(height: context.spacing.md),
                    TextButton(
                      onPressed: _viewModel.changeEmail,
                      child: Text(context.translate.authChangeEmail),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatSeconds(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }
}
