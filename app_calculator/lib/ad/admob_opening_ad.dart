
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AppOpenAdManager {

  String testOpeningAdId = "";
  String testAndOpeningAdId = "ca-app-pub-3940256099942544/3419835294";
  String testIosOpeningAdId = "ca-app-pub-3940256099942544/5662855259";

  late String addId;
  String adName = "Opening";

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isInit = false;

  /// Maximum duration allowed between loading and showing the ad.
  final Duration maxCacheDuration = Duration(hours: 4);

  /// Keep track of load time so we don't show an expired ad.
  DateTime? _appOpenLoadTime;

  AppOpenAdManager() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      adName = 'ios$adName';
      testOpeningAdId = testIosOpeningAdId;
    } else {
      adName = 'and$adName';
      testOpeningAdId = testAndOpeningAdId;
    }
  }

  Future initializeOpeningAd() async {
    if (!_isInit) {
      if (kReleaseMode) {
        final adCollectionReference = FirebaseFirestore.instance
            .collection("ad_id").doc("ySiKuE840qZ9zWtmEDNv");
        var value = await adCollectionReference.get();
        addId = value.data()?[adName];
      } else {
        addId = testOpeningAdId;
      }
      _isInit = true;
    }
  }

  void loadAd() {
    AppOpenAd.load(
      adUnitId: addId,
      orientation: AppOpenAd.orientationPortrait,
      request: AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          print('AppOpenAd failed to load: $error');
          // Handle the error.
        },
      ),
    );
  }

  AppOpenAd? getInterstitialAd() {
    return _appOpenAd;
  }

  bool get isAdAvailable {
    return _appOpenAd != null;
  }

  void showAdIfAvailable() {
    if (!_isInit) {
      return;
    }
    if (!isAdAvailable) {
      print('Tried to show ad before available.');
      loadAd();
      return;
    }
    if (_isShowingAd) {
      print('Tried to show ad while already showing an ad.');
      return;
    }

    if (DateTime.now().subtract(maxCacheDuration).isAfter(_appOpenLoadTime!)) {
      print('Maximum cache duration exceeded. Loading another ad.');
      _appOpenAd!.dispose();
      _appOpenAd = null;
      loadAd();
      return;
    }
    // Set the fullScreenContentCallback and show the ad.
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        print('$ad onAdShowedFullScreenContent');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        print('$ad onAdDismissedFullScreenContent');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );
    _appOpenAd!.show();
  }
}






