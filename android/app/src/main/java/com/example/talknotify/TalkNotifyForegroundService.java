package com.example.talknotify;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.IBinder;
import android.speech.tts.TextToSpeech;
import android.util.Log;

import androidx.core.app.NotificationCompat;

import java.util.Calendar;
import java.util.Locale;

/**
 * Foreground service that keeps TalkNotify alive in the background.
 * Uses Android's native TextToSpeech to announce incoming messages
 * even when the Flutter app is not open.
 */
public class TalkNotifyForegroundService extends Service implements TextToSpeech.OnInitListener {

    private static final String TAG = "TalkNotifyService";
    private static final String CHANNEL_ID = "talknotify_foreground";
    private static final int NOTIFICATION_ID = 1001;

    private TextToSpeech tts;
    private boolean ttsReady = false;

    // Static reference so NotificationListener can call it directly
    public static TalkNotifyForegroundService instance;

    @Override
    public void onCreate() {
        super.onCreate();
        instance = this;

        // Initialize native TTS
        tts = new TextToSpeech(this, this);

        // Register notification callback — now passes full message content
        NotificationListener.callback = (sender, message, appSource) -> {
            if (isDndActive()) return; // Respect Do Not Disturb hours
            announceMessage(sender, appSource, message);
        };

        Log.d(TAG, "TalkNotify foreground service started");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        startForeground(NOTIFICATION_ID, buildForegroundNotification());
        // Restart if killed by system
        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        instance = null;
        if (tts != null) {
            tts.stop();
            tts.shutdown();
        }
        NotificationListener.callback = null;
    }

    /** Called when TTS engine is ready */
    @Override
    public void onInit(int status) {
        if (status == TextToSpeech.SUCCESS) {
            tts.setLanguage(Locale.US);
            ttsReady = true;
            Log.d(TAG, "TTS initialized successfully");
        } else {
            Log.e(TAG, "TTS initialization failed");
        }
    }

    /** Announce incoming message aloud — reads full message content */
    public void announceMessage(String sender, String appSource, String message) {
        if (!ttsReady || tts == null) return;

        String announcement;
        if (message != null && !message.isEmpty()) {
            announcement = "New " + appSource + " message from " + sender + ". " + message;
        } else {
            announcement = "New " + appSource + " message from " + sender;
        }

        Log.d(TAG, "Announcing: " + announcement);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            tts.speak(announcement, TextToSpeech.QUEUE_FLUSH, null, "msg_" + System.currentTimeMillis());
        } else {
            tts.speak(announcement, TextToSpeech.QUEUE_FLUSH, null);
        }
    }

    /** Build the persistent foreground notification */
    private Notification buildForegroundNotification() {
        createNotificationChannel();

        Intent openAppIntent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_IMMUTABLE
        );

        return new NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("TalkNotify is active")
            .setContentText(isDrivingModeEnabled() ? "🚗 Driving mode ON — reading all messages" : "Listening for incoming messages...")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build();
    }

    /** Check if Do Not Disturb hours are active */
    private boolean isDndActive() {
        SharedPreferences prefs = getSharedPreferences("talknotify_prefs", Context.MODE_PRIVATE);
        boolean dndEnabled = prefs.getBoolean("dnd_enabled", false);
        if (!dndEnabled) return false;

        int dndStart = prefs.getInt("dnd_start_hour", 22); // default 10pm
        int dndEnd   = prefs.getInt("dnd_end_hour", 6);    // default 6am

        int currentHour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY);

        if (dndStart > dndEnd) {
            // Overnight range e.g. 22:00 - 06:00
            return currentHour >= dndStart || currentHour < dndEnd;
        } else {
            return currentHour >= dndStart && currentHour < dndEnd;
        }
    }

    /** Check if driving mode is enabled */
    public boolean isDrivingModeEnabled() {
        SharedPreferences prefs = getSharedPreferences("talknotify_prefs", Context.MODE_PRIVATE);
        return prefs.getBoolean("driving_mode", false);
    }

    /** Check if group messages should be skipped */
    public boolean isSkipGroupMessages() {
        SharedPreferences prefs = getSharedPreferences("talknotify_prefs", Context.MODE_PRIVATE);
        return prefs.getBoolean("skip_group_messages", false);
    }

    /** Set driving mode */
    public void setDrivingMode(boolean enabled) {
        SharedPreferences prefs = getSharedPreferences("talknotify_prefs", Context.MODE_PRIVATE);
        prefs.edit().putBoolean("driving_mode", enabled).apply();
        // Update foreground notification text
        NotificationManager manager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager != null) {
            manager.notify(NOTIFICATION_ID, buildForegroundNotification());
        }
    }

    /** Create notification channel for Android 8+ */
    private void createNotificationChannel() {        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "TalkNotify Background Service",
                NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("Keeps TalkNotify running in the background");
            channel.setShowBadge(false);

            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }
}
