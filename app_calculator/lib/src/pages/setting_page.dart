import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_calculator/src/backend/math_model.dart';

class SettingPage extends StatelessWidget {

  SettingPage(this.bannerSettingWidget, this.initialSettingAdId);

  final AdWidget bannerSettingWidget;
  final String initialSettingAdId;
  InterstitialAd? interstitialSettingAd;

  @override
  Widget build(BuildContext context) {
    InterstitialAd.load(adUnitId: initialSettingAdId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialSettingAd=ad;
            interstitialSettingAd!.show();
          },
          onAdFailedToLoad: (error) {
          },
        ));

    final mathModel = Provider.of<MathModel>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,),
          onPressed: () {
            mathModel.calcNumber();
            Navigator.pop(context);
          },
        ),
        title: const Text('Settings',),
      ),
      body: settingPage(),
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget settingPage() {
    return ListView(
      itemExtent: 60.0,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      children: <Widget>[
        const ListTile(
          leading: Text(
            'Calc Setting',
            style: TextStyle(
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
        SizedBox(height: 100),
        Consumer<SettingModel>(
          builder: (context, setmodel, _) => ListTile(
            title: const Text(
              'Calc Precision',
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
        const SizedBox(height: 100),
        const ListTile(
          leading: Text(
            'Change color: function keyboard',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Consumer<SettingModel>(
          builder: (context, setmodel, _) => ListTile(
            title: ToggleButtons(
              children: const <Widget>[
                Text('Brown'),
                Text('Black'),
                Text('Red'),
                Text('Blue'),
                Text('Orange'),
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
        ),const SizedBox(height: 100),
        const ListTile(
          leading: Text(
            'Change color: number keyboard',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Consumer<SettingModel>(
          builder: (context, setmodel, _) => ListTile(
            title: ToggleButtons(
              children: const <Widget>[
                Text('Brown'),
                Text('Black'),
                Text('Red'),
                Text('Blue'),
                Text('Orange'),
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
      ],
    );
  }
}

class SettingModel with ChangeNotifier {
  double precision = 10;
  bool isRadMode = true;
  bool hideKeyboard = false;
  int initPage = 0;
  Completer loading = Completer();

  bool isFunctionBrown = false;
  bool isFunctionBlack = false;
  bool isFunctionRed = false;
  bool isFunctionBlue = false;
  bool isFunctionOrange = false;


  var functionColorList = [false, false, false, false, false];
  int functionColorIndex = 0;

  var numberColorList = [false, false, false, false, false];
  int numberColorIndex = 0;

  SettingModel() {
    initVal();
  }

  Future changeSlider(double val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    precision = val;
    prefs.setDouble('precision', precision);
    notifyListeners();
  }

  Future changeRadMode(bool mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isRadMode = mode;
    prefs.setBool('isRadMode', isRadMode);
    notifyListeners();
  }

  Future changeKeyboardMode(bool mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    hideKeyboard = mode;
    prefs.setBool('hideKeyboard', hideKeyboard);
  }

  Future changeInitpage(int val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    initPage = val;
    prefs.setInt('initPage', initPage);
  }

  Future initVal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    precision = prefs.getDouble('precision') ?? 10;
    isRadMode = prefs.getBool('isRadMode') ?? true;
    hideKeyboard = prefs.getBool('hideKeyboard') ?? false;
    initPage = prefs.getInt('initPage') ?? 0;
    functionColorIndex = prefs.getInt('functionColorIndex') ?? 0;
    functionColorList[functionColorIndex] = true;
    numberColorIndex = prefs.getInt('numberColorIndex') ?? 1;
    numberColorList[numberColorIndex] = true;
    loading.complete();

    notifyListeners();
  }

  Future changeFunctionColor(int colorIndex) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    for (int i=0; i<functionColorList.length; i++) {
      functionColorList[i] = false;
    }
    functionColorList[colorIndex] = true;
    prefs.setInt('functionColorIndex', colorIndex);
    notifyListeners();
  }

  Future changeNumberColor(int colorIndex) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    for (int i=0; i<numberColorList.length; i++) {
      numberColorList[i] = false;
    }
    numberColorList[colorIndex] = true;
    prefs.setInt('numberColorIndex', colorIndex);
    notifyListeners();
  }
}
