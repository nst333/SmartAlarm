package io.github.nst333.smartalarmver3

import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {

    private val eventChannelName = "io.github.nst333/sleep_data"
    private var eventSink: EventChannel.EventSink? = null

    // 1. SleepTrackingService에서 보내는 AI 추론 결과를 받는 리시버
    private val sleepDataReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == SleepTrackingService.ACTION_SLEEP_DATA) {
                val heartRate = intent.getIntExtra("heartRate", 0)
                val movement = intent.getDoubleExtra("movement", 0.0)
                val hrv = intent.getIntExtra("hrv", 0)
                val sleepStage = intent.getStringExtra("sleepStage") ?: "Unknown"

                val sleepData = mapOf(
                    "heartRate" to heartRate,
                    "movement" to movement,
                    "hrv" to hrv,
                    "sleepStage" to sleepStage
                )

                // 2. 받은 데이터를 플러터 UI로 전송
                eventSink?.success(sleepData)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    startSleepService()
                }

                override fun onCancel(arguments: Any?) {
                    stopSleepService()
                    eventSink = null
                }
            }
        )
    }

    @SuppressLint("UnspecifiedRegisterReceiverFlag")
    private fun startSleepService() {
        // 브로드캐스트 리시버 등록
        val filter = IntentFilter(SleepTrackingService.ACTION_SLEEP_DATA)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(sleepDataReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(sleepDataReceiver, filter)
        }

        // TFLite 추론이 돌아가는 백그라운드 서비스 실행
        val serviceIntent = Intent(this, SleepTrackingService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun stopSleepService() {
        // 리시버 해제 및 서비스 종료
        try {
            unregisterReceiver(sleepDataReceiver)
        } catch (e: Exception) {
            e.printStackTrace()
        }
        val serviceIntent = Intent(this, SleepTrackingService::class.java)
        stopService(serviceIntent)
    }
}