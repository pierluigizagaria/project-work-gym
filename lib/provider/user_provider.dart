import 'package:flutter/material.dart';

import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  late UserApp user = UserApp('', '', '', '', [], '', false);

  void addGym(String gym) {
    user.palestre.add(gym);
    notifyListeners();
  }
}
