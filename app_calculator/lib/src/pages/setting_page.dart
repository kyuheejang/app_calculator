import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_calculator/src/backend/math_model.dart';

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
        title: const Text('Setting',),
      ),
      body: ListView(
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
          Consumer<SettingModel>(
            builder: (context, setmodel, _) => ListTile(
              title: const Text('Calc Precision'),
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
        ],
      ),
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

}

class SettingModel with ChangeNotifier {
  double precision = 10;
  bool isRadMode = true;
  bool hideKeyboard = false;
  int initPage = 0;
  Completer loading = Completer();

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
    loading.complete();
    notifyListeners();
  }

}
