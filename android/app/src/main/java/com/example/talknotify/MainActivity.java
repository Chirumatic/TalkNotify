package com.example.talknotify;

import android.content.ComponentName;
import android.content.Intent;
import android.os.Build;
import android.provider.Settings;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.EventChannel;

import java.util.HashMap;
import java.util.Map;

/**
 * Main Android Activity.
 * Sets up MethodChannel and EventChannel bridges between Flutter and native Android.
 */
public class MainActivity extends FlutterActivity {

    private static final String METHOD_CHANNEL = "com.example.talknotify/notifications";
    private static final String EVENT_CHANNEL  = "com.example.talknotify/message_stream";

    private EventChannel.EventSink eventSink;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Start foreground service so TTS works when app is closed
        Intent serviceIntent = new Intent(this, TalkNotifyForegroundService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent);
        } else {
            startService(serviceIntent);
        }

        // --- Method Channel: permission checks and service control ---
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), METHOD_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "isNotificationAccessGranted":
                        result.success(isNotificationAccessGranted());
                        break;
                    case "requestNotificationAccess":
                        openNotificationAccessSettings();
                        result.success(true);
                        break;
                    case "startNotificationListener":
                        registerNotificationCallback();
                        result.success(true);
                        break;
                    case "stopNotificationListener":
                        NotificationListener.callback = null;
                        result.success(true);
                        break;
                    default:
                        result.notImplemented();
                }
            });

        // --- Event Channel: stream incoming messages to Flutter ---
        new EventChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), EVENT_CHANNEL)
            .setStreamHandler(new EventChannel.StreamHandler() {
                @Override
                public void onListen(Object arguments, EventChannel.EventSink events) {
                    eventSink = events;
                    registerNotificationCallback();
                }

                @Override
                public void onCancel(Object arguments) {
                    eventSink = null;
                    NotificationListener.callback = null;
                }
            });
    }

    /** Register the callback that forwards notifications to Flutter */
    private void registerNotificationCallback() {
        NotificationListener.callback = (sender, message, appSource) -> {
            if (eventSink != null) {
                runOnUiThread(() -> {
                    Map<String, String> data = new HashMap<>();
                    data.put("sender", sender);
                    data.put("message", message);
                    data.put("appSource", appSource);
                    eventSink.success(data);
                });
            }
        };
    }

    /** Check if notification listener permission is granted */
    private boolean isNotificationAccessGranted() {
        String pkgName = getPackageName();
        String flat = Settings.Secure.getString(
            getContentResolver(),
            "enabled_notification_listeners"
        );
        if (!TextUtils.isEmpty(flat)) {
            String[] names = flat.split(":");
            for (String name : names) {
                ComponentName cn = ComponentName.unflattenFromString(name);
                if (cn != null && pkgName.equals(cn.getPackageName())) {
                    return true;
                }
            }
        }
        return false;
    }

    /** Open Android notification access settings page */
    private void openNotificationAccessSettings() {
        Intent intent = new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }
}
