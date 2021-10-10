import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_calculator/src/backend/math_model.dart';

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
