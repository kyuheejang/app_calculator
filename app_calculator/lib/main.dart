import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:app_calculator/src/widgets/math_box.dart';
import 'package:app_calculator/src/widgets/result.dart';
import 'package:app_calculator/src/widgets/matrixbutton.dart';
import 'package:app_calculator/src/widgets/keyboard.dart';
import 'package:app_calculator/src/backend/math_model.dart';
import 'package:app_calculator/src/pages/setting_page.dart';
import 'package:app_calculator/src/pages/functionpage.dart';


final String TestInitialAdId = "ca-app-pub-3940256099942544/1033173712";
final String TestBannerAdId = "ca-app-pub-3940256099942544/6300978111";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
            if (settings.loading.isCompleted) {
              switch (settings.initPage) {
                case 0:
                  if (model!.value == Mode.Matrix) {
                    model.value = Mode.Basic;
                  }
                  break;
                case 1:
                  model!.changeMode(Mode.Matrix);
                  break;
              }
            }
            return model!;
          },
          dispose: (context, value) => value.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'handy calculator',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          canvasColor: Colors.white,
        ),
        home: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {

  // 시작 광고
  InterstitialAd? interstitialAd;
  bool isLoaded= false;

  // 배너 광고
  final BannerAd myBanner = BannerAd(
    adUnitId: TestBannerAdId,
    size: AdSize.fullBanner,
    request: const AdRequest(),
    listener: const BannerAdListener(),
  );


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  final Server _server = Server();
  late TabController tabController;
  List tabs = ["Basic", "Matrix"];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: tabs.length, vsync: this);
    _server.start();

    InterstitialAd.load(adUnitId: TestInitialAdId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            setState(() {
              isLoaded=true;
              interstitialAd=ad;
              interstitialAd!.show();
            });
          },
          onAdFailedToLoad: (error) {
            // Do nothing on failed to load
            print("Interstitial Failed to load");
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
    final mode = Provider.of<CalculationMode>(context, listen: false);
    final mathBoxController =
    Provider.of<MathBoxController>(context, listen: false);
    final setting = Provider.of<SettingModel>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        brightness: Brightness.light,
        leading: IconButton(
          icon: const Icon(
            MaterialCommunityIcons.settings_outline,
            color: Colors.grey,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingPage(adWidget)),
            );
          },
        ),
        title: FutureBuilder(
          future: setting.loading.future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              tabController.index = setting.initPage;
            }
            return TabBar(
              indicatorColor: Colors.blueAccent[400],
              controller: tabController,
              labelColor: Colors.black,
              indicator: BoxDecoration(
                border: Border.all(
                  color: Colors.blueAccent,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
              tabs: const <Widget>[
                Tab(text: 'Basic'),
                Tab(text: 'Matrix'),
              ],
              onTap: (index) {
                setting.changeInitpage(index);
                switch (index) {
                  case 0:
                    if (mode.value == Mode.Matrix) {
                      mode.value = Mode.Basic;
                      mathBoxController.deleteAllExpression();
                    }
                    break;
                  case 1:
                    if (mode.value != Mode.Matrix) {
                      mode.value = Mode.Matrix;
                      mathBoxController.deleteAllExpression();
                      mathBoxController.addExpression('\\\\bmatrix');
                    }
                    break;
                  default:
                    throw 'Unknown type';
                }
              },
            );
          },
        ),
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
          MathKeyBoard(),
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
                break;
              case Mode.Matrix:
                return MatrixButton();
                break;
              case Mode.Function:
                return OutlinedButton(
                  child: const Text('Analyze'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FunctionPage()),
                    );
                  },
                );
                break;
              default:
                throw 'Error';
            }
          },
        ),
        Consumer<CalculationMode>(
          builder: (context, mathMode, _) => mathMode.value != Mode.Matrix
              ? ExpandKeyBoard()
              : const SizedBox(
            height: 0.0,
          ),
        ),
      ],
    );
  }
}
