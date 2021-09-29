import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_calculator/src/widgets/math_box.dart';
import 'package:app_calculator/src/widgets/result.dart';
import 'package:app_calculator/src/widgets/keyboard.dart';
import 'package:app_calculator/src/backend/math_model.dart';
import 'package:app_calculator/src/pages/setting_page.dart';

String testInitialAdId = "ca-app-pub-3940256099942544/1033173712";
String testBannerAdId = "ca-app-pub-3940256099942544/6300978111";

String initialAdId = "";
String bannerAdId = "";


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (kReleaseMode) { // is Release Mode ??
    final adCollectionReference = FirebaseFirestore.instance
        .collection("ad_id").doc("ySiKuE840qZ9zWtmEDNv");
    var value = await adCollectionReference.get();
    initialAdId = value.data()?['initialAdId'];
    bannerAdId = value.data()?['bannerAdId'];
  } else {
    initialAdId = testInitialAdId;
    bannerAdId = testBannerAdId;
  }

  MobileAds.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );
    return MultiProvider(
      providers: [
        Provider(create: (context) => MathBoxController()),
        ChangeNotifierProvider(create: (_) => SettingModel()),
        ChangeNotifierProxyProvider<SettingModel, MathModel>(
          create: (context) => MathModel(),
          update: (context, settings, model) => model!
            ..changeSetting(
                precision: settings.precision.toInt(),
                isRadMode: settings.isRadMode),
        ),
        ChangeNotifierProxyProvider<SettingModel, MatrixModel>(
          create: (context) => MatrixModel(),
          update: (context, settings, model) => model!
            ..changeSetting(
              precision: settings.precision.toInt(),
            ),
        ),
        Provider(create: (context) => FunctionModel()),
        ListenableProxyProvider<SettingModel, CalculationMode>(
          create: (context) => CalculationMode(Mode.Basic),
          update: (context, settings, model) {
            return model!;
          },
          dispose: (context, value) => value.dispose(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'handy calculator',
        theme: ThemeData(
          primarySwatch: Colors.brown,
          canvasColor: Colors.white,
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {



  // 시작 광고
  InterstitialAd? interstitialAd;
  bool isLoaded= false;

  final BannerAd myBanner = BannerAd(
    adUnitId: bannerAdId,
    size: AdSize.fullBanner,
    request: const AdRequest(),
    listener: const BannerAdListener(),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  final Server _server = Server();

  void doSomeAsyncStuff() async {

  }

  @override
  void initState() {
    super.initState();
    _server.start();
    doSomeAsyncStuff();


    InterstitialAd.load(adUnitId: initialAdId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            setState(() {
              isLoaded=true;
              interstitialAd=ad;
              interstitialAd!.show();
            });
          },
          onAdFailedToLoad: (error) {
          },
        ));

    myBanner.load();
  }

  @override
  void dispose() {
    _server.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


    final AdWidget adWidget = AdWidget(ad: myBanner);

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.cogs,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingPage(adWidget)),
            );
          },
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(
          //     FontAwesomeIcons.save,
          //     color: Colors.black,
          //   ),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => SettingPage(adWidget)),
          //     );
          //   },
          // ),
          // IconButton(
          //   icon: const Icon(
          //     FontAwesomeIcons.hdd,
          //     color: Colors.black,
          //   ),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => SettingPage(adWidget)),
          //     );
          //   },
          // ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: const <Widget>[
                MathBox(),
                SlidComponent(),
              ],
            ),
          ),
          const MathKeyBoard(),
          const Padding(padding: EdgeInsets.only(bottom:40)),
        ],
      ),
    );
  }
}

class SlidComponent extends StatelessWidget {
  const SlidComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Consumer<CalculationMode>(
          builder: (context, mathMode, _) {
            switch (mathMode.value) {
              case Mode.Basic:
                return Result();
              default:
                throw 'Error';
            }
          },
        ),
        Consumer<CalculationMode>(
          builder: (context, mathMode, _) => mathMode.value != Mode.Matrix
              ? const ExpandKeyBoard()
              : const SizedBox(
            height: 0.0,
          ),
        ),
      ],
    );
  }
}
