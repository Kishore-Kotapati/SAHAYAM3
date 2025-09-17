import 'package:flutter/material.dart';

class MissionProvider extends ChangeNotifier {
  // Example state
  String missionStatus = 'Not started';

  void startMission() {
    missionStatus = 'Started';
    notifyListeners();
  }
}
