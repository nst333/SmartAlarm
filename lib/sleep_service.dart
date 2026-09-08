import 'dart:async';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SleepData {
  final int heartRate;
  final double movement;
  final int hrv;
  final String predictedStage;

  SleepData({
    required this.heartRate,
    required this.movement,
    required this.hrv,
    required this.predictedStage,
  });

  factory SleepData.fromMap(Map<dynamic, dynamic> map) {
    return SleepData(
      heartRate: map['heartRate'] ?? 0,
      movement: (map['movement'] ?? 0.0).toDouble(),
      hrv: map['hrv'] ?? 0,
      predictedStage: map['sleepStage'] ?? 'Unknown'
    );
  }
}

class SleepMonitorService {
  static const EventChannel _sleepEventChannel = EventChannel('io.github.nst333/sleep_data');

  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> basicStatuses = await [
      Permission.sensors,
      Permission.activityRecognition,
      Permission.notification,
    ].request();

    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Permission.sensors: ${basicStatuses[Permission.sensors]}");
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Permission.activityRecognition: ${basicStatuses[Permission.activityRecognition]}");
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Permission.notification: ${basicStatuses[Permission.notification]}");

    bool essentialGranted = (basicStatuses[Permission.sensors]?.isGranted ?? false) &&
        (basicStatuses[Permission.activityRecognition]?.isGranted ?? false);

    if (basicStatuses[Permission.sensors]?.isGranted == true) {
      PermissionStatus alwaysStatus = await Permission.sensorsAlways.request();
      print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Permission.sensorsAlways: $alwaysStatus");
    } else {
      print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Permission.sensorsAlways: 요청 불가 (기본 권한 거절됨)");
    }

    // Wear OS 특성상 essentialGranted만으로 기본 작동 여부를 판단합니다.
    return essentialGranted;
  }

  Stream<SleepData> get sleepStateStream {
    return _sleepEventChannel.receiveBroadcastStream().map((dynamic event) {
      final data = Map<dynamic, dynamic>.from(event);
      return SleepData.fromMap(data);
    });
  }
}