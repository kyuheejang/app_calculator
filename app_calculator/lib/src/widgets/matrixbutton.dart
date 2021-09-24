import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_calculator/src/backend/math_model.dart';
import 'package:app_calculator/src/widgets/math_box.dart';

class SingleMatrixButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;

  const SingleMatrixButton({Key? key, required this.child, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: OutlineButton(
        child: child,
        onPressed: onPressed,
        highlightedBorderColor: Colors.blue,
        highlightColor: Colors.blue[200],
        splashColor: Colors.blueAccent,
        borderSide: const BorderSide(
          color: Colors.blue,
          width: 2.0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
      ),
    );
  }
}

class MatrixButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mathBoxController = Provider.of<MathBoxController>(context, listen: false);
    return Container(
      height: 40.0,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          Consumer<MatrixModel>(
            builder: (_, model, child) => model.single?
              const SizedBox(height: 0.0,):
              SingleMatrixButton(
                child: child!,
                onPressed: () {
                  model.calc();
                  mathBoxController.deleteAllExpression();
                  mathBoxController.addString(model.display());
                },
              ),
            child: const Text('Calculate'),
          ),
          Consumer<MatrixModel>(
            builder: (_, model, child) => model.square?
              SingleMatrixButton(
                child: child!,
                onPressed: () {
                  model.invert();
                  mathBoxController.deleteAllExpression();
                  mathBoxController.addString(model.display());
                },
              ):
              const SizedBox(height: 0.0,),
            child: const Text('Invert'),
          ),
          Consumer<MatrixModel>(
            builder: (_, model, child) => model.square?
              SingleMatrixButton(
                child: child!,
                onPressed: () {
                  model.norm();
                  mathBoxController.deleteAllExpression();
                  mathBoxController.addString(model.display());
                },
              ):
              const SizedBox(height: 0.0,),
            child: const Text('Norm'),
          ),
          Consumer<MatrixModel>(
            builder: (_, model, child) => model.single?
              SingleMatrixButton(
                child: child!,
                onPressed: () {
                  model.transpose();
                  mathBoxController.deleteAllExpression();
                  mathBoxController.addString(model.display());
                },
              ):
              const SizedBox(height: 0.0,),
            child: const Text('Transpose'),
          ),
          SingleMatrixButton(
            child: const Text('Add Row'),
            onPressed: () {
              mathBoxController.addKey('Shift-Spacebar');
            },
          ),
          SingleMatrixButton(
            child: const Text('Add Column'),
            onPressed: () {
              mathBoxController.addKey('Shift-Enter');
            },
          ),
        ],
      ),
    );
  }
}