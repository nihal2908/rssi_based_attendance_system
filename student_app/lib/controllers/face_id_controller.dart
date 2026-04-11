import 'package:flutter/foundation.dart';

class FaceIdController extends ChangeNotifier {
  void initiateFaceIdSetup() {}
  Future<Map<String, dynamic>> checkRequestStatus() async {
    return await Future.value({});
  }
}
