import 'package:flutter/material.dart';

class ColorProvider extends ChangeNotifier {
  Color _selectedColor = Colors.white;

  Color get selectedColor => _selectedColor;

  void setSelectedColor(Color color) {
    _selectedColor = color;
    notifyListeners();
  }
}
