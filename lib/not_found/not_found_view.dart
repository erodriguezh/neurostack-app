import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/l10n/translate_extension.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/not_found/not_found_view_model.dart';

class NotFoundView extends StatefulWidget {
  const NotFoundView({super.key});

  @override
  State<NotFoundView> createState() => _NotFoundViewState();
}

class _NotFoundViewState extends State<NotFoundView> {
  late final NotFoundViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = NotFoundViewModel(routerService: locator<RouterService>());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(context.spacing.xl),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                context.translate.notFoundTitle,
                style: context.textStyles.xxxl,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.md),
              Text(
                context.translate.notFoundMessage,
                style: context.textStyles.standard,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.xl),
              OutlinedButton(
                onPressed: _viewModel.navigateToHome,
                child: Text(context.translate.notFoundGoHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
