package com.example.mentz

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build

/**
 * Notificação persistente do cronômetro de treino.
 *
 * O tempo NÃO é contado pelo app. A notificação usa o cronômetro do próprio
 * sistema (`setUsesChronometer` + `setWhen`), que continua contando com o app
 * em segundo plano, com a tela bloqueada e até com o processo encerrado.
 * Por isso não é preciso um Foreground Service para o tempo ficar certo.
 *
 * Só cuida de montar, publicar e remover a notificação; o canal de
 * comunicação com o Flutter e o pedido de permissão ficam no [MainActivity].
 */
class WorkoutTimerNotification(private val context: Context) {

    private val manager: NotificationManager
        get() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    /** Antes do Android 13 não há permissão em tempo de execução. */
    fun canNotify(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            manager.areNotificationsEnabled()
        } else {
            true
        }

    /**
     * Publica ou atualiza a notificação (mesmo id, então é atualizada no lugar).
     *
     * Rodando, o sistema conta a partir de [baseMs]. Pausado, mostra
     * [elapsedMs] parado.
     */
    fun show(running: Boolean, baseMs: Long, elapsedMs: Long, title: String) {
        createChannel()

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
        }

        builder
            .setSmallIcon(R.drawable.ic_stat_timer)
            .setContentTitle(title)
            .setContentIntent(openAppIntent())
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setVisibility(Notification.VISIBILITY_PUBLIC)

        if (running) {
            builder
                .setWhen(baseMs)
                .setShowWhen(true)
                .setUsesChronometer(true)
                .setContentText("Toque para voltar ao treino")
        } else {
            builder
                .setShowWhen(false)
                .setUsesChronometer(false)
                .setContentText("Pausado em ${formatHms(elapsedMs)}")
        }

        manager.notify(NOTIFICATION_ID, builder.build())
    }

    /** Remove a notificação. */
    fun hide() = manager.cancel(NOTIFICATION_ID)

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        // IMPORTANCE_LOW: aparece sem som nem vibração a cada atualização
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Treino em andamento",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Cronômetro do treino em andamento"
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    /** Tocar na notificação abre (ou traz para a frente) o app. */
    private fun openAppIntent(): PendingIntent? {
        val launchIntent =
            context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return null
        return PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun formatHms(ms: Long): String {
        val total = ms / 1000
        return String.format("%02d:%02d:%02d", total / 3600, (total / 60) % 60, total % 60)
    }

    private companion object {
        const val CHANNEL_ID = "workout_timer"
        const val NOTIFICATION_ID = 7301
    }
}