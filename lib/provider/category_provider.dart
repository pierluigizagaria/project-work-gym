import 'package:flutter/material.dart';

class CategoryProvider extends ChangeNotifier {
  String? category;

  void changeValue(String newValue) {
    category = newValue;
    notifyListeners();
  }
}
