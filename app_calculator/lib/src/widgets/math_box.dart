import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';

import 'package:app_calculator/src/backend/math_model.dart';
import 'package:app_calculator/src/pages/setting_page.dart';

class Server {
  // class from inAppBrowser

  HttpServer? _server;

  int _port = 8080;

  Server({int port = 8080}) {
    _port = port;
  }

  ///Closes the server.
  Future<void> close() async {
    if (_server != null) {
      await _server!.close(force: true);
      print('Server running on http://localhost:$_port closed');
      _server = null;
    }
  }

  Future<void> start() async {
    if (_server != null) {
      throw Exception('Server already started on http://localhost:$_port');
    }

    var completer = Completer();
    runZoned(() {
      HttpServer.bind('127.0.0.1', _port, shared: true).then((server) {
        print('Server running on http://localhost:' + _port.toString());

        _server = server;

        server.listen((HttpRequest request) async {
          var body = <int>[];
          var path = request.requestedUri.path;
          path = (path.startsWith('/')) ? path.substring(1) : path;
          path += (path.endsWith('/')) ? 'index.html' : '';

          try {
            body = (await rootBundle.load(path)).buffer.asUint8List();
          } catch (e) {
            print(e.toString());
            request.response.close();
            return;
          }

          var contentType = ['text', 'html'];
          if (!request.requestedUri.path.endsWith('/') &&
              request.requestedUri.pathSegments.isNotEmpty) {
            var mimeType =
                lookupMimeType(request.requestedUri.path, headerBytes: body);
            if (mimeType != null) {
              contentType = mimeType.split('/');
            }
          }

          request.response.headers.contentType =
              ContentType(contentType[0], contentType[1], charset: 'utf-8');
          request.response.add(body);
          request.response.close();
        });

        completer.complete();
      });
    }, onError: (e, stackTrace) => print('Error: $e $stackTrace'));

    return completer.future;
  }
}

class MathBox extends StatelessWidget {
  const MathBox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mathBoxController = Provider.of<MathBoxController>(context, listen: false);
    final mathModel = Provider.of<MathModel>(context, listen: false);
    final matrixModel = Provider.of<MatrixModel>(context, listen: false);
    final functionModel = Provider.of<FunctionModel>(context, listen: false);
    final mode = Provider.of<CalculationMode>(context, listen: false);
    return Stack(
      children: <Widget>[
        WebView(
          onWebViewCreated: (controller) {
            controller.loadUrl("http://localhost:8080/assets/html/homepage.html");
            mathBoxController.webViewController = controller;
          },
          onPageFinished: (s) {
            final setting = Provider.of<SettingModel>(context, listen: false);
            if (setting.initPage == 1) {
              mathBoxController.addExpression('\\\\bmatrix');
            }
          },
          javascriptMode: JavascriptMode.unrestricted,
          javascriptChannels: {
            JavascriptChannel(
              name: 'latexString',
              onMessageReceived: (JavascriptMessage message) {
                if (mode.value == Mode.Matrix) {
                  matrixModel.updateExpression(message.message);
                } else {
                  if (message.message.contains(RegExp('x|y'))) {
                    mode.changeMode(Mode.Function);
                    functionModel.updateExpression(message.message);
                  } else {
                    mode.changeMode(Mode.Basic);
                    mathModel.updateExpression(message.message);
                    mathModel.calcNumber();
                  }
                }
              }
            ),
            JavascriptChannel(
              name: 'clearable',
              onMessageReceived: (JavascriptMessage message) {
                mathModel.changeClearable(message.message == 'false'?false:true);
              }
            ),
          },
        ),
        ClearAnimation(),
      ],
    );
  }
}

class ClearAnimation extends StatefulWidget {
  @override
  _ClearAnimationState createState() => _ClearAnimationState();
}

class _ClearAnimationState extends State<ClearAnimation> with TickerProviderStateMixin {

  late AnimationController animationController;
  late Animation animation;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(duration: const Duration(milliseconds: 500),vsync: this);
    final curve = CurvedAnimation(parent: animationController, curve: Curves.easeInOutCubic);
    animation = Tween<double>(begin: 0, end: 2000).animate(curve);
    Provider.of<MathBoxController>(context, listen: false).clearAnimationController = animationController;
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimation(BuildContext context, Widget? child) {
    return Positioned(
      top: 10.0-animation.value/2,
      right: -animation.value/2,
      child: ClipOval(
        child: Container(
          height: animation.value,
          width: animation.value,
          color: Colors.blue[100],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      builder: _buildAnimation,
      animation: animation,
    );
  }
}

class MathBoxController {

  late WebViewController _webViewController;
  late AnimationController clearAnimationController;
  List<String> mathBoxHistoryList = [];

  set webViewController(WebViewController controller) {
    _webViewController = controller;
  }

  String encodeMathBoxHistory() {
    String _encodedMathBoxHistoryList = "";
    print(mathBoxHistoryList.toString());

    for (var i = 0; i < mathBoxHistoryList.length; i++) {
      _encodedMathBoxHistoryList += mathBoxHistoryList[i];
      if (i < mathBoxHistoryList.length - 1) {
        _encodedMathBoxHistoryList += "@@";
      }
    }
    return _encodedMathBoxHistoryList;
  }

  void decodeMathBoxHistory(String _mathBoxHistoryList) {
    print(_mathBoxHistoryList);
    List<String> parsedExpressionList = _mathBoxHistoryList.split("@@");
    mathBoxHistoryList = parsedExpressionList;
    print(mathBoxHistoryList.toString());
  }



  void addExpression(String msg, {bool isOperator = false}) {
    String cmd = "addCmd('$msg', {isOperator: ${isOperator.toString()}})";
    _webViewController.evaluateJavascript(cmd);
    mathBoxHistoryList.add(cmd);
  }

  void addString(String msg) {
    String cmd = "addString('$msg')";
    _webViewController.evaluateJavascript(cmd);
    mathBoxHistoryList.add(cmd);
  }

  void equal() {
    String cmd = "equal()";
    _webViewController.evaluateJavascript(cmd);
    mathBoxHistoryList.add(cmd);
  }

  void addKey(String key) {
    String cmd = "simulateKey('$key')";
    _webViewController.evaluateJavascript(cmd);
    mathBoxHistoryList.add(cmd);
  }

  void deleteExpression() {
    String cmd = "delString()";
    _webViewController.evaluateJavascript(cmd);
    mathBoxHistoryList.removeLast();
  }

  void deleteAllExpression() {
    _webViewController.evaluateJavascript("delAll()");
    mathBoxHistoryList.clear();
  }

  void loadSavedHistory() {
    _webViewController.evaluateJavascript("delAll()");
    for (var history in mathBoxHistoryList) {
      _webViewController.evaluateJavascript(history);
    }
  }
}
