
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String testAndBannerAdId = "ca-app-pub-3940256099942544/6300978111";
String testIosBannerAdId = "ca-app-pub-3940256099942544/2934735716";
String testBannerAdId = "";

class AdmobBannerAd {

  late String addId;
  late String bannerName;
  late BannerAd bannerAd;
  late AdSize adSize;


  AdmobBannerAd(String bannerName, this.adSize) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      this.bannerName = 'ios$bannerName';
      testBannerAdId = testIosBannerAdId;
    } else {
      this.bannerName = 'and$bannerName';
      testBannerAdId = testAndBannerAdId;
    }
  }

  Future getBannerAd() async {
    if (kReleaseMode) {
      final adCollectionReference = FirebaseFirestore.instance
          .collection("ad_id").doc("ySiKuE840qZ9zWtmEDNv");
      var value = await adCollectionReference.get();
      addId = value.data()?[bannerName];
    } else {
      addId = testBannerAdId;
    }

    bannerAd = BannerAd(
      adUnitId: addId,
      size: adSize,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );

    bannerAd.load();

    return bannerAd;
  }
}






