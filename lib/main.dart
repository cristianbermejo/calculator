import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CalculatorHomePage(title: ''),
    );
  }
}

class CalculatorHomePage extends StatefulWidget {
  const CalculatorHomePage({super.key, required this.title});

  final String title;

  @override
  State<CalculatorHomePage> createState() => _CalculatorHomePageState();
}

class _CalculatorHomePageState extends State<CalculatorHomePage> {
  // TODO Look for an alternative to double for decimal numbers
  // double seems to have many precision issues, results are unexpected
  List<double> _numbers = [0, 0];
  bool _fractional = false;
  Function _operatorFunction = () {};
  bool _equalsButtonPressed = false;

  void _handleButtonPress(String label) {
    int? number = int.tryParse(label);
    if (number != null) {
      _handleNumericButtonPress(number.toDouble());
    } else if (label == "C") {
      _handleClearButtonPress();
    } else if (label == "±") {
      _handleChangeSignButtonPress();
    } else if (label == "%") {
      _handlePercentButtonPress();
    } else if (label == "√") {
      _handleSquareRootButtonPress();
    } else if (label == "÷") {
      _handleOperatorButtonPress(_divideOperatorFunction);
    } else if (label == "×") {
      _handleOperatorButtonPress(_multiplyOperatorFunction);
    } else if (label == "−") {
      _handleOperatorButtonPress(_substractOperatorFunction);
    } else if (label == ".") {
      _handleDecimalPointButtonPress();
    } else if (label == "=") {
      _handleEqualsButtonPress();
    } else if (label == "+") {
      _handleOperatorButtonPress(_addOperatorFunction);
    }
  }

  void _handleNumericButtonPress(double number) {
    // Reset the variables if the last button pressed was the equals
    if (_equalsButtonPressed) {
      _numbers[0] = 0;
      _numbers[1] = 0;
      _operatorFunction = () {};
      _equalsButtonPressed = false;
    }

    // Don't add leading zeros to the integer part
    if (_numbers[0] > 0 || number > 0) {
      if (_fractional) {
        if (_numbers[0] == _numbers[0].truncate()) {
          number = number / 10;
        } else {
          double fractionalPart = _numbers[0] - _numbers[0].truncate();
          int decimalPlaces = 1;
          // FIXME This should work, but doubles are not precise enough
          while (fractionalPart.ceil() != fractionalPart.floor()) {
            fractionalPart = fractionalPart * 10 - (fractionalPart * 10).truncate();
            decimalPlaces++;
          }
          number = number / pow(10, decimalPlaces);
        }
      }

      // FIXME Positive values switch to negative in some cases
      // If the number we're concatenating to is negative, the number to
      // concatenate should be negative too
      if (_numbers[0].isNegative) {
        number = -number;
      }

      // Calculate the new value
      // Only change the position of the current numbers if we're not adding
      // numbers to the fractional part
      double newValue = (_numbers[0] * (!_fractional ? 10 : 1)) + number;

      // Only update the value if that won't result in an overflow
      // This if logic goes as follows:
      // - If the number is positive, its power of 10 should be a greater number
      // - If the number is zero, it's power of 10 should be also zero
      // - If the number is negative, its power of 10 should be a lower number
      if ((!_numbers[0].isNegative == (newValue >= _numbers[0]))
        && newValue.isFinite) {

        setState(() => _numbers[0] = newValue);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Unable to perform operation.")
        ));
      }
    }
  }

  void _handleClearButtonPress() => setState(() {
    _numbers = [0, 0];
    _fractional = false;
    _operatorFunction = () {};
  });

  void _handleChangeSignButtonPress() => setState(() => _numbers[0] = -_numbers[0]);

  void _handlePercentButtonPress() {
    double result;
    if (_operatorFunction != _divideOperatorFunction
      && _operatorFunction != _multiplyOperatorFunction) {

      result = ((_numbers[1] * _numbers[0]) / 100);
    } else {
      result = (_numbers[0] / 100);
    }

    setState(() => _numbers[0] = result);
  }

  void _handleSquareRootButtonPress() => setState(() {
    _numbers[0] = sqrt(_numbers[0]);
  });

  void _handleOperatorButtonPress(Function operatorFunction) => setState(() {
    _numbers[1] = _numbers[0];
    _numbers[0] = 0;
    _operatorFunction = operatorFunction;
    _equalsButtonPressed = false;
  });

  void _handleDecimalPointButtonPress() => setState(() {
    _fractional = true;
  });

  void _handleEqualsButtonPress() {
    // The numbers should only be flipped once
    if (!_equalsButtonPressed) {
      double aux = _numbers[0];
      _numbers[0] = _numbers[1];
      _numbers[1] = aux;
    }

    double result = _operatorFunction();
    if (result.isFinite) {
      setState(() {
        _numbers[0] = result;
        _fractional = false;
        _equalsButtonPressed = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Unable to perform operation.")
      ));
    }
  }

  void _divideOperatorFunction() => (_numbers[0] / _numbers[1]);

  void _multiplyOperatorFunction() => _numbers[0] * _numbers[1];

  void _substractOperatorFunction() => _numbers[0] - _numbers[1];

  void _addOperatorFunction() => _numbers[0] + _numbers[1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: NavigationToolbar.kMiddleSpacing
                ),
                child: Text(
                  '${_numbers[0]}',
                  style: Theme.of(context).textTheme.headlineLarge
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(children: [Expanded(child: _buildKeyboard(context))]),
    );
  }

  Widget _buildKeyboard(BuildContext context) {
    List<Widget> rows = [];
    List<List<String>> labelLists = [
      ["C", "±", "%", "√"],
      ["7", "8", "9", "÷"],
      ["4", "5", "6", "×"],
      ["1", "2", "3", "−"],
      ["0", ".", "=", "+"],
    ];

    for (final labels in labelLists) {
      List<Widget> buttons = [];

      for (final label in labels) {
        buttons.add(
          // This Expanded widget makes the buttons fill the horizontal space
          Expanded(child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilledButton.tonal(
              onPressed: () => _handleButtonPress(label),
              child: Text(label)
            ),
          ))
        );
      }

      rows.add(
        // This Expanded widget makes the rows fill the vertical space
        Expanded(child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: buttons
        ))
      );
    }

    return Column(children: rows);
  }
}
