package io.github.nst333.smartalarmver3

import android.content.Context
import android.util.Log
import androidx.health.services.client.HealthServices
import androidx.health.services.client.MeasureCallback
import androidx.health.services.client.data.Availability
import androidx.health.services.client.data.DataPointContainer
import androidx.health.services.client.data.DataType
import androidx.health.services.client.data.DeltaDataType
import kotlinx.coroutines.guava.await

class HealthDataStream(context: Context) {
    private val healthClient = HealthServices.getClient(context)
    private val measureClient = healthClient.measureClient

    private val heartRateCallback = object : MeasureCallback {
        override fun onAvailabilityChanged(dataType: DeltaDataType<*, *>, availability: Availability) {
            Log.d("HealthAPI", "Status Changed : $availability")
        }

        override fun onDataReceived(data: DataPointContainer) {
            val heartRateData = data.getData(DataType.HEART_RATE_BPM)
            heartRateData.forEach { dataPoint ->
                val heartRateValue = dataPoint.value
                Log.d("HealthAPI", "Current HeartRate : $heartRateValue BPM")
            }
        }
    }

    suspend fun checkCapabilities(): Boolean {
        return try {
            val capabilities = measureClient.getCapabilitiesAsync().await()
            // 심박수 측정 기능이 지원되는지 확인
            DataType.HEART_RATE_BPM in capabilities.supportedDataTypesMeasure
        } catch (e: Exception) {
            Log.e("HealthAPI", "기능 확인 실패", e)
            false
        }
    }

    // 4. 측정 시작
    suspend fun startMeasuring() {
        if (!checkCapabilities()) {
            Log.e("HealthAPI", "이 기기에서는 심박수 측정을 지원하지 않습니다.")
            return
        }

        try {
            measureClient.registerMeasureCallback(DataType.HEART_RATE_BPM, heartRateCallback)
            Log.d("HealthAPI", "심박수 측정 시작됨")
        } catch (e: Exception) {
            Log.e("HealthAPI", "측정 시작 실패", e)
        }
    }

    // 5. 측정 종료
    suspend fun stopMeasuring() {
        try {
            measureClient.unregisterMeasureCallbackAsync(DataType.HEART_RATE_BPM, heartRateCallback).await()
            Log.d("HealthAPI", "심박수 측정 종료됨")
        } catch (e: Exception) {
            Log.e("HealthAPI", "측정 종료 실패", e)
        }
    }
}