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
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sensors,
      Permission.activityRecognition,
      Permission.sensorsAlways,
      Permission.notification,
    ].request();

    print("Permission.sensors: ${statuses[Permission.sensors]}");
    print("Permission.activityRecognition: ${statuses[Permission.activityRecognition]}");
    print("Permission.sensorsAlways: ${statuses[Permission.sensorsAlways]}");
    print("Permission.notification: ${statuses[Permission.notification]}");

    // Wear OS에서 sensorsAlways는 수동 설정이 필요할 수 있으므로, 
    // 일단 sensors와 activityRecognition만으로 판단하거나 로직을 유연하게 가져갑니다.
    bool essentialGranted = (statuses[Permission.sensors]?.isGranted ?? false) &&
                            (statuses[Permission.activityRecognition]?.isGranted ?? false);
    
    return essentialGranted;
  }

  Stream<SleepData> get sleepStateStream {
    return _sleepEventChannel.receiveBroadcastStream().map((dynamic event) {
      final data = Map<dynamic, dynamic>.from(event);
      return SleepData.fromMap(data);
    });
  }
}