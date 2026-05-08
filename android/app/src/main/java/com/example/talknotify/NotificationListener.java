package com.example.talknotify;

import android.app.Notification;
import android.content.ComponentName;
import android.content.Intent;
import android.os.Bundle;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.util.Log;

import java.util.HashMap;
import java.util.Map;

/**
 * Android Notification Listener Service.
 * Intercepts notifications from supported apps and forwards them to Flutter.
 */
public class NotificationListener extends NotificationListenerService {

    private static final String TAG = "TalkNotifyListener";

    // Package names of supported apps
    private static final Map<String, String> SUPPORTED_APPS = new HashMap<>();

    static {
        SUPPORTED_APPS.put("com.whatsapp", "WhatsApp");
        SUPPORTED_APPS.put("com.whatsapp.w4b", "WhatsApp Business");
        SUPPORTED_APPS.put("org.telegram.messenger", "Telegram");
        SUPPORTED_APPS.put("com.facebook.orca", "Messenger");
        SUPPORTED_APPS.put("com.instagram.android", "Instagram");
        SUPPORTED_APPS.put("com.google.android.apps.messaging", "SMS");
        SUPPORTED_APPS.put("com.android.mms", "SMS");
        SUPPORTED_APPS.put("com.samsung.android.messaging", "SMS");
    }

    // Static callback so MainActivity can register a listener
    public static NotificationCallback callback;

    public interface NotificationCallback {
        void onNotificationReceived(String sender, String message, String appSource);
    }

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        String packageName = sbn.getPackageName();

        // Only process supported apps
        if (!SUPPORTED_APPS.containsKey(packageName)) return;

        String appSource = SUPPORTED_APPS.get(packageName);
        Notification notification = sbn.getNotification();
        Bundle extras = notification.extras;

        if (extras == null) return;

        // Extract sender and message text
        CharSequence titleSeq = extras.getCharSequence(Notification.EXTRA_TITLE);
        CharSequence textSeq = extras.getCharSequence(Notification.EXTRA_TEXT);

        String sender = titleSeq != null ? titleSeq.toString() : "Unknown";
        String message = textSeq != null ? textSeq.toString() : "";

        // Skip group summary notifications (they are duplicates)
        if ((notification.flags & Notification.FLAG_GROUP_SUMMARY) != 0) return;

        Log.d(TAG, "New notification from " + appSource + ": " + sender + " - " + message);

        // Forward to Flutter via callback
        if (callback != null && !message.isEmpty()) {
            callback.onNotificationReceived(sender, message, appSource);
        }
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        // Not needed for now
    }
}
