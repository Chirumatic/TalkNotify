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

        // Skip download/progress notifications
        if (isDownloadNotification(notification, extras, message)) {
            Log.d(TAG, "Skipping download notification");
            return;
        }

        // Detect group messages
        boolean isGroupMessage = isGroupMessage(extras, appSource, sender, message);

        // Check skip group setting EARLY — before forwarding anywhere
        boolean skipGroups = TalkNotifyForegroundService.instance != null
            && TalkNotifyForegroundService.instance.isSkipGroupMessages();

        if (isGroupMessage && skipGroups) {
            Log.d(TAG, "Skipping group message from: " + sender);
            return;
        }

        // Check per-app setting — skip if this app is disabled in settings
        if (!isAppEnabled(appSource)) {
            Log.d(TAG, "Skipping message — app disabled: " + appSource);
            return;
        }

        Log.d(TAG, "New notification from " + appSource + ": " + sender + " - " + message
            + (isGroupMessage ? " [GROUP]" : " [DIRECT]"));

        // Forward to Flutter
        if (callback != null && !message.isEmpty()) {
            callback.onNotificationReceived(
                sender,
                message,
                appSource + (isGroupMessage ? "|group" : "|direct")
            );
        }

        // Announce via foreground service TTS
        if (TalkNotifyForegroundService.instance != null && !message.isEmpty()) {
            TalkNotifyForegroundService.instance.announceMessage(sender, appSource, message);
        }

        // Update home screen widget
        TalkNotifyWidget.updateWidgets(this, sender, message, appSource);
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        // Not needed for now
    }

    /**
     * Detect if a notification is a download/progress notification.
     * WhatsApp shows these when downloading photos, videos, documents.
     */
    private boolean isDownloadNotification(Notification notification, Bundle extras, String message) {
        // Method 1: Check if it's an ongoing/progress notification
        // Download notifications are always ongoing and have a progress bar
        if ((notification.flags & Notification.FLAG_ONGOING_EVENT) != 0) {
            return true;
        }

        // Method 2: Check for progress indicator in extras
        int progress = extras.getInt(Notification.EXTRA_PROGRESS, -1);
        int progressMax = extras.getInt(Notification.EXTRA_PROGRESS_MAX, -1);
        if (progress >= 0 && progressMax > 0) {
            return true;
        }

        // Method 3: Check for indeterminate progress
        boolean indeterminate = extras.getBoolean(Notification.EXTRA_PROGRESS_INDETERMINATE, false);
        if (indeterminate) {
            return true;
        }

        // Method 4: Message content patterns for downloads
        String lowerMessage = message.toLowerCase();
        if (lowerMessage.contains("downloading") ||
            lowerMessage.contains("download") ||
            lowerMessage.contains("uploading") ||
            lowerMessage.contains("% complete") ||
            lowerMessage.contains("kb/s") ||
            lowerMessage.contains("mb/s") ||
            lowerMessage.matches(".*\\d+%.*") ||
            lowerMessage.matches(".*\\d+\\.\\d+ (kb|mb|gb).*")) {
            return true;
        }

        // Method 5: Check notification category
        String category = notification.category;
        if (android.app.Notification.CATEGORY_PROGRESS.equals(category) ||
            android.app.Notification.CATEGORY_SERVICE.equals(category)) {
            return true;
        }

        return false;
    }

    /**
     * Check if a given app is enabled in settings.
     * Reads from Android SharedPreferences synced from Flutter.
     */
    private boolean isAppEnabled(String appSource) {
        android.content.SharedPreferences prefs = getSharedPreferences(
            "talknotify_prefs", android.content.Context.MODE_PRIVATE);

        switch (appSource.toLowerCase()) {
            case "whatsapp":
            case "whatsapp business":
                return prefs.getBoolean("readWhatsApp", true);
            case "sms":
                return prefs.getBoolean("readSms", true);
            case "telegram":
                return prefs.getBoolean("readTelegram", true);
            case "messenger":
                return prefs.getBoolean("readMessenger", true);
            case "instagram":
                return prefs.getBoolean("readInstagram", true);
            default:
                return true;
        }
    }

    /**
     * Detect if a notification is from a group chat.
     * Uses multiple detection methods for accuracy.
     */
    private boolean isGroupMessage(Bundle extras, String appSource, String title, String text) {
        // Log all extras for debugging
        Log.d(TAG, "=== Group Detection Debug ===");
        Log.d(TAG, "Title: " + title);
        Log.d(TAG, "Text: " + text);
        
        // Method 1: Check EXTRA_CONVERSATION_TITLE (Android 11+)
        CharSequence convTitle = extras.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE);
        if (convTitle != null && !convTitle.toString().isEmpty()) {
            Log.d(TAG, "DETECTED GROUP via CONVERSATION_TITLE: " + convTitle);
            return true;
        }

        // Method 2: Check EXTRA_SUB_TEXT (WhatsApp uses this for group name)
        CharSequence subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT);
        if (subText != null && !subText.toString().isEmpty()) {
            Log.d(TAG, "DETECTED GROUP via SUB_TEXT: " + subText);
            return true;
        }

        // Method 3: Check if notification is part of a conversation (Android 10+)
        CharSequence[] messages = extras.getCharSequenceArray(Notification.EXTRA_MESSAGES);
        if (messages != null && messages.length > 0) {
            // This is a messaging style notification - check if it's a group
            // In groups, the title is the group name, not the sender
            Log.d(TAG, "DETECTED MESSAGING_STYLE notification");
        }

        // Method 4: WhatsApp/Telegram pattern - "SenderName: message text"
        // In groups, the text contains "Name: message" and title is the group name
        if (text.contains(": ")) {
            int colonIndex = text.indexOf(": ");
            if (colonIndex > 0 && colonIndex < 40) {
                String possibleSender = text.substring(0, colonIndex).trim();
                
                // If the sender in the text doesn't match the title, it's a group
                // Title = group name, Text = "PersonName: actual message"
                if (!possibleSender.equalsIgnoreCase(title.trim())) {
                    Log.d(TAG, "DETECTED GROUP via pattern mismatch");
                    Log.d(TAG, "Title: '" + title + "' vs Sender in text: '" + possibleSender + "'");
                    return true;
                }
            }
        }

        // Method 5: Check for multiple participants indicator
        CharSequence infoText = extras.getCharSequence(Notification.EXTRA_INFO_TEXT);
        if (infoText != null) {
            String info = infoText.toString();
            // WhatsApp shows participant count like "3 participants"
            if (info.contains("participant") || info.contains("member")) {
                Log.d(TAG, "DETECTED GROUP via INFO_TEXT: " + info);
                return true;
            }
        }

        Log.d(TAG, "DETECTED as DIRECT message");
        return false;
    }
}
