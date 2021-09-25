import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:provider/provider.dart';
import 'package:app_calculator/src/widgets/math_box.dart';
import 'package:app_calculator/src/pages/setting_page.dart';
import 'package:app_calculator/src/backend/math_model.dart';

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
    this.fontColor = Colors.black,
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
  const MathKeyBoard({Key? key}) : super(key: key);

  List<Widget> _buildLowButton(MathBoxController mathBoxController) {
    List<Widget> button = [];

    for (var i = 7; i <= 9; i++) {
      button.add(NumButton(
        child: Text('$i'),
        onPressed: () {mathBoxController.addExpression('$i');},
      ));
    }

    button.add(NumButton(
      child: const Icon(// frac
        IconData(0xe907, fontFamily: 'Keyboard'),
        size: 60.0,
      ),
      onPressed: () {mathBoxController.addExpression('/', isOperator: true);}, onLongPress: () {  },
    ));

    button.add(NumButton(
      child: const Icon(MaterialCommunityIcons.backspace_outline),
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final mathBoxController = Provider.of<MathBoxController>(context, listen: false);
    return SizedBox(
      height: width / 5 * 4 / aspectRatio,
      child: Material(
        color: Colors.grey[300],
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

}

const animationConstant = 8.0;

class AtanCurve extends Curve {
  @override
  double transform(double t) => atan(animationConstant*2*t-animationConstant)/(2*atan(animationConstant))+0.5;
}

class ExpandKeyBoard extends StatefulWidget {
  const ExpandKeyBoard({Key? key}) : super(key: key);

  @override
  _ExpandKeyBoardState createState() => _ExpandKeyBoardState();
}

class _ExpandKeyBoardState extends State<ExpandKeyBoard> with TickerProviderStateMixin {
  late AnimationController animationController;
  late Animation keyboardAnimation;
  late Animation arrowAnimation;
  late double _height;

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
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Material(
        color: Colors.blueAccent[400],
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10.0),
          topLeft: Radius.circular(10.0),
        ),
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
                  color: Colors.grey[200],
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

  @override
  Widget build(BuildContext context) {
    final setting = Provider.of<SettingModel>(context, listen: false);
    return FutureBuilder(
      future: setting.loading.future,
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
    var fontColor = (Colors.grey[200])!;

    button.add(SignButton(
      child: const Text('sin'),
      fontSize: fontSize,
      fontColor: fontColor,
      onPressed: () {
        mathBoxController.addExpression('\\sin');
        mathBoxController.addExpression('(');
      },
    ));

    button.add(SignButton(
      child: const Text('cos'),
      fontSize: fontSize,
      fontColor: fontColor,
      onPressed: () {
        mathBoxController.addExpression('\\cos');
        mathBoxController.addExpression('(');
      },
    ));

    button.add(SignButton(
      child: const Text('tan'),
      fontSize: fontSize,
      fontColor: fontColor,
      onPressed: () {
        mathBoxController.addExpression('\\\\tan');
        mathBoxController.addExpression('(');
      },
    ));

    button.add(SignButton(
      child: Icon(// sqrt
        const IconData(0xe90a, fontFamily: 'Keyboard'),
        color: fontColor,
        size: iconSize,
      ),
      onPressed: () {
        mathBoxController.addExpression('\\sqrt');
      },
    ));

    button.add(SignButton(
      child: Icon(// exp
        const IconData(0xe905, fontFamily: 'Keyboard'),
        color: fontColor,
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
        color: fontColor,
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
      fontColor: fontColor,
      onPressed: () {
        mathBoxController.addExpression('\\ln');
        mathBoxController.addExpression('(');
      },
    ));

    button.add(SignButton(
      child: Icon(// arcsin
        const IconData(0xe903, fontFamily: 'Keyboard'),
        color: fontColor,
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
        color: fontColor,
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
        color: fontColor,
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
        color: fontColor,
        size: iconSize,
      ),
      onPressed: () {
        mathBoxController.addExpression('\\\\nthroot');
      },
    ));

    button.add(SignButton(
      child: Icon(// abs
        const IconData(0xe901, fontFamily: 'Keyboard'),
        color: fontColor,
        size: iconSize,
      ),
      onPressed: () {
        mathBoxController.addExpression('\\|');
      },
    ));

    button.add(SignButton(
      child: const Text('('),
      fontSize: fontSize,
      fontColor: fontColor,
      onPressed: () {
        mathBoxController.addExpression('(');
      },
    ));

    button.add(SignButton(
      child: const Text(')'),
      fontSize: fontSize,
      fontColor: fontColor,
      onPressed: () {
        mathBoxController.addExpression(')');
      },
    ));

    button.add(SignButton(
      child: const Text('!'),
      fontSize: fontSize,
      fontColor: fontColor,
      onPressed: () {
        mathBoxController.addExpression('!');
      },
    ));

    button.add(SignButton(
      child: Icon(// *10^n
        const IconData(0xe900, fontFamily: 'Keyboard'),
        color: fontColor,
        size: iconSize,
      ),
      fontSize: fontSize,
      fontColor: fontColor,
      onPressed: () {
        mathBoxController.addExpression('E');
      },
    ));

    button.add(SignButton(
      child: const Text('log'),
      fontSize: fontSize,
      fontColor: fontColor,
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
        color: fontColor,
        size: iconSize,
      ),
      onPressed: () {
        mathBoxController.addExpression(')');
        mathBoxController.addExpression('^');
      },
    ));

    // button.add(MyButton(
    //   child: Icon(
    //     MaterialCommunityIcons.getIconData("function-variant"), 
    //     color: fontColor,
    //   ),
    //   onPressed: () {
    //     mathBoxController.addExpression('x');
    //   },
    // ));

    button.add(SignButton(
      child: Icon(Icons.arrow_back, color: fontColor,),
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
      child: Icon(Icons.arrow_forward, color: fontColor,),
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
      fontColor: fontColor,
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
