import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Utility class that manages loading and showing app open ads.
class BannerAdManager {
  /// Maximum duration allowed between loading and showing the ad.
  final Duration maxCacheDuration = Duration(hours: 4);
  String adUnitId;
  BannerAdManager({required this.adUnitId});


  /// Load an [InterstitialAd].
  Future<BannerAd> loadAd() async {
    final BannerAd myBanner = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.fullBanner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );

    await myBanner.load();

    return myBanner;
  }
}