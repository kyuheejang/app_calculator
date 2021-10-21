import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_calculator/src/pages/setting_page.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter_icons/flutter_icons.dart';

import 'package:app_calculator/src/widgets/math_box.dart';
import 'package:app_calculator/src/widgets/result.dart';
import 'package:app_calculator/src/widgets/keyboard.dart';
import 'package:app_calculator/src/backend/math_model.dart';
import 'package:csv_localizations/csv_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


String testInitialAdId = "ca-app-pub-3940256099942544/1033173712";
String testBannerAdId = "ca-app-pub-3940256099942544/6300978111";

String formulaSaveInterAdId = "";
String settingBannerAdId = "";
String endBannerAdId = "";
String historyBannerAdId = "";
String mainBannerAdId = "";

int functionColorIndex = 0;
int numberColorIndex = 0;
Color functionBackgroundColor = Colors.black87;
Color numberBackgroundColor = Colors.black87;
late SharedPreferences prefs;

class PushNotification {
  PushNotification({
    this.title,
    this.body,
  });
  String? title;
  String? body;
}

// 수식 save 광고
InterstitialAd? saveInterAd;

final BannerAd mainBanner = BannerAd(
  adUnitId: mainBannerAdId,
  size: AdSize.banner,
  request: const AdRequest(),
  listener: const BannerAdListener(),
);

final BannerAd settingBanner = BannerAd(
  adUnitId: settingBannerAdId,
  size: AdSize.mediumRectangle,
  request: const AdRequest(),
  listener: const BannerAdListener(),
);

final BannerAd endBanner = BannerAd(
  adUnitId: endBannerAdId,
  size: AdSize.mediumRectangle,
  request: const AdRequest(),
  listener: const BannerAdListener(),
);

final BannerAd historyBanner = BannerAd(
  adUnitId: settingBannerAdId,
  size: AdSize.banner,
  request: const AdRequest(),
  listener: const BannerAdListener(),
);


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final status = await AppTrackingTransparency.requestTrackingAuthorization();

  await Firebase.initializeApp();
  prefs = await SharedPreferences.getInstance();


  if (kReleaseMode) { // is Release Mode ??
    final adCollectionReference = FirebaseFirestore.instance
        .collection("ad_id").doc("ySiKuE840qZ9zWtmEDNv");
    var value = await adCollectionReference.get();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      mainBannerAdId = value.data()?['iosMainBanner'];
      settingBannerAdId = value.data()?['iosSettingBanner'];
      formulaSaveInterAdId = value.data()?['iosFormulaSaveInter'];
      endBannerAdId = value.data()?['iosEndBanner'];
      historyBannerAdId = value.data()?['iosHistoryBanner'];
    } else {
      mainBannerAdId = value.data()?['andMainBanner'];
      settingBannerAdId = value.data()?['andSettingBanner'];
      formulaSaveInterAdId = value.data()?['andFormulaSaveInter'];
      endBannerAdId = value.data()?['andEndBanner'];
      historyBannerAdId = value.data()?['andHistoryBanner'];
    }
  } else {
    mainBannerAdId = testBannerAdId;
    formulaSaveInterAdId = testInitialAdId;
    settingBannerAdId = testBannerAdId;
    endBannerAdId = testBannerAdId;
    historyBannerAdId = testBannerAdId;
  }

  await MobileAds.instance.initialize();
  await MobileAds.instance.setAppMuted(true);

  mainBanner.load();
  settingBanner.load();
  endBanner.load();
  historyBanner.load();


  await InterstitialAd.load(adUnitId: formulaSaveInterAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          saveInterAd=ad;
        },
        onAdFailedToLoad: (error) {
          saveInterAd = null;
        },
      ));

  saveInterAd?.fullScreenContentCallback = FullScreenContentCallback(
    onAdShowedFullScreenContent: (InterstitialAd ad) =>
        print('$ad onAdShowedFullScreenContent.'),
    onAdDismissedFullScreenContent: (InterstitialAd ad) {
      print('$ad onAdDismissedFullScreenContent.');
      ad.dispose();
    },
    onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
      print('$ad onAdFailedToShowFullScreenContent: $error');
      ad.dispose();
    },
    onAdImpression: (InterstitialAd ad) => print('$ad impression occurred.'),
  );

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
        localizationsDelegates: const [
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          CsvLocalizationsDelegate('assets/localization_calculator.csv'),
        ],
        supportedLocales: const [
          Locale('en'), Locale('gl'), Locale('gu'), Locale('el'), Locale('nl'),
          Locale('ne'), Locale('no'), Locale('da'), Locale('de'), Locale('lo'),
          Locale('lv'), Locale('ru'), Locale('ro'), Locale('lt'), Locale('mr'),
          Locale('mk'), Locale('ml'), Locale('ms'), Locale('mn'), Locale('eu'),
          Locale('my'), Locale('vi'), Locale('be'), Locale('bn'), Locale('bg'),
          Locale('sr'), Locale('sw'), Locale('sv'), Locale('es'), Locale('sk'),
          Locale('sl'), Locale('si'), Locale('ar'), Locale('hy'), Locale('is'),
          Locale('az'), Locale('af'), Locale('sq'), Locale('am'), Locale('et'),
          Locale('en'), Locale('ur'), Locale('uk'), Locale('it'), Locale('id'),
          Locale('ja'), Locale('ka'), Locale('zu'), Locale('zh', 'CN'), Locale('zh', 'TW'),
          Locale('cs'), Locale('kk'), Locale('ca'), Locale('kn'), Locale('hr'),
          Locale('km'), Locale('ky'), Locale('ta'), Locale('th'), Locale('tr'),
          Locale('te'), Locale('pa'), Locale('fa'), Locale('pt'), Locale('pl'),
          Locale('fr'), Locale('fi'), Locale('fil'), Locale('ko'), Locale('hu'),
          Locale('iw'), Locale('hi'),
        ],
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


  bool isLoaded= false;

  // push
  late final FirebaseMessaging _messaging;

  void registerNotification() async {
    // 1. Initialize the Firebase app
    await Firebase.initializeApp();

    // 2. Instantiate Firebase Messaging
    _messaging = FirebaseMessaging.instance;

    // 3. On iOS, this helps to take the user permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );


    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // For handling the received notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Parse the message received
        PushNotification notification = PushNotification(
          title: message.notification?.title,
          body: message.notification?.body,
        );
      });
    } else {
    print('User declined or has not accepted permission');
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }


  Future _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  final Server _server = Server();

  final TextEditingController _textFieldController = TextEditingController();

  Future<void> _displayTextInputDialog(BuildContext context) async {

    if (saveInterAd != null) {
      await saveInterAd!.show();
    }

    String saveName = "";

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(CsvLocalizations.instance.string('formula_name')),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)
            ),
            content: TextField(
              controller: TextEditingController(text: ""),
              onChanged: (value) {
                setState(() {
                  saveName = value;
                });
              },
              decoration: const InputDecoration(hintText: ""),
            ),
            actions: <Widget>[
              FlatButton(
                color: Colors.green,
                textColor: Colors.white,
                child: Text(CsvLocalizations.instance.string('ok')),
                onPressed: () {
                  setState(() {
                    // mathModelList를 불러와서 리스트에 삽입한다.
                    final mathModel = Provider.of<MathModel>(context, listen: false);
                    final mathBoxController = Provider.of<MathBoxController>(context, listen:false);
                    List<String> expressionList = prefs.getStringList('expressionList') ?? [];
                    List<String> resultList = prefs.getStringList('resultList') ?? [];
                    List<String> mathModelNameList = prefs.getStringList('mathModelNameList') ?? [];
                    List<String> mathBoxList = prefs.getStringList('mathBoxList') ?? [];
                    if (saveName == "") {
                      return _showDialog(
                          CsvLocalizations.instance.string('error'),
                          CsvLocalizations.instance.string('please_specify')
                      );
                    }

                    if (mathModelNameList.length > 10) {
                      Navigator.pop(context);
                      _showDialog(
                        CsvLocalizations.instance.string('error'),
                        CsvLocalizations.instance.string('cannot_store'),
                      );
                    }

                    // 수식이랑 수식 이름 저장
                    mathModelNameList.add(saveName);
                    expressionList.add(mathModel.getExpression());
                    resultList.add(mathModel.getResult());
                    mathBoxList.add(mathBoxController.encodeMathBoxHistory());
                    prefs.setStringList("mathModelNameList", mathModelNameList);
                    prefs.setStringList("expressionList", expressionList);
                    prefs.setStringList("resultList", resultList);
                    prefs.setStringList("mathBoxList", mathBoxList);
                    _textFieldController.clear();
                    Navigator.pop(context);
                    _showDialog(
                      CsvLocalizations.instance.string('success'),
                      CsvLocalizations.instance.string('formula_saved'),
                    );
                  });
                },
              ),
              FlatButton(
                color: Colors.red,
                textColor: Colors.white,
                child: Text(CsvLocalizations.instance.string('cancel')),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
      });
  }

  void _showDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text(title),
          content: new Text(body),
          actions: <Widget>[
            new FlatButton(
              child:Text(CsvLocalizations.instance.string('close')),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget formulaHistoryList() {
    List<String> expressionList = prefs.getStringList('expressionList') ?? [];
    List<String> resultList = prefs.getStringList('resultList') ?? [];
    List<String> mathModelNameList = prefs.getStringList('mathModelNameList') ?? [];
    List<String> mathBoxList = prefs.getStringList('mathBoxList') ?? [];

    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: mathModelNameList.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child:  ListTile(
            title: Text(mathModelNameList[index]),
            trailing: SizedBox(
              width: 100,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.download,
                      color: Colors.blue,),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(CsvLocalizations.instance.string('alert')),
                            content: Text(CsvLocalizations.instance.string('load_this')),
                            actions: <Widget>[
                              FlatButton(
                                color: Colors.green,
                                textColor: Colors.white,
                                child: Text(CsvLocalizations.instance.string('ok')),
                                onPressed: () {
                                  setState(() {
                                    final mathModel = Provider.of<MathModel>(context, listen: false);
                                    mathModel.updateExpression(expressionList[index]);
                                    mathModel.setResult(resultList[index]);
                                    mathModel.calcNumber();
                                    final mathBoxController = Provider.of<MathBoxController>(context, listen:false);
                                    mathBoxController.decodeMathBoxHistory(mathBoxList[index]);
                                    mathBoxController.loadSavedHistory();
                                    Navigator.pop(context);
                                    return _showDialog(
                                        CsvLocalizations.instance.string('success'),
                                        CsvLocalizations.instance.string('formula_loaded')
                                    );
                                  });
                                },
                              ),
                              FlatButton(
                                color: Colors.red,
                                textColor: Colors.white,
                                child: Text(CsvLocalizations.instance.string('cancel')),
                                onPressed: () {
                                  setState(() {
                                    Navigator.pop(context);
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.trashAlt,
                      color: Colors.red,),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          // return object of type Dialog
                          return AlertDialog(
                            title: Text(CsvLocalizations.instance.string('alert')),
                            content: Text(CsvLocalizations.instance.string('remove_this')),
                            actions: <Widget>[
                              FlatButton(
                                color: Colors.green,
                                textColor: Colors.white,
                                child: Text(CsvLocalizations.instance.string('ok')),
                                onPressed: () {
                                  setState(() {
                                    // remove mathmode
                                    mathModelNameList.removeAt(index);
                                    expressionList.removeAt(index);
                                    resultList.removeAt(index);
                                    mathBoxList.removeAt(index);
                                    prefs.setStringList("mathModelNameList", mathModelNameList);
                                    prefs.setStringList("expressionList", expressionList);
                                    prefs.setStringList("resultList", resultList);
                                    prefs.setStringList("mathBoxList", mathBoxList);
                                    Navigator.pop(context);
                                    return _showDialog(
                                        CsvLocalizations.instance.string('success'),
                                        CsvLocalizations.instance.string('formula_removed')
                                    );
                                  });
                                },
                              ),
                              FlatButton(
                                color: Colors.red,
                                textColor: Colors.white,
                                child: Text(CsvLocalizations.instance.string('cancel')),
                                onPressed: () {
                                  setState(() {
                                    Navigator.pop(context);
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
            ),
          );
        },
      ),
    );
  }

  Widget setupAlertDialoadContainer() {
    List<String> expressionList = prefs.getStringList('expressionList') ?? [];
    List<String> resultList = prefs.getStringList('resultList') ?? [];
    List<String> mathModelNameList = prefs.getStringList('mathModelNameList') ?? [];
    List<String> mathBoxList = prefs.getStringList('mathBoxList') ?? [];

    return Container(
      height: 300.0, // Change as per your requirement
      width: 300.0, // Change as per your requirement
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: mathModelNameList.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(mathModelNameList[index]),
            trailing: SizedBox(
              width: 100,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.download,
                      color: Colors.blue,),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(CsvLocalizations.instance.string('alert')),
                            content: Text(CsvLocalizations.instance.string('load_this')),
                            actions: <Widget>[
                              FlatButton(
                                color: Colors.green,
                                textColor: Colors.white,
                                child: Text(CsvLocalizations.instance.string('ok')),
                                onPressed: () {
                                  setState(() {
                                    final mathModel = Provider.of<MathModel>(context, listen: false);
                                    mathModel.updateExpression(expressionList[index]);
                                    mathModel.setResult(resultList[index]);
                                    mathModel.calcNumber();
                                    final mathBoxController = Provider.of<MathBoxController>(context, listen:false);
                                    mathBoxController.decodeMathBoxHistory(mathBoxList[index]);
                                    mathBoxController.loadSavedHistory();
                                    Navigator.pop(context);
                                    return _showDialog(
                                        CsvLocalizations.instance.string('success'),
                                        CsvLocalizations.instance.string('formula_loaded')
                                    );
                                  });
                                },
                              ),
                              FlatButton(
                                color: Colors.red,
                                textColor: Colors.white,
                                child: Text(CsvLocalizations.instance.string('cancel')),
                                onPressed: () {
                                  setState(() {
                                    Navigator.pop(context);
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      FontAwesomeIcons.trashAlt,
                      color: Colors.red,),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          // return object of type Dialog
                          return AlertDialog(
                            title: Text(CsvLocalizations.instance.string('alert')),
                            content: Text(CsvLocalizations.instance.string('remove_this')),
                            actions: <Widget>[
                              FlatButton(
                                color: Colors.green,
                                textColor: Colors.white,
                                child: Text(CsvLocalizations.instance.string('ok')),
                                onPressed: () {
                                  setState(() {
                                    // remove mathmode
                                    mathModelNameList.removeAt(index);
                                    expressionList.removeAt(index);
                                    resultList.removeAt(index);
                                    mathBoxList.removeAt(index);
                                    prefs.setStringList("mathModelNameList", mathModelNameList);
                                    prefs.setStringList("expressionList", expressionList);
                                    prefs.setStringList("resultList", resultList);
                                    prefs.setStringList("mathBoxList", mathBoxList);
                                    int count = 2;
                                    Navigator.of(context).popUntil((_) => count-- <= 0);
                                    return _showDialog(
                                        CsvLocalizations.instance.string('success'),
                                        CsvLocalizations.instance.string('formula_removed')
                                    );
                                  });
                                },
                              ),
                              FlatButton(
                                color: Colors.red,
                                textColor: Colors.white,
                                child: Text(CsvLocalizations.instance.string('cancel')),
                                onPressed: () {
                                  setState(() {
                                    Navigator.pop(context);
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // For handling notification when the app is in terminated state
  checkForInitialMessage() async {
    await Firebase.initializeApp();
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      PushNotification notification = PushNotification(
        title: initialMessage.notification?.title,
        body: initialMessage.notification?.body,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _server.start();
    registerNotification();

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      PushNotification notification = PushNotification(
        title: message.notification?.title,
        body: message.notification?.body,
      );
    });
    checkForInitialMessage();
  }

  @override
  void dispose() {
    _server.close();
    super.dispose();
  }

  Widget settingPage() {
    return ListView(
      itemExtent: 60.0,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      children: <Widget>[
        ListTile(
          leading: Text(
            CsvLocalizations.instance.string('calc_setting'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Consumer<SettingModel>(
          builder: (context, setmodel, _) => ListTile(
            title: ToggleButtons(
              children: const <Widget>[
                Text('RAD'),
                Text('DEG'),
              ],
              constraints: const BoxConstraints(
                minWidth: 100,
                minHeight: 40,
              ),
              isSelected: [setmodel.isRadMode, !setmodel.isRadMode],
              onPressed: (index) {
                setmodel.changeRadMode((index==0)?true:false);
              },
            ),
          ),
        ),
        SizedBox(height: 50),
        Consumer<SettingModel>(
          builder: (context, setmodel, _) => ListTile(
            title: Text(
              CsvLocalizations.instance.string('calc_precision'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),),
            subtitle: Slider(
              value: setmodel.precision.toDouble(),
              min: 0.0,
              max: 10.0,
              label: "${setmodel.precision.toInt()}",
              divisions: 10,
              onChanged: (val) {
                setmodel.changeSlider(val);
              },
            ),
            trailing: Text('${setmodel.precision.toInt()}'),
          ),
        ),
        const SizedBox(height: 50),
        ListTile(
          leading: Text(
            CsvLocalizations.instance.string('function_keyboard'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Consumer<SettingModel>(
          builder: (context, setmodel, _) => ListTile(
            title: ToggleButtons(
              children: <Widget>[
                Text(CsvLocalizations.instance.string('brown')),
                Text(CsvLocalizations.instance.string('black')),
                Text(CsvLocalizations.instance.string('red')),
                Text(CsvLocalizations.instance.string('blue')),
                Text(CsvLocalizations.instance.string('orange')),
              ],
              constraints: const BoxConstraints(
                minWidth: 55,
                minHeight: 40,
              ),
              isSelected: [
                setmodel.functionColorList[0],
                setmodel.functionColorList[1],
                setmodel.functionColorList[2],
                setmodel.functionColorList[3],
                setmodel.functionColorList[4],
              ],
              onPressed: (index) {
                setmodel.changeFunctionColor(index);
              },
            ),
          ),
        ),const SizedBox(height: 50),
        ListTile(
          leading: Text(
            CsvLocalizations.instance.string('number_keyboard'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Consumer<SettingModel>(
          builder: (context, setmodel, _) => ListTile(
            title: ToggleButtons(
              children: <Widget>[
                Text(CsvLocalizations.instance.string('brown')),
                Text(CsvLocalizations.instance.string('black')),
                Text(CsvLocalizations.instance.string('red')),
                Text(CsvLocalizations.instance.string('blue')),
                Text(CsvLocalizations.instance.string('orange')),
              ],
              constraints: const BoxConstraints(
                minWidth: 55,
                minHeight: 40,
              ),
              isSelected: [
                setmodel.numberColorList[0],
                setmodel.numberColorList[1],
                setmodel.numberColorList[2],
                setmodel.numberColorList[3],
                setmodel.numberColorList[4],
              ],
              onPressed: (index) {
                setmodel.changeNumberColor(index);
              },
            ),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Container(
          height: 250,
          width: 300,
          child: AdWidget(ad: settingBanner)
        )
      ],
    );
  }

  final PageController pageController = PageController(initialPage: 0);
  int _selectedIndex=0;

  void _onItemTapped (int index) async {
    setState(() {
      if (index == 0) {
        pageController.animateToPage(
          0,
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 100),);
      } else if (index == 1) {
        _selectedIndex = 1;
        pageController.animateToPage(
          1,
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 100),);
      } else if (index == 2) {
        _selectedIndex = 2;
        pageController.animateToPage(
          2,
          curve: Curves.easeIn,
          duration: const Duration(milliseconds: 100),);
      } else if (index == 3) {
        _selectedIndex = 0;
        pageController.jumpTo(0);
      }
    });

    if (index == 3) {
      _displayTextInputDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        resizeToAvoidBottomInset : false,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: AppBar(
            elevation: 0.0,
            backgroundColor: Colors.transparent,
          ),
        ),
        body: PageView(
          physics:const NeverScrollableScrollPhysics(),
          controller: pageController,
          children: [
              Column(
              children: <Widget>[
                Container(
                  height: 50,
                  child: AdWidget(ad: mainBanner),
                ),
                Container(
                  height: 10,
                ),
                Expanded(
                  flex: 10,
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
            settingPage(),
            Container(
              color: Colors.white24,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 60,
                    child: AdWidget(ad: historyBanner),
                  ),
                  SizedBox(height: 10),
                  formulaHistoryList(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(onTap: _onItemTapped,
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: Icon(FlutterIcons.md_calculator_ion),
                  title: Text(CsvLocalizations.instance.string('calculator'))
              ),
              BottomNavigationBarItem(
                  icon: Icon(FlutterIcons.setting_ant),
                  title: Text(CsvLocalizations.instance.string('setting'))
              ),
              BottomNavigationBarItem(
                  icon: Icon(FlutterIcons.history_faw),
                  title: Text(CsvLocalizations.instance.string('history'))
              ),
              BottomNavigationBarItem(
                  icon: Icon(FontAwesomeIcons.save,),
                  title: Text(CsvLocalizations.instance.string('save'))
              ),
            ]),
      ),
      onWillPop: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(CsvLocalizations.instance.string('end')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(CsvLocalizations.instance.string('end_app')),
                  Container(
                    width: 330,
                    height: 260,
                    child: AdWidget(ad: endBanner),
                  )
                ],
              ),
              actions: <Widget>[
                FlatButton(
                  color: Colors.green,
                  textColor: Colors.white,
                  child: Text(CsvLocalizations.instance.string('ok')),
                  onPressed: () {
                    setState(() {
                      SystemNavigator.pop();
                    });
                  },
                ),
                FlatButton(
                  color: Colors.red,
                  textColor: Colors.white,
                  child: Text(CsvLocalizations.instance.string('cancel'),),
                  onPressed: () {
                    setState(() {
                      Navigator.pop(context);
                    });
                  },
                ),
              ],
            );
          },
        );
        return new Future(() => false);
      },
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
              ? ExpandKeyBoard()
              : const SizedBox(
            height: 0.0,
          ),
        ),
      ],
    );
  }
}

