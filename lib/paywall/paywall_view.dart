import 'package:flutter/material.dart';
import 'package:neurostack/core/ui/app_theme.dart';
import 'package:neurostack/core/ui/widgets/app_grid_background.dart';
import 'package:neurostack/core/utils/internal_notification/notify_service.dart';
import 'package:neurostack/core/utils/internal_notification/toast/toast_event.dart';
import 'package:neurostack/core/utils/locator.dart';
import 'package:neurostack/core/utils/navigation/router_service.dart';
import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';
import 'package:neurostack/paywall/paywall_view_model.dart';

class PaywallView extends StatefulWidget {
  const PaywallView({super.key});

  @override
  State<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends State<PaywallView> {
  late final PaywallViewModel _viewModel = PaywallViewModel(
    revenueCatService: locator<RevenueCatService>(),
  );

  @override
  void initState() {
    super.initState();
    _presentPaywall();
  }

  Future<void> _presentPaywall() async {
    final outcome = await _viewModel.presentPaywall();
    if (!mounted) return;

    // Handle error case to prevent navigation loops.
    // Show a toast using NotifyService so it survives route pop.
    if (outcome == PaywallOutcome.error) {
      locator<NotifyService>().setToastEvent(
        ToastEventError(
          message: 'Unable to show upgrade options. Please try again later.',
        ),
      );
      // Brief delay ensures toast renders before navigation
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;

    // Always navigate back - let caller handle what happens next.
    // RouterService.back() is the correct method (no pop(result) API).
    locator<RouterService>().back();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while RevenueCat paywall is being presented.
    // The native paywall UI will appear on top of this.
    return AppGridBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(context.spacing.lg),
              child: const CircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }
}
