import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';

/// Contact Us page with a back button and screen title.
class ContactView extends StatelessWidget {
  const ContactView({super.key});

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.semanticColors;
    final spacing = context.spacing;

    return AppGridBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.sm,
              spacing.sm,
              spacing.lg,
              0,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    LucideIcons.chevronLeft,
                    color: semanticColors.ink,
                  ),
                  onPressed: () => locator<RouterService>().back(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Contact Us',
                  style: context.theme.textTheme.headlineLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
