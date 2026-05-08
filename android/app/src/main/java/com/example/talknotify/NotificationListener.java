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

        // Detect group messages:
        // WhatsApp/Telegram group messages have format "Sender: message text" in the body
        // and the title is the group name (contains no phone number pattern)
        boolean isGroupMessage = isGroupMessage(extras, appSource, sender, message);

        Log.d(TAG, "New notification from " + appSource + ": " + sender + " - " + message
            + (isGroupMessage ? " [GROUP]" : " [DIRECT]"));

        // Forward to Flutter — include isGroup flag so Flutter can filter
        if (callback != null && !message.isEmpty()) {
            callback.onNotificationReceived(
                sender,
                message,
                appSource + (isGroupMessage ? "|group" : "|direct")
            );
        }

        // Announce via foreground service TTS
        if (TalkNotifyForegroundService.instance != null && !message.isEmpty()) {
            // Check if foreground service should skip group messages
            boolean skipGroups = TalkNotifyForegroundService.instance.isSkipGroupMessages();
            if (isGroupMessage && skipGroups) return;
            TalkNotifyForegroundService.instance.announceMessage(sender, appSource, message);
        }
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        // Not needed for now
    }

    /**
     * Detect if a notification is from a group chat.
     *
     * WhatsApp group messages:
     *   - EXTRA_TITLE = group name (e.g. "Family Group")
     *   - EXTRA_TEXT  = "SenderName: message text"
     *
     * Telegram group messages:
     *   - EXTRA_TITLE = group name
     *   - EXTRA_SUB_TEXT or EXTRA_TEXT contains "SenderName: ..."
     *
     * Direct messages have the sender name as the title directly.
     */
    private boolean isGroupMessage(Bundle extras, String appSource, String title, String text) {
        // Method 1: Check EXTRA_CONVERSATION_TITLE (set for group chats on Android)
        CharSequence convTitle = extras.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE);
        if (convTitle != null && !convTitle.toString().isEmpty()) {
            return true;
        }

        // Method 2: WhatsApp/Telegram group messages have "Sender: text" pattern in body
        // while the title is the group name
        if (text.contains(": ")) {
            // If text starts with "SomeName: " it's likely a group message
            int colonIndex = text.indexOf(": ");
            if (colonIndex > 0 && colonIndex < 30) {
                // Extra check: the part before ":" should not be the same as the title
                String possibleSender = text.substring(0, colonIndex);
                if (!possibleSender.equalsIgnoreCase(title)) {
                    return true;
                }
            }
        }

        // Method 3: Check EXTRA_SUB_TEXT which WhatsApp sets to group name
        CharSequence subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT);
        if (subText != null && !subText.toString().isEmpty()) {
            return true;
        }

        return false;
    }
}
