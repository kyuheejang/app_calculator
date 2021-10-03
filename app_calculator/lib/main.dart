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

import 'package:app_calculator/src/widgets/math_box.dart';
import 'package:app_calculator/src/widgets/result.dart';
import 'package:app_calculator/src/widgets/keyboard.dart';
import 'package:app_calculator/src/backend/math_model.dart';
import 'package:app_calculator/src/pages/setting_page.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

String testInitialAdId = "ca-app-pub-3940256099942544/1033173712";
String testBannerAdId = "ca-app-pub-3940256099942544/6300978111";

String mainInterAdId = "";
String settingInterAdId = "";
String formulaSaveInterAdId = "";
String formulaLoadInterAdId = "";
String settingBannerAdId = "";
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
      mainInterAdId = value.data()?['iosMainInter'];
      settingInterAdId = value.data()?['iosSettingInter'];
      settingBannerAdId = value.data()?['iosSettingBanner'];
      formulaSaveInterAdId = value.data()?['iosFormulaSaveInter'];
      formulaLoadInterAdId = value.data()?['iosFormulaLoadInter'];
    } else {
      mainInterAdId = value.data()?['andMainInter'];
      settingInterAdId = value.data()?['andSettingInter'];
      settingBannerAdId = value.data()?['andSettingBanner'];
      formulaSaveInterAdId = value.data()?['andFormulaSaveInter'];
      formulaLoadInterAdId = value.data()?['andFormulaLoadInter'];
    }
  } else {
    mainInterAdId = testInitialAdId;
    settingInterAdId = testInitialAdId;
    formulaSaveInterAdId = testInitialAdId;
    formulaLoadInterAdId = testInitialAdId;
    settingBannerAdId = testBannerAdId;
  }

  await MobileAds.instance.initialize();


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
    adUnitId: settingBannerAdId,
    size: AdSize.fullBanner,
    request: const AdRequest(),
    listener: const BannerAdListener(),
  );

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

    InterstitialAd.load(adUnitId: mainInterAdId,
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
  }

  final Server _server = Server();

  final TextEditingController _textFieldController = TextEditingController();

  Future<void> _displayTextInputDialog(BuildContext context) async {
    String saveName = "";
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Please specify a name of the formula to be saved \n \n'
                'Operations that require input by touching the screen, such as log, do not work.'),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)
            ),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  saveName = value;
                });
              },
              controller: _textFieldController,
              decoration: const InputDecoration(hintText: ""),
            ),
            actions: <Widget>[
              FlatButton(
                color: Colors.green,
                textColor: Colors.white,
                child: Text('OK'),
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
                          'Error',
                          'Please specify a formula name'
                      );
                    }

                    if (mathModelNameList.length > 10) {
                      Navigator.pop(context);
                      return _showDialog(
                          'Error',
                          'Cannot store more than 10 formulas'
                      );
                    }

                    InterstitialAd.load(adUnitId: formulaSaveInterAdId,
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
                    return _showDialog(
                        'Success',
                        'Formula saved successfully'
                    );
                  });
                },
              ),
              FlatButton(
                color: Colors.red,
                textColor: Colors.white,
                child: Text('CANCEL'),
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
              child: new Text("Close"),
              onPressed: () {
                Navigator.pop(context);
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
                            title: new Text("Alert"),
                            content: new Text("load this formula?"),
                            actions: <Widget>[
                              FlatButton(
                                color: Colors.green,
                                textColor: Colors.white,
                                child: Text('OK'),
                                onPressed: () {
                                  setState(() {
                                    InterstitialAd.load(adUnitId: formulaLoadInterAdId,
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
                                        'Success',
                                        'Formula loaded successfully'
                                    );
                                  });
                                },
                              ),
                              FlatButton(
                                color: Colors.red,
                                textColor: Colors.white,
                                child: Text('CANCEL'),
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
                            title: const Text("Alert"),
                            content: const Text("Remove this formula?"),
                            actions: <Widget>[
                              FlatButton(
                                color: Colors.green,
                                textColor: Colors.white,
                                child: const Text('OK'),
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
                                        'Success',
                                        'Formula removed successfully'
                                    );
                                  });
                                },
                              ),
                              FlatButton(
                                color: Colors.red,
                                textColor: Colors.white,
                                child: const Text('CANCEL'),
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
    myBanner.load();
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

  @override
  Widget build(BuildContext context) {

    final AdWidget bannerWidget = AdWidget(ad: myBanner);

    return Scaffold(
      resizeToAvoidBottomInset : false,
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
              MaterialPageRoute(builder: (context) => SettingPage(bannerWidget, settingInterAdId)),
            ).then((onValue) {
              setState(() {

              });
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.save,
              color: Colors.black,
            ),
            onPressed: () {
              _displayTextInputDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(
              FontAwesomeIcons.hdd,
              color: Colors.black,
            ),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Saved formula list'),
                      content: setupAlertDialoadContainer(),
                    );
                  });
            },
          ),
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
          MathKeyBoard(),
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
              ? ExpandKeyBoard()
              : const SizedBox(
            height: 0.0,
          ),
        ),
      ],
    );
  }
}

