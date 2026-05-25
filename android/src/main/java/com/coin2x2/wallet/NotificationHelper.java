package com.coin2x2.wallet;

import android.app.Activity;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

/**
 * Simple local notifications for wallet events.
 */
public final class NotificationHelper {

    private static final String CHANNEL_ID = "2x2coin_wallet_events";

    private NotificationHelper() {}

    public static void showNotification(
            @NonNull Activity activity,
            @NonNull String title,
            @NonNull String message) {
        createChannel(activity);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(activity, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_launcher)
                .setContentTitle(title)
                .setContentText(message)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setAutoCancel(true);

        NotificationManagerCompat.from(activity).notify(
                (int) System.currentTimeMillis(), builder.build());
    }

    private static void createChannel(Context context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return;
        }
        NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "2X2Coin Wallet",
                NotificationManager.IMPORTANCE_DEFAULT);
        NotificationManager manager =
                (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager != null) {
            manager.createNotificationChannel(channel);
        }
    }
}
