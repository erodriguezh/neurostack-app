import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/constants/widget_keys.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';
import 'package:neurostack/core/utils/in_app_review/in_app_review_service.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/settings/rate_app_view_model.dart';

/// Rate App screen with primary ("Rate on App Store") and secondary
/// ("Quick Rating") CTAs.
///
/// Navigation: accessed via Settings "Rate the App" tile at `/settings/rate-app`.
/// Close button uses [RouterService.back], matching [ContactView].
class RateAppView extends StatefulWidget {
  const RateAppView({super.key});

  @override
  State<RateAppView> createState() => _RateAppViewState();
}

class _RateAppViewState extends State<RateAppView> {
  late final RateAppViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RateAppViewModel(
      inAppReviewService: locator<InAppReviewService>(),
      notifyService: locator<NotifyService>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semanticColors = context.semanticColors;
    final colorScheme = context.theme.colorScheme;
    final spacing = context.spacing;
    final textTheme = context.theme.textTheme;

    return AppGridBackground(
      mode: AppGridBackgroundMode.adaptive,
      child: Scaffold(
        key: WidgetKeys.rateAppScreen,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Close button row
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: spacing.sm,
                    right: spacing.sm,
                  ),
                  child: IconButton(
                    key: WidgetKeys.rateAppCloseButton,
                    icon: Icon(
                      Icons.close,
                      color: semanticColors.inkSubtle,
                    ),
                    onPressed: () => locator<RouterService>().back(),
                  ),
                ),
              ),

              // Body content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Logo — brandSky is the brand accent with no
                      // semantic equivalent; matches AuthView and SplashScreen.
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary
                                  .withValues(alpha: 0.2),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: SvgPicture.asset(
                          'assets/logo.svg',
                          key: WidgetKeys.rateAppLogo,
                          width: 48,
                          height: 48,
                          colorFilter: ColorFilter.mode(
                            colorScheme.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      SizedBox(height: spacing.xl),

                      // Title
                      Text(
                        'Enjoying Neurostack?',
                        style: textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing.md),

                      // Body text
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(
                          'Your feedback helps improve the app and reach more '
                          'people who can benefit from evidence-based wellness '
                          'protocols.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: semanticColors.inkSubtle,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Primary CTA: "Rate on App Store"
                      if (_viewModel.canOpenStoreListing)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: WidgetKeys.rateAppPrimaryCta,
                            onPressed: _viewModel.openStoreListing,
                            icon: const Icon(Icons.star_rounded, size: 18),
                            label: const Text('Rate on App Store'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: context.borderRadius.full,
                              ),
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              textStyle: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                key: WidgetKeys.rateAppPrimaryCta,
                                onPressed: null,
                                icon:
                                    const Icon(Icons.star_rounded, size: 18),
                                label: const Text('Rate on App Store'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: context.borderRadius.full,
                                  ),
                                  textStyle: textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: spacing.sm),
                            Text(
                              'Store rating not available on this platform',
                              style: textTheme.bodySmall?.copyWith(
                                color: semanticColors.inkSubtle,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                      SizedBox(height: spacing.md),

                      // Secondary CTA: "Quick Rating"
                      if (_viewModel.isServiceInitialized)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            key: WidgetKeys.rateAppSecondaryCta,
                            onPressed: _viewModel.requestReviewForScreen,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: context.borderRadius.full,
                              ),
                              side: BorderSide(
                                color: semanticColors.border,
                              ),
                              foregroundColor: semanticColors.ink,
                              textStyle: textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                            child: const Text('Quick Rating'),
                          ),
                        ),

                      SizedBox(height: spacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
