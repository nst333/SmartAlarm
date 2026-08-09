package com.example.smartalarmver3

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.github.nst333.smartalarmver3.SleepTrackingService

class MainActivity: FlutterActivity() {
    private val eventChannelName = "io.github.nst333/sleep_data"
    private var sleepDataReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 앱 시작 시 서비스 실행 (이미 실행 중이면 무시됨)
        val intent = Intent(this, SleepTrackingService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }

        // 서비스의 데이터를 Flutter UI로 전달하는 채널 설정
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    // 서비스에서 쏘는 브로드캐스트를 수신하여 Flutter로 전달
                    sleepDataReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            intent?.let {
                                val data = mapOf(
                                    "heartRate" to it.getIntExtra("heartRate", 0),
                                    "movement" to it.getDoubleExtra("movement", 0.0),
                                    "hrv" to it.getIntExtra("hrv", 0),
                                    "sleepStage" to it.getStringExtra("sleepStage")
                                )
                                events?.success(data)
                            }
                        }
                    }

                    val filter = IntentFilter(SleepTrackingService.ACTION_SLEEP_DATA)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        registerReceiver(sleepDataReceiver, filter, Context.RECEIVER_EXPORTED)
                    } else {
                        registerReceiver(sleepDataReceiver, filter)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    sleepDataReceiver?.let {
                        unregisterReceiver(it)
                        sleepDataReceiver = null
                    }
                }
            }
        )
    }

    override fun onDestroy() {
        sleepDataReceiver?.let {
            unregisterReceiver(it)
            sleepDataReceiver = null
        }
        super.onDestroy()
    }
}
