import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/library/library_view_model.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  late final LibraryViewModel _viewModel = LibraryViewModel(
    routerService: locator<RouterService>(),
  );

  @override
  Widget build(BuildContext context) {
    return AppGridBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(context.spacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Library',
                    style: context.theme.textTheme.headlineLarge,
                  ),
                  SizedBox(height: context.spacing.sm),
                  Text(
                    'Library browsing is coming soon.',
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: context.kitColors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: context.spacing.lg),
                  OutlinedButton(
                    onPressed: _viewModel.navigateToHome,
                    child: const Text('Back to Stack'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
