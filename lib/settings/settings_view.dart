import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/settings/settings_view_model.dart';

/// Settings view providing user account actions.
///
/// Currently includes:
/// - Restore Purchases: Critical for subscription correctness after device
///   change, app reinstall, or family sharing setup.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final SettingsViewModel _viewModel = SettingsViewModel(
    revenueCatService: locator<RevenueCatService>(),
  );

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final kitColors = context.kitColors;

    return AppGridBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header with back button
              SliverToBoxAdapter(
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
                          color: kitColors.white90,
                        ),
                        onPressed: () => locator<RouterService>().back(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Settings',
                        style: context.theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 32,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -0.8,
                          color: kitColors.white90,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: spacing.lg)),

              // Settings list
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: kitColors.panel,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kitColors.white10),
                    ),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _viewModel.isRestoring,
                      builder: (context, isRestoring, child) {
                        return _RestorePurchasesTile(
                          isRestoring: isRestoring,
                          onTap: () => _handleRestorePurchases(context),
                        );
                      },
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

  Future<void> _handleRestorePurchases(BuildContext context) async {
    // Capture messenger before async gap
    final messenger = ScaffoldMessenger.of(context);
    final success = await _viewModel.restorePurchases();
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Purchases restored successfully')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to restore purchases. Try again later.'),
        ),
      );
    }
  }
}

class _RestorePurchasesTile extends StatelessWidget {
  const _RestorePurchasesTile({
    required this.isRestoring,
    required this.onTap,
  });

  final bool isRestoring;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kitColors = context.kitColors;

    return ListTile(
      leading: isRestoring
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(kitColors.white60),
              ),
            )
          : Icon(LucideIcons.rotateCcw, color: kitColors.white60),
      title: Text(
        'Restore Purchases',
        style: context.theme.textTheme.bodyLarge?.copyWith(
          color: kitColors.white90,
        ),
      ),
      subtitle: Text(
        'Recover purchases from another device',
        style: context.theme.textTheme.bodySmall?.copyWith(
          color: kitColors.white40,
        ),
      ),
      enabled: !isRestoring,
      onTap: isRestoring ? null : onTap,
    );
  }
}
