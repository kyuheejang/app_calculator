import 'dart:io';

import 'package:flutter/material.dart';
import 'package:csv_localizations/csv_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:translator/translator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_calculator/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:app_calculator/ad/banner_ad_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

String currentAppName = "handy scientific calculator";
String testInitialAdId = "ca-app-pub-3940256099942544/1033173712";
String testBannerAdId = "ca-app-pub-3940256099942544/6300978111";

class Apps {
  String appName;
  String appDescription;
  String icon;
  String appLink;

  Apps({
    required this.appName,
    required this.appDescription,
    required this.icon,
    required this.appLink});
}

List<dynamic> appNames = [];
List<dynamic> appDescriptions = [];
List<dynamic> appIcons = [];
List<dynamic> appLinks = [];

List<Apps> appInfos = [];

class MoreApps extends StatefulWidget {
  BannerAd moreAppsBanner;
  MoreApps({required this.moreAppsBanner});
  @override
  _MoreAppsState createState() => _MoreAppsState();
}

class _MoreAppsState extends State<MoreApps> {
  @override
  void initState() {
    super.initState();
    initiateValues();
  }

  void _launchURL(url) async =>
      await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';

  void initiateValues() async {
    final adCollectionReference = FirebaseFirestore.instance
        .collection("more_apps").doc("bApkCbdnwJKRqHvdpSRn");

    var value = await adCollectionReference.get();
    if (Platform.isAndroid) {
      appNames = value.data()?['appname_android'];
      appDescriptions = value.data()?['description_android'];
      appIcons = value.data()?['icon_android'];
      appLinks = value.data()?['applink_android'];
    } else {
      appNames = value.data()?['appname_ios'];
      appDescriptions = value.data()?['description_ios'];
      appIcons = value.data()?['icon_ios'];
      appLinks = value.data()?['applink_ios'];
    }
    Locale myLocale = Localizations.localeOf(context);
    String languageCode = myLocale.languageCode;


    for(int i=0; i < appNames.length; i++) {
      if (appNames[i] == currentAppName) {
        continue;
      }
      final translator = GoogleTranslator();
      var appName = await translator.translate(appNames[i], to: languageCode);
      var appDescription = await translator.translate(appDescriptions[i], to: languageCode);
      setState(() {
        appInfos.add(
            Apps(
                appName: appName.text,
                appDescription: appDescription.text,
                icon: appIcons[i],
                appLink: appLinks[i]
            )
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(15.0),
        child: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: appInfos.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  onTap: () {
                    _launchURL(appInfos[index].appLink);
                  },
                  contentPadding: EdgeInsets.all(5),
                  leading: Container(
                    height: 60,
                    width: 60,
                    child: Image.network(appInfos[index].icon)
                  ),
                  title: Text('${appInfos[index].appName}'),
                  subtitle: Text('${appInfos[index].appDescription}'),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return CustomDivider();
              },
            ),
          ),
          Container(
            height: 30,
          ),
          Container(
              height: 250,
              child: AdWidget(ad: widget.moreAppsBanner)
          )
        ],
      ),
    );
  }
}
