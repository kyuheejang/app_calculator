import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:app_calculator/src/widgets/math_box.dart';
import 'package:app_calculator/src/pages/setting_page.dart';
import 'package:app_calculator/src/backend/math_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NumButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final double fontSize;
  final Color fontColor;

  const NumButton({
    required this.child,
    required this.onPressed,
    this.onLongPress,
    this.fontSize = 30,
    this.fontColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
        fontSize: fontSize,
        color: fontColor,
        fontFamily: "GemunuLibre",
      ),
      child: InkResponse(
        splashFactory: InkRipple.splashFactory,
        highlightColor: Colors.transparent,
        onTap: onPressed,
        onLongPress: onLongPress,
        child: Center(child: child,),
      ),
    );
  }
}

class SignButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final double fontSize;
  final Color fontColor;

  const SignButton({
    required this.child,
    required this.onPressed,
    this.onLongPress,
    this.fontSize = 25,
    this.fontColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
        fontSize: fontSize,
        color: fontColor,
        fontFamily: "TimesNewRoman",
      ),
      child: InkResponse(
        splashFactory: InkRipple.splashFactory,
        highlightColor: Colors.transparent,
        onTap: onPressed,
        onLongPress: onLongPress,
        child: Center(child: child,),
      ),
    );
  }
}


const aspectRatio = 1.2;

class MathKeyBoard extends StatelessWidget {

  Color functionBackgroundColor = Colors.black;
  Color numberBackgroundColor = Colors.black;

  List<Widget> _buildLowButton(MathBoxController mathBoxController) {
    List<Widget> button = [];

    for (var i = 7; i <= 9; i++) {
      button.add(NumButton(
        child: Text('$i'),
        onPressed: () {mathBoxController.addExpression('$i');},
      ));
    }

    button.add(SignButton(
      child: const Icon(
        FontAwesomeIcons.broom,
        color: Colors.white,
      ),
      onPressed: mathBoxController.deleteAllExpression,
    ));


    button.add(NumButton(
      child: const Icon(
        FontAwesomeIcons.backspace,
        color: Colors.white,
      ),
      onPressed: mathBoxController.deleteExpression,
      onLongPress: () async {
        mathBoxController.deleteAllExpression();
        await mathBoxController.clearAnimationController.forward();
        mathBoxController.clearAnimationController.reset();
      },
    ));

    for (var i = 4; i <= 6; i++) {
      button.add(NumButton(
        child: Text('$i'),
        onPressed: () {mathBoxController.addExpression('$i');},
      ));
    }

    button.add(NumButton(
      child: const Text('+'),
      onPressed: () {mathBoxController.addExpression('+', isOperator: true);},
    ));

    button.add(NumButton(
      child: const Text('-'),
      onPressed: () {mathBoxController.addExpression('-', isOperator: true);},
    ));

    for (var i = 1; i <= 3; i++) {
      button.add(NumButton(
        child: Text('$i'),
        onPressed: () {mathBoxController.addExpression('$i');},
      ));
    }

    button.add(NumButton(
      child: const Text('×'),
      onPressed: () {mathBoxController.addExpression('\\\\times', isOperator: true);},
    ));

    button.add(NumButton(
      child: const Text('÷'),
      onPressed: () {mathBoxController.addExpression('\\div', isOperator: true);},
    ));

    button.add(NumButton(
      child: const Text('0'),
      onPressed: () {mathBoxController.addExpression('0');},
    ));

    button.add(NumButton(
      child: const Text('.'),
      onPressed: () {mathBoxController.addExpression('.');},
    ));

    button.add(Consumer<CalculationMode>(
      builder: (context, mode, _) => NumButton(
        child: mode.value!=Mode.Matrix?
          const Text('='):
          const Icon(
            MaterialCommunityIcons.matrix,
            size: 40.0,
          ),
        onPressed: () {
          mode.value==Mode.Basic?mathBoxController.equal():mathBoxController.addExpression('\\\\bmatrix');
        }, onLongPress: () {  },
      ),
    ));

    button.add(NumButton(
      child: const Text('π'),
      onPressed: () {mathBoxController.addExpression('\\pi');},
    ));

    button.add(NumButton(
      child: const Text('e'),
      onPressed: () {mathBoxController.addExpression('e');},
    ));

    return button;
  }

  Future changeThemeColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int functionColorIndex = prefs.getInt('functionColorIndex') ?? 0;
    int numberColorIndex = prefs.getInt('numberColorIndex') ?? 1;

    if (functionColorIndex == 0) {
      functionBackgroundColor = Colors.brown;
    } else if (functionColorIndex == 1) {
      functionBackgroundColor = Colors.black;
    } else if (functionColorIndex == 2) {
      functionBackgroundColor = Colors.red;
    } else if (functionColorIndex == 3) {
      functionBackgroundColor = Colors.blue;
    } else if (functionColorIndex == 4) {
      functionBackgroundColor = Colors.orange;
    } else if (functionColorIndex == 5) {
      functionBackgroundColor = Colors.white;
    }

    if (numberColorIndex == 0) {
      numberBackgroundColor = Colors.brown;
    } else if (numberColorIndex == 1) {
      numberBackgroundColor = Colors.black;
    } else if (numberColorIndex == 2) {
      numberBackgroundColor = Colors.red;
    } else if (numberColorIndex == 3) {
      numberBackgroundColor = Colors.blue;
    } else if (numberColorIndex == 4) {
      numberBackgroundColor = Colors.orange;
    } else if (numberColorIndex == 5) {
      numberBackgroundColor = Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final mathBoxController = Provider.of<MathBoxController>(context, listen: false);
    return FutureBuilder(
        future: changeThemeColor(),
        builder: (context, snapshot) {
          return SizedBox(
            height: width / 5 * 4 / aspectRatio,
            child: Material(
              color: numberBackgroundColor,
              elevation: 15.0,
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 5,
                childAspectRatio: aspectRatio,
                children: _buildLowButton(mathBoxController),
              ),
            ),
          );
        }
    );
  }
}

const animationConstant = 8.0;



class AtanCurve extends Curve {
  @override
  double transform(double t) => atan(animationConstant*2*t-animationConstant)/(2*atan(animationConstant))+0.5;
}

class ExpandKeyBoard extends StatefulWidget {

  Color functionBackgroundColor = Colors.black87;
  Color numberBackgroundColor = Colors.black87;

  @override
  _ExpandKeyBoardState createState() => _ExpandKeyBoardState();
}

class _ExpandKeyBoardState extends State<ExpandKeyBoard> with TickerProviderStateMixin {
  late AnimationController animationController;
  late Animation keyboardAnimation;
  late Animation arrowAnimation;
  late double _height;

  Color functionFontColor = Colors.black87;
  Color functionBackgroundColor = Colors.black87;
  Color numberFontColor = Colors.black87;
  Color numberBackgroundColor = Colors.black87;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _height = (MediaQuery.of(context).size.width - 10) / 7 * 3 / aspectRatio;

    animationController = AnimationController(duration: const Duration(milliseconds: 400),vsync: this);
    final curve = CurvedAnimation(parent: animationController, curve: AtanCurve());
    keyboardAnimation = Tween<double>(begin: _height, end: 0).animate(curve);
    arrowAnimation = Tween<double>(begin: 15.0, end: 35.0).animate(curve);
  }

  Widget _buildAnimation(BuildContext context, Widget? child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Material(
        color: functionBackgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: arrowAnimation.value,
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  final setting = Provider.of<SettingModel>(context, listen: false);
                  if (animationController.status == AnimationStatus.dismissed) {
                    animationController.forward();
                    setting.changeKeyboardMode(true);
                  } else {
                    animationController.reverse();
                    setting.changeKeyboardMode(false);
                  }
                },
                child: Icon(
                  (keyboardAnimation.value > _height*0.8)?Icons.keyboard_arrow_down:Icons.keyboard_arrow_up,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              height: keyboardAnimation.value,
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 7,
                children: _buildUpButton(),
                childAspectRatio: aspectRatio,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future changeThemeColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int functionColorIndex = prefs.getInt('functionColorIndex') ?? 0;
    int numberColorIndex = prefs.getInt('numberColorIndex') ?? 1;

    if (functionColorIndex == 0) {
      functionBackgroundColor = Colors.brown;
      functionFontColor = Colors.white;
    } else if (functionColorIndex == 1) {
      functionBackgroundColor = Colors.black;
      functionFontColor = Colors.white;
    } else if (functionColorIndex == 2) {
      functionBackgroundColor = Colors.red;
      functionFontColor = Colors.white;
    } else if (functionColorIndex == 3) {
      functionBackgroundColor = Colors.blue;
      functionFontColor = Colors.white;
    } else if (functionColorIndex == 4) {
      functionBackgroundColor = Colors.orange;
      functionFontColor = Colors.white;
    } else if (functionColorIndex == 5) {
      functionBackgroundColor = Colors.white;
      functionFontColor = Colors.black;
    }

    if (numberColorIndex == 0) {
      numberBackgroundColor = Colors.brown;
      numberFontColor = Colors.white;
    } else if (numberColorIndex == 1) {
      numberBackgroundColor = Colors.black;
      numberFontColor = Colors.white;
    } else if (numberColorIndex == 2) {
      numberBackgroundColor = Colors.red;
      numberFontColor = Colors.white;
    } else if (numberColorIndex == 3) {
      numberBackgroundColor = Colors.blue;
      numberFontColor = Colors.white;
    } else if (numberColorIndex == 4) {
      numberBackgroundColor = Colors.orange;
      numberFontColor = Colors.white;
    } else if (numberColorIndex == 5) {
      numberBackgroundColor = Colors.white;
      numberFontColor = Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final setting = Provider.of<SettingModel>(context, listen: false);
    return FutureBuilder(
      future: Future.wait([setting.loading.future, changeThemeColor()]),
      builder: (context, snapshot) {
        if (setting.loading.isCompleted && setting.hideKeyboard) {
          animationController.value = 1;
        }
        return GestureDetector(
          onVerticalDragUpdate: (detail) {
            if (keyboardAnimation.value - detail.delta.dy > 0 && keyboardAnimation.value - detail.delta.dy < _height) {
              double y = keyboardAnimation.value - detail.delta.dy;
              animationController.value = (tan(atan(animationConstant)-y*atan(animationConstant)*2/_height)+animationConstant)/animationConstant/2;
            }
          },
          onVerticalDragEnd: (detail) {
            if (detail.primaryVelocity! > 0.0) {
              animationController.animateTo(1.0, duration: const Duration(milliseconds: 200));
              setting.changeKeyboardMode(true);
            } else if (detail.primaryVelocity! < 0.0) {
              animationController.animateBack(0.0, duration: const Duration(milliseconds: 200));
              setting.changeKeyboardMode(false);
            } else if (keyboardAnimation.value > _height*0.8) {
              animationController.reverse();
              setting.changeKeyboardMode(false);
            } else {
              animationController.forward();
              setting.changeKeyboardMode(true);
            }
          },
          child: AnimatedBuilder(
            builder: _buildAnimation,
            animation: animationController,
          ),
        );
      }
    );
  }

  List<Widget> _buildUpButton() {
    final mathBoxController = Provider.of<MathBoxController>(context, listen:false);
    List<Widget> button = [];
    const fontSize = 25.0;
    const iconSize = 45.0;

    button.add(SignButton(
      child: const Text('sin'),
      fontSize: fontSize,
      fontColor: functionFontColor,
      onPressed: () {
        mathBoxController.addExpression('\\sin');
        mathBoxController.addExpression('(');
      },
    ));

    button.add(SignButton(
      child: const Text('cos'),
      fontSize: fontSize,
      fontColor: functionFontColor,
      onPressed: () {
        mathBoxController.addExpression('\\cos');
        mathBoxController.addExpression('(');
      },
    ));

    button.add(SignButton(
      child: const Text('tan'),
      fontSize: fontSize,
      fontColor: functionFontColor,
      onPressed: () {
        mathBoxController.addExpression('\\\\tan');
        mathBoxController.addExpression('(');
      },
    ));

    button.add(SignButton(
      child: Icon(// sqrt
        const IconData(0xe90a, fontFamily: 'Keyboard'),
        color: functionFontColor,
        size: iconSize,
      ),
      onPressed: () {
        mathBoxController.addExpression('\\sqrt');
      },
    ));

    button.add(SignButton(
      child: Icon(// exp
        const IconData(0xe905, fontFamily: 'Keyboard'),
        color: functionFontColor,
        size: iconSize,
      ),
      onPressed: () {
        mathBoxController.addExpression('e');
        mathBoxController.addExpression('^');
      },
    ));

    button.add(SignButton(
      child: Icon(// pow2
        const IconData(0xe909, fontFamily: 'Keyboard'),
        color: functionFontColor,
        size: iconSize,
      ),
      onPressed: () {
        mathBoxController.addExpression(')');
        mathBoxController.addExpression('^');
        mathBoxController.addExpression('2');
      },
    ));

    button.add(SignButton(
      child: const Text('ln'),
      fontSize: fontSize,
      fontColor: functionFontColor,
      onPressed: () {
        mathBoxController.addExpression('\\ln');
        mathBoxController.addExpression('(');
      },
    ));

    button.add(SignButton(
      child: Icon(// arcsin
        const IconData(0xe903, fontFamily: 'Keyboard'),
        color: functionFontColor,
        size: iconSize,
      ),
      onPressed: () {
        mathBoxController.addExpression('\\arcsin');
        mathBoxController.addExpression('(');
      },
    ));

    button.add(SignButton(
      child: Icon(// arccos
        const IconData(0xe902, fontFamily: 'Keyboard'),
        color: functionFontColor,
        size: iconSize,
      ),
      onPressed: () {
        mathBoxController.addExpression('\\arccos');
        mathBoxController.addExpression('(');
      },
    ));

    button.add(SignButton(
      child: Icon(// arctan
        const IconData(0xe904, fontFamily: 'Keyboard'),
        color: functionFontColor,
        size: iconSize,
      ),
      onPressed: () {
        mathBoxController.addExpression('\\arctan');
        mathBoxController.addExpression('(');
      },
    ));

    button.add(SignButton(
      child: Icon(// nrt
        const IconData(0xe908, fontFamily: 'Keyboard'),
        color: functionFontColor,
        size: iconSize,
      ),
      onPressed: () {
        mathBoxController.addExpression('\\\\nthroot');
      },
    ));

    button.add(SignButton(
      child: Icon(// abs
        const IconData(0xe901, fontFamily: 'Keyboard'),
        color: functionFontColor,
        size: iconSize,
      ),
      onPressed: () {
        mathBoxController.addExpression('\\|');
      },
    ));

    button.add(SignButton(
      child: const Text('('),
      fontSize: fontSize,
      fontColor: functionFontColor,
      onPressed: () {
        mathBoxController.addExpression('(');
      },
    ));

    button.add(SignButton(
      child: const Text(')'),
      fontSize: fontSize,
      fontColor: functionFontColor,
      onPressed: () {
        mathBoxController.addExpression(')');
      },
    ));

    button.add(SignButton(
      child: Icon(// *10^n
        const IconData(0xe900, fontFamily: 'Keyboard'),
        color: functionFontColor,
        size: iconSize,
      ),
      fontSize: fontSize,
      fontColor: functionFontColor,
      onPressed: () {
        mathBoxController.addExpression('E');
      },
    ));

    button.add(SignButton(
      child: const Text('log'),
      fontSize: fontSize,
      fontColor: functionFontColor,
      onPressed: () {
        mathBoxController.addExpression('log');
        mathBoxController.addExpression('_');
        mathBoxController.addKey('Right');
        mathBoxController.addExpression('(');
        mathBoxController.addKey('Left Left');
      },
    ));

    button.add(SignButton(
      child: Icon(// expo
        const IconData(0xe906, fontFamily: 'Keyboard'),
        color: functionFontColor,
        size: iconSize,
      ),
      onPressed: () {
        mathBoxController.addExpression(')');
        mathBoxController.addExpression('^');
      },
    ));

    button.add(NumButton(
      child: const Icon(// frac
        IconData(0xe907, fontFamily: 'Keyboard'),
        size: 40.0,
        color: Colors.white,
      ),
      onPressed: () {
        mathBoxController.addExpression('/', isOperator: true);},
    ));

    button.add(SignButton(
      child: Icon(Icons.arrow_back, color: functionFontColor,),
      onPressed: () {
        mathBoxController.addKey('Left');
      },
      onLongPress: () {
        try {
          final expression = Provider.of<MathModel>(context, listen: false).checkHistory(toPrevious: true);
          mathBoxController.deleteAllExpression();
          mathBoxController.addString(expression);
        } catch (e) {
          final snackBar = SnackBar(
            content: const Text('This is the first result'),
            duration: const Duration(milliseconds: 700,),
            action: SnackBarAction(
              label: 'OK',
              onPressed: (){},
            ),
          );
          Scaffold.of(context).showSnackBar(snackBar);
        }
      },
    ));

    button.add(SignButton(
      child: Icon(Icons.arrow_forward, color: functionFontColor,),
      onPressed: () {
        mathBoxController.addKey('Right');
      },
      onLongPress: () {
        try {
          final expression = Provider.of<MathModel>(context, listen: false).checkHistory(toPrevious: false);
          mathBoxController.deleteAllExpression();
          mathBoxController.addString(expression);
        } catch (e) {
          final snackBar = SnackBar(
            content: const Text('This is the last result'),
            duration: const Duration(milliseconds: 700,),
            action: SnackBarAction(
              label: 'OK',
              onPressed: (){},
            ),
          );
          Scaffold.of(context).showSnackBar(snackBar);
        }
      },
    ));

    button.add(SignButton(
      child: const Text('Ans'),
      fontSize: fontSize,
      fontColor: functionFontColor,
      onPressed: () {
        if (Provider.of<MathModel>(context, listen: false).hasHistory) {
          mathBoxController.addExpression('Ans');
        } else {
          final snackBar = SnackBar(
            content: const Text('Unable to input Ans now'),
            duration: const Duration(milliseconds: 500,),
            action: SnackBarAction(
              label: 'OK',
              onPressed: (){},
            ),
          );
          Scaffold.of(context).showSnackBar(snackBar);
        }
      },
    ));
    return button;
  }

}
