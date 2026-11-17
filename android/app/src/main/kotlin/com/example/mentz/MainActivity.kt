package com.example.mentz

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hospeda o Flutter e atende o canal `mentz/workout_timer`, que liga o app à
 * notificação do cronômetro ([WorkoutTimerNotification]). Aqui ficam só o
 * registro do canal e o pedido de permissão, que dependem da Activity.
 */
class MainActivity : FlutterActivity() {
    private val notification by lazy { WorkoutTimerNotification(this) }
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(notification.canNotify())
                    "requestPermission" -> requestNotificationPermission(result)
                    "show" -> {
                        notification.show(
                            running = call.argument<Boolean>("running") ?: true,
                            baseMs = call.argument<Number>("baseMs")?.toLong()
                                ?: System.currentTimeMillis(),
                            elapsedMs = call.argument<Number>("elapsedMs")?.toLong() ?: 0L,
                            title = call.argument<String>("title") ?: "Treino em andamento",
                        )
                        result.success(null)
                    }
                    "hide" -> {
                        notification.hide()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU || notification.canNotify()) {
            result.success(notification.canNotify())
            return
        }
        if (pendingPermissionResult != null) {
            // Já existe um pedido aberto: não abre outro diálogo
            result.success(false)
            return
        }
        pendingPermissionResult = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE) {
            pendingPermissionResult?.success(
                grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED,
            )
            pendingPermissionResult = null
        }
    }

    private companion object {
        const val CHANNEL = "mentz/workout_timer"
        const val REQUEST_CODE = 7301
    }
}