package com.gbi_logistics.gbi_logistics

import android.media.RingtoneManager
import android.media.Ringtone
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.gbilogistics/sounds"
    private var errorRingtone: Ringtone? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playErrorSound" -> {
                    try {
                        // Detener sonido anterior si existe
                        errorRingtone?.stop()
                        
                        // Usar TYPE_ALARM para un sonido más fuerte y de error
                        val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                        errorRingtone = RingtoneManager.getRingtone(applicationContext, alarmUri)
                        errorRingtone?.play()
                        
                        // Detener después de 500ms para que sea corto
                        handler.postDelayed({
                            errorRingtone?.stop()
                        }, 500)
                        
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SOUND_ERROR", "Error playing sound: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
