package io.github.nst333.smartalarmver3

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.res.AssetFileDescriptor
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel
import java.util.LinkedList
import kotlin.math.abs
import kotlin.math.pow
import kotlin.math.sqrt

class SleepTrackingService : Service(), SensorEventListener {

    // --- 센서 관련 변수 ---
    private lateinit var sensorManager: SensorManager
    private var heartRateSensor: Sensor? = null
    private var accelerometerSensor: Sensor? = null

    private var currentHeartRate: Int = 0
    private var currentMovement: Double = 0.0
    private var estimatedHrv: Int = 0
    private var lastPredictedStage = "센서 측정 대기중..."

    private var monitoringHandler = Handler(Looper.getMainLooper())
    private var monitoringRunnable: Runnable? = null

    // --- TFLite 딥러닝 추론 관련 변수 ---
    private var interpreter: Interpreter? = null
    private val TIME_STEPS = 20
    private val FEATURES = 6

    // 30초(1 epoch) 단위 데이터를 모으기 위한 임시 리스트
    private val epochHrList = mutableListOf<Float>()
    private val epochXList = mutableListOf<Float>()
    private val epochYList = mutableListOf<Float>()
    private val epochZList = mutableListOf<Float>()
    private var epochSteps = 0f // 만약 걸음수 센서가 있다면 여기에 누적

    // 20 Epoch 분량의 Feature를 저장하는 큐
    private val featureBuffer = LinkedList<FloatArray>()

    companion object {
        const val ACTION_SLEEP_DATA = "io.github.nst333/sleep_data"
    }

    override fun onCreate() {
        super.onCreate()
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        heartRateSensor = sensorManager.getDefaultSensor(Sensor.TYPE_HEART_RATE)
        accelerometerSensor = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        // TFLite 모델 초기화
        try {
            interpreter = Interpreter(loadModelFile(), Interpreter.Options())
        } catch (e: Exception) {
            e.printStackTrace()
        }

        lastPredictedStage = "onCreate DONE"
    }

    private fun loadModelFile(): ByteBuffer {
        val fileDescriptor: AssetFileDescriptor = assets.openFd("apple_watch_sleep_ultimate.tflite")
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, fileDescriptor.startOffset, fileDescriptor.declaredLength)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()
        val notification: Notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, "sleep_channel")
                .setContentTitle("스마트 알람 모니터링 중")
                .setContentText("AI 모델이 수면 단계를 분석하고 있습니다.")
                .setSmallIcon(android.R.drawable.ic_menu_compass)
                .build()
        } else {
            Notification()
        }

        startForeground(1, notification)
        startSensors()
        return START_STICKY
    }

    private fun startSensors() {
        heartRateSensor?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL) }
        accelerometerSensor?.let { sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL) }
        lastPredictedStage = "Sensor Registration DONE"

        monitoringRunnable = object : Runnable {
            override fun run() {
                // ==========================================================
                // 1. [UI 업데이트] 매 1초마다 무조건 플러터로 현재 센서값 전송!
                // ==========================================================
                val broadcastIntent = Intent(ACTION_SLEEP_DATA).apply {
                    setPackage(packageName)

                    putExtra("heartRate", currentHeartRate)
                    putExtra("movement", currentMovement)
                    putExtra("hrv", estimatedHrv)
                    putExtra("sleepStage", lastPredictedStage)
                }
                sendBroadcast(broadcastIntent)

                // ==========================================================
                // 2. [AI 데이터 수집] 백그라운드에서 30초(1 epoch) 단위 데이터 누적
                // ==========================================================
                // 심박수가 0보다 클 때만(워치를 차고 있을 때만) 리스트에 추가
                if (currentHeartRate > 0) {
                    epochHrList.add(currentHeartRate.toFloat())
                }

                // 만약 30초치(30개) 데이터가 다 모였다면?
                if (epochHrList.size >= 30) {
                    val hrMean = calculateMean(epochHrList)
                    val hrStd = calculateStd(epochHrList)
                    val xStd = calculateStd(epochXList)
                    val yStd = calculateStd(epochYList)
                    val zStd = calculateStd(epochZList)

                    val rawFeatures = floatArrayOf(hrMean, hrStd, xStd, yStd, zStd, epochSteps)

                    featureBuffer.add(rawFeatures)
                    if (featureBuffer.size > TIME_STEPS) {
                        featureBuffer.poll()
                    }

                    // 버퍼가 20개(10분) 꽉 찼다면 추론 실행!
                    if (featureBuffer.size == TIME_STEPS) {
                        lastPredictedStage = runInference() // 추론 결과를 변수에 저장
                    } else {
                        // 아직 10분치 데이터가 안 모였을 때의 상태 텍스트
                        lastPredictedStage = "데이터 수집중... (${featureBuffer.size}/20)"
                    }

                    // 다음 30초를 위해 리스트 초기화
                    epochHrList.clear()
                    epochXList.clear()
                    epochYList.clear()
                    epochZList.clear()
                    epochSteps = 0f
                }

                // 1초 뒤 반복 실행
                monitoringHandler.postDelayed(this, 1000)
            }
        }
        monitoringHandler.post(monitoringRunnable!!)
    }

    private fun runInference(): String {
        if (interpreter == null) return "Model Load Failed"

        // 입력 텐서 준비 [1, 20, 6] (Batch 1, TimeSteps 20, Features 6) Float는 4바이트
        val inputBuffer = ByteBuffer.allocateDirect(1 * TIME_STEPS * FEATURES * 4)
        inputBuffer.order(ByteOrder.nativeOrder())

        for (epoch in featureBuffer) {
            for (feature in epoch) {
                inputBuffer.putFloat(feature)
            }
        }

        // 출력 텐서 준비 [1, 4] (클래스 4개)
        val outputBuffer = ByteBuffer.allocateDirect(1 * 4 * 4)
        outputBuffer.order(ByteOrder.nativeOrder())

        // 🔥 추론 실행 (내장된 Keras 정규화 레이어가 스케일링까지 자동 처리)
        interpreter?.run(inputBuffer, outputBuffer)

        outputBuffer.rewind()
        val probabilities = FloatArray(4)
        outputBuffer.asFloatBuffer().get(probabilities)

        // 가장 확률이 높은 클래스(인덱스) 반환
        val maxIndex = probabilities.indices.maxByOrNull { probabilities[it] } ?: 0

        // Python에서 정의한 클래스 맵핑에 맞춰 반환
        return when (maxIndex) {
            0 -> "WAKE"
            1 -> "LIGHT SLEEP"
            2 -> "DEEP SLEEP"
            3 -> "REM SLEEP"
            else -> "UNKNOWN"
        }
    }

    // --- 통계량 계산 헬퍼 함수 (Python의 pandas .std(), .mean()과 동일) ---
    private fun calculateMean(list: List<Float>): Float {
        if (list.isEmpty()) return 0f
        return list.sum() / list.size
    }

    private fun calculateStd(list: List<Float>): Float {
        if (list.size <= 1) return 0f // Python의 .fillna(0)과 동일
        val mean = calculateMean(list)
        var sumOfSquaredDifferences = 0f
        for (value in list) {
            sumOfSquaredDifferences += (value - mean).pow(2)
        }
        // 표본 표준편차 (N-1) 적용
        return sqrt(sumOfSquaredDifferences / (list.size - 1))
    }

    // --- 안드로이드 OS 콜백 함수 (센서 데이터 읽기) ---
    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return
        when (event.sensor.type) {
            Sensor.TYPE_HEART_RATE -> {
                val rawHeartRate = event.values[0].toInt()
                if (rawHeartRate > 0) {
                    if (currentHeartRate > 0) estimatedHrv = abs(currentHeartRate - rawHeartRate) * 10
                    currentHeartRate = rawHeartRate
                }
            }
            Sensor.TYPE_ACCELEROMETER -> {
                val x = event.values[0]
                val y = event.values[1]
                val z = event.values[2]

                // 가속도 벡터계산 (기존 앱 UI 표현용)
                val g = sqrt((x * x + y * y + z * z).toDouble())
                currentMovement = abs(g - 9.81)

                // 30초 단위로 편차를 구하기 위해 Raw xyz 값을 리스트에 누적 (중력 포함 상태 유지 권장)
                epochXList.add(x)
                epochYList.add(y)
                epochZList.add(z)
            }
        }
    }

    override fun onDestroy() {
        sensorManager.unregisterListener(this)
        monitoringRunnable?.let { monitoringHandler.removeCallbacks(it) }
        interpreter?.close() // 메모리 릭 방지
        super.onDestroy()
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("sleep_channel", "수면 측정 알림", NotificationManager.IMPORTANCE_LOW)
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}