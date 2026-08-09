import "dart:async";

import "package:flutter/material.dart";
import 'package:wear/wear.dart';
import 'package:wearable_rotary/wearable_rotary.dart';
import "package:smartalarmver3/elegant.dart";
import "package:smartalarmver3/elegant_btn.dart";
import 'package:smartalarmver3/sleep_service.dart';

void main() {
  runApp(
    const MaterialApp(
      home: MyApp(),
      debugShowCheckedModeBanner: false,
    )
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TimeOfDay? _selectedTime;

  final SleepMonitorService _sleepService = SleepMonitorService();

  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    print("Checking permissions...");
    bool granted = await _sleepService.requestPermissions();
    print("Permissions granted result: $granted");
    setState(() {
      _hasPermission = granted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double paddingValue = screenSize.width * 0.05;

    return ElegantBackground(
      width: screenSize.width,
      height: screenSize.height,
      child: WatchShape(
        builder: (context, shape, child) {
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(paddingValue),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasPermission)
                    StreamBuilder<SleepData>(
                      stream: _sleepService.sleepStateStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text("통신 오류", 
                            style: TextStyle(color: Colors.red, fontSize: screenSize.width * 0.05));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text("데이터 대기중...", 
                            style: TextStyle(color: Colors.white70, fontSize: screenSize.width * 0.05));
                        }

                        final data = snapshot.data!;

                        return Container(
                          padding: EdgeInsets.all(screenSize.width * 0.04),
                          margin: EdgeInsets.symmetric(horizontal: screenSize.width * 0.05),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Predict : ${data.predictedStage}",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: screenSize.width * 0.05,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              Divider(color: Colors.white24, height: screenSize.width * 0.04,),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildDataColumn(Icons.favorite, Colors.redAccent, "${data.heartRate}", screenSize.width),
                                  _buildDataColumn(Icons.directions_run, Colors.blueAccent, data.movement.toStringAsFixed(1), screenSize.width),
                                  _buildDataColumn(Icons.monitor_heart, Colors.purpleAccent, "${data.hrv}", screenSize.width),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    )
                  else
                    GestureDetector(
                      onTap: _checkPermission,
                      child: Text(
                        "권한 필요\n(터치하여 요청)",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orangeAccent, fontSize: screenSize.width * 0.05),
                      ),
                    ),

                  SizedBox(height: screenSize.height * 0.04,),
                  Text(
                    _selectedTime == null
                        ? "시간 미설정"
                        : "설정: ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(color: Colors.white, fontSize: screenSize.width * 0.055, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: screenSize.height * 0.04),
                  SizedBox(
                    width: screenSize.width * 0.6,
                    height: screenSize.height * 0.22,
                    child: GlassmorphismBtn(
                      text: "시간 선택",
                      onPressed: () async {
                        final TimeOfDay? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WearTimePicker(),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            _selectedTime = result;
                          });
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

Widget _buildDataColumn(IconData icon, Color iconColor, String value, double screenWidth) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: iconColor, size: screenWidth * 0.07,),
      SizedBox(height: screenWidth * 0.01,),
      Text(value, style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.035),),
    ],
  );
}

class WearTimePicker extends StatefulWidget {
  const WearTimePicker({super.key});

  @override
  State<WearTimePicker> createState() => _WearTimePickerState();
}

class _WearTimePickerState extends State<WearTimePicker> {
  final FixedExtentScrollController _hourController = FixedExtentScrollController(initialItem: 7);
  final FixedExtentScrollController _minuteController = FixedExtentScrollController(initialItem: 0);

  late StreamSubscription<RotaryEvent> _rotarySubscription;

  bool isHourFocused = true;

  @override
  void initState() {
    super.initState();

    _rotarySubscription = rotaryEvents.listen((RotaryEvent event) {
      final targetController = isHourFocused ? _hourController : _minuteController;
      final maxCount = isHourFocused ? 24 : 60;

      int currentIndex = targetController.selectedItem;
      int nextIndex;

      if (event.direction == RotaryDirection.clockwise) {
        nextIndex = currentIndex + 1;
      } else {
        nextIndex = currentIndex - 1;
      }

      if (nextIndex < 0) nextIndex = maxCount - 1;
      if (nextIndex >= maxCount) nextIndex = 0;

      targetController.animateToItem(
        nextIndex,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _rotarySubscription.cancel();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isHourFocused ? "시간을 맞추세요" : "분을 맞추세요",
              style: TextStyle(color: Colors.blueAccent, fontSize: screenSize.width * 0.05),
            ),
            SizedBox(height: screenSize.height * 0.05),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWheel(
                  controller: _hourController,
                  itemCount: 24,
                  isFocused: isHourFocused,
                  onTap: () => setState(() => isHourFocused = true),
                  screenWidth: screenSize.width,
                ),
                Text(":", style: TextStyle(color: Colors.white, fontSize: screenSize.width * 0.08, fontWeight: FontWeight.bold)),
                _buildWheel(
                  controller: _minuteController,
                  itemCount: 60,
                  isFocused: !isHourFocused,
                  onTap: () => setState(() => isHourFocused = false),
                  screenWidth: screenSize.width,
                ),
              ],
            ),
            SizedBox(height: screenSize.height * 0.05),
            SizedBox(
              width: screenSize.width * 0.25,
              height: screenSize.width * 0.25,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white24,
                ),
                onPressed: () {
                  final pickedTime = TimeOfDay(
                    hour: _hourController.selectedItem,
                    minute: _minuteController.selectedItem,
                  );
                  Navigator.pop(context, pickedTime);
                },
                child: Icon(Icons.check, color: Colors.white, size: screenSize.width * 0.1),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required bool isFocused,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth * 0.25,
        height: screenWidth * 0.4,
        decoration: BoxDecoration(
          color: isFocused ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: screenWidth * 0.15,
          perspective: 0.005,
          diameterRatio: 1.2,
          physics: const FixedExtentScrollPhysics(),
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              final displayValue = index.toString().padLeft(2, '0');
              return Center(
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: screenWidth * 0.12,
                    color: isFocused ? Colors.white : Colors.white38,
                    fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
            childCount: itemCount,
          ),
        ),
      ),
    );
  }
}
