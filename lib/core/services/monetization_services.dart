/// Integration seams only. The offline editor never depends on an SDK, account,
/// or purchase state. A future RevenueCat/AdMob adapter can implement these.
abstract class SubscriptionService {
  bool get isPremium;
  Future<bool> restorePurchases();
}

class DisabledSubscriptionService implements SubscriptionService {
  @override
  bool get isPremium => false;

  @override
  Future<bool> restorePurchases() async => false;
}

abstract class AdsService {
  bool get isAvailable;
  Future<void> showCreationCompletePlacement();
}

class DisabledAdsService implements AdsService {
  @override
  bool get isAvailable => false;

  @override
  Future<void> showCreationCompletePlacement() async {}
}
