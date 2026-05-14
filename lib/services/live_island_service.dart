import 'package:flutter/services.dart';

class LiveIslandService {
  static final LiveIslandService _instance = LiveIslandService._internal();
  factory LiveIslandService() => _instance;
  LiveIslandService._internal();

  static const MethodChannel _channel = MethodChannel('com.nutrimateapp/live_updates');

  Future<void> startIsland() async {
    try {
      await _channel.invokeMethod('startIsland');
    } on PlatformException catch (e) {
      print("Failed to start island: '${e.message}'.");
    }
  }

  Future<void> updateIsland(int progress) async {
    try {
      await _channel.invokeMethod('updateIsland', {'progress': progress});
    } on PlatformException catch (e) {
      print("Failed to update island: '${e.message}'.");
    }
  }

  Future<void> stopIsland() async {
    try {
      await _channel.invokeMethod('stopIsland');
    } on PlatformException catch (e) {
      print("Failed to stop island: '${e.message}'.");
    }
  }
}
