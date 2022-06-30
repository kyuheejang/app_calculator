
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdmobInterstitialAd {
  String testInitialAdId = "";
  String testAndInitialAdId = "ca-app-pub-3940256099942544/1033173712";
  String testIosInitialAdId = "ca-app-pub-3940256099942544/4411468910";

  late String addId;
  late String interstitialName;
  InterstitialAd? interstitialAd;


  AdmobInterstitialAd(String interstitialName) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      this.interstitialName = 'ios$interstitialName';
      testInitialAdId = testIosInitialAdId;
    } else {
      this.interstitialName = 'and$interstitialName';
      testInitialAdId = testAndInitialAdId;
    }
  }

  Future initializeInterstitialAd() async {
    if (kReleaseMode) {
      final adCollectionReference = FirebaseFirestore.instance
          .collection("ad_id").doc("ySiKuE840qZ9zWtmEDNv");
      var value = await adCollectionReference.get();
      addId = value.data()?[interstitialName];
    } else {
      addId = testInitialAdId;
    }

    InterstitialAd.load(adUnitId: addId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd=ad;

            interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (InterstitialAd ad) =>
                  print('$ad onAdShowedFullScreenContent.'),
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                print('$ad onAdDismissedFullScreenContent.');
                ad.dispose();
                interstitialAd = null;
              },
              onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
                print('$ad onAdFailedToShowFullScreenContent: $error');
                ad.dispose();
                interstitialAd = null;
              },
              onAdImpression: (InterstitialAd ad) => print('$ad impression occurred.'),
            );
          },
          onAdFailedToLoad: (error) {
            if (kDebugMode) {
              print(error);
            }
            interstitialAd=null;
          },
        ));
  }

  InterstitialAd? getInterstitialAd() {
    return interstitialAd;
  }
}






