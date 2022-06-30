import 'dart:async';

import 'package:app_calculator/ad/admob_opening_ad.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter/material.dart';

class AppLifecycleReactor extends WidgetsBindingObserver {
  AppOpenAdManager appOpenAdManager = AppOpenAdManager();

  AppLifecycleReactor({required this.appOpenAdManager});
  late StreamSubscription<FGBGType> subscription;

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // Try to show an app open ad if the app is being resumed and
    // we're not already showing an app open ad.
   subscription = FGBGEvents.stream.listen((event) {
      if (event == FGBGType.foreground) {
        appOpenAdManager.showAdIfAvailable();
      }
    });
  }
}