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
import 'package:app_calculator/screens/more_apps.dart';
import 'package:app_calculator/ad/admob_banner_ad.dart';
import 'package:app_calculator/ad/admob_Interstitial_ad.dart';
import 'package:app_calculator/ad/admob_opening_ad.dart';
import 'package:app_calculator/ad/lifecycle_refactor.dart';

String testOpeningAdId = "ca-app-pub-3940256099942544/3419835294";

int functionColorIndex = 0;
int numberColorIndex = 0;
Color functionBackgroundColor = Colors.black87;
Color numberBackgroundColor = Colors.black87;
late SharedPreferences prefs;
late Icon more_apps_icon;

class PushNotification {
  PushNotification({
    this.title,
    this.body,
  });
  String? title;
  String? body;
}

// 세팅 광고
InterstitialAd? settingInter;
InterstitialAd? saveInter;
InterstitialAd? loadInter;
InterstitialAd? moreAppsInter;

late BannerAd settingBanner;
late BannerAd endBanner;

AdmobInterstitialAd settingInterAd = AdmobInterstitialAd('SettingInter');
AdmobInterstitialAd saveInterAd = AdmobInterstitialAd('FormulaSaveInter');
AdmobInterstitialAd loadInterAd = AdmobInterstitialAd('FormulaLoadInter');
AdmobInterstitialAd moreAppsInterAd = AdmobInterstitialAd('MoreAppsInter');

Widget moreApps = MoreApps();
AppOpenAdManager appOpenAdManager = AppOpenAdManager();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final status = await AppTrackingTransparency.requestTrackingAuthorization();

  await Firebase.initializeApp();
  prefs = await SharedPreferences.getInstance();

  await MobileAds.instance.initialize();
  await MobileAds.instance.setAppMuted(true);

  AdmobBannerAd settingBannerAd = AdmobBannerAd('SettingBanner', AdSize.banner);
  settingBanner = await settingBannerAd.getBannerAd();

  AdmobBannerAd endBannerAd = AdmobBannerAd('EndBanner', AdSize.mediumRectangle);
  endBanner = await endBannerAd.getBannerAd();

  await settingInterAd.initializeInterstitialAd();
  await saveInterAd.initializeInterstitialAd();
  await loadInterAd.initializeInterstitialAd();
  await moreAppsInterAd.initializeInterstitialAd();
  await appOpenAdManager.initializeOpeningAd();
  appOpenAdManager.loadAd();

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
        title: 'Scientific Calculator',
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
    saveInter = saveInterAd.getInterstitialAd();
    if (saveInter != null) {
      await saveInter!.show();
    }

    String saveName = "";

    return await showDialog(
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
                      return _showDialog(
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
                  });
                  return _showDialog2(
                    CsvLocalizations.instance.string('success'),
                    CsvLocalizations.instance.string('formula_saved'),
                  );
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

  void _showDialog2(String title, String body) {
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
                int count = 2;
                Navigator.of(context).popUntil((_) => count-- <= 0);
              },
            ),
          ],
        );
      },
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
                                    int count = 2;
                                    Navigator.of(context).popUntil((_) => count-- <= 0);
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

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      more_apps_icon = Icon(FlutterIcons.app_store_ent);
    } else {
      more_apps_icon = Icon(FlutterIcons.android1_ant);
    }

    WidgetsBinding.instance
        .addObserver(AppLifecycleReactor(appOpenAdManager: appOpenAdManager));
  }

  @override
  void dispose() {
    _server.close();
    super.dispose();
  }

  Widget formulaHistory() {
    List<String> expressionList = prefs.getStringList('expressionList') ?? [];
    List<String> resultList = prefs.getStringList('resultList') ?? [];
    List<String> mathModelNameList = prefs.getStringList('mathModelNameList') ?? [];
    List<String> mathBoxList = prefs.getStringList('mathBoxList') ?? [];

    return Scaffold(
      resizeToAvoidBottomInset : false,
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
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: mathModelNameList.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ListTile(
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
          ),
        ],
      )
    );
  }

  Widget settingPage() {
    return Scaffold(
      resizeToAvoidBottomInset : false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(15.0),
        child: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
        ),
      ),
      body: ListView(
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
          Container(
            height: 50,
            child: AdWidget(ad: settingBanner)
          )
        ],
      ),
    );
  }

  int _selectedIndex=0;

  void _onItemTapped (int index) async {
    setState(() {
      _selectedIndex=index;
    });
    if (index == 1) {
      settingInter = settingInterAd.getInterstitialAd();
      if (settingInter != null) {
        await settingInter!.show();
      }
    }
    if (index == 2) {
      loadInter = loadInterAd.getInterstitialAd();
      if (loadInter != null) {
        await loadInter!.show();
      }
    }
    if (index == 3) {
      moreAppsInter = moreAppsInterAd.getInterstitialAd();
      if (moreAppsInter != null) {
        await moreAppsInter!.show();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 5),
              title: Text(CsvLocalizations.instance.string('end')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(CsvLocalizations.instance.string('end_app')),
                  SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: SizedBox()),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text(
                          CsvLocalizations.instance.string('ok'),
                          style: TextStyle(
                              color: Colors.white
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            SystemNavigator.pop();
                          });
                        },
                      ),
                      SizedBox(width: 10),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text(
                          CsvLocalizations.instance.string('cancel'),
                          style: TextStyle(
                              color: Colors.white
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            Navigator.pop(context);
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: 330,
                    height: 260,
                    child: AdWidget(ad: endBanner),
                  ),
                ],
              ),
            );
          },
        );
        return new Future(() => false);
      },
      child: Scaffold(
        resizeToAvoidBottomInset : false,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            Column(
              children: [
                Expanded(
                  child: Scaffold(
                    resizeToAvoidBottomInset : false,
                    appBar: AppBar(
                      elevation: 0.0,
                      backgroundColor: Colors.transparent,
                      actions: <Widget>[
                        IconButton(
                          tooltip: CsvLocalizations.instance.string('save'),
                          onPressed: () {
                            _displayTextInputDialog(context);
                          },
                          icon: Icon(
                            FontAwesomeIcons.save,
                            color: Colors.black,
                          ),
                        )
                      ],
                    ),
                    body: Column(
                      children: <Widget>[
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
                        MathKeyBoard()
                      ],
                    ),
                  ),
                ),
              ],
            ),
            settingPage(),
            formulaHistory(),
            moreApps
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
            onTap: _onItemTapped,
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: Icon(FlutterIcons.md_calculator_ion),
                  label: CsvLocalizations.instance.string('calculator')
              ),
              BottomNavigationBarItem(
                  icon: Icon(FlutterIcons.setting_ant),
                  label: CsvLocalizations.instance.string('setting')
              ),
              BottomNavigationBarItem(
                  icon: Icon(FontAwesomeIcons.history),
                  label: CsvLocalizations.instance.string('history')
              ),
              BottomNavigationBarItem(
                icon: more_apps_icon,
                label: CsvLocalizations.instance.string('moreApps'),
              ),
            ]),
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
              ? ExpandKeyBoard()
              : const SizedBox(
            height: 0.0,
          ),
        ),
      ],
    );
  }
}

