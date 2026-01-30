import 'package:neurostack/paywall/data/revenuecat_service.dart';
import 'package:neurostack/paywall/domain/entitlement_snapshot.dart';

/// ViewModel for PaywallView.
///
/// Delegates paywall presentation to [RevenueCatService].
/// Navigation is handled by the view after paywall closes.
class PaywallViewModel {
  PaywallViewModel({required RevenueCatService revenueCatService})
      : _revenueCatService = revenueCatService;

  final RevenueCatService _revenueCatService;

  /// Presents the RevenueCat paywall and returns the outcome.
  ///
  /// Returns [PaywallOutcome.purchased] if user completed a purchase,
  /// [PaywallOutcome.cancelled] if user dismissed without purchasing,
  /// or [PaywallOutcome.error] if presentation failed.
  Future<PaywallOutcome> presentPaywall() {
    return _revenueCatService.presentPaywall();
  }
}
