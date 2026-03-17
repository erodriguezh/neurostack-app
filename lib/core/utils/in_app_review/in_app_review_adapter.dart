import 'package:in_app_review/in_app_review.dart';

/// Test seam for the `in_app_review` plugin.
///
/// The static [InAppReview.instance] singleton is not directly mockable.
/// This adapter wraps its API so that [InAppReviewService] can be fully
/// unit-tested via a mock implementation.
abstract class InAppReviewAdapter {
  Future<bool> isAvailable();
  Future<void> requestReview();
  Future<void> openStoreListing({String? appStoreId});
}

/// Default implementation that delegates to [InAppReview.instance].
class DefaultInAppReviewAdapter implements InAppReviewAdapter {
  final InAppReview _instance = InAppReview.instance;

  @override
  Future<bool> isAvailable() => _instance.isAvailable();

  @override
  Future<void> requestReview() => _instance.requestReview();

  @override
  Future<void> openStoreListing({String? appStoreId}) =>
      _instance.openStoreListing(appStoreId: appStoreId);
}
