package com.example.talknotify;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
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
 * Bridges Flutter (Dart) and Android native (Java).
 */
public class MainActivity extends FlutterActivity {

    private static final String METHOD_CHANNEL = "com.example.talknotify/notifications";
    private static final String EVENT_CHANNEL  = "com.example.talknotify/message_stream";
    private static final String PREFS_NAME     = "talknotify_prefs";

    private EventChannel.EventSink eventSink;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Start foreground service
        Intent serviceIntent = new Intent(this, TalkNotifyForegroundService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent);
        } else {
            startService(serviceIntent);
        }

        // Method Channel
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
                    case "syncSettings":
                        // Save Flutter settings to Android SharedPreferences
                        // so native services (NotificationListener, ForegroundService) can read them
                        if (call.arguments instanceof Map) {
                            syncNativeSettings((Map<?, ?>) call.arguments);
                        }
                        result.success(true);
                        break;
                    default:
                        result.notImplemented();
                }
            });

        // Event Channel — streams messages to Flutter
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

    /**
     * Save settings from Flutter into Android SharedPreferences.
     * This allows NotificationListener and ForegroundService to read them
     * even when Flutter is not running.
     */
    private void syncNativeSettings(Map<?, ?> settings) {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();

        for (Map.Entry<?, ?> entry : settings.entrySet()) {
            String key = entry.getKey().toString();
            Object value = entry.getValue();

            if (value instanceof Boolean) {
                editor.putBoolean(key, (Boolean) value);
            } else if (value instanceof Integer) {
                editor.putInt(key, (Integer) value);
            } else if (value instanceof String) {
                editor.putString(key, (String) value);
            }
        }

        editor.apply();
    }

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

    private boolean isNotificationAccessGranted() {
        String pkgName = getPackageName();
        String flat = Settings.Secure.getString(
            getContentResolver(), "enabled_notification_listeners");
        if (!TextUtils.isEmpty(flat)) {
            for (String name : flat.split(":")) {
                ComponentName cn = ComponentName.unflattenFromString(name);
                if (cn != null && pkgName.equals(cn.getPackageName())) return true;
            }
        }
        return false;
    }

    private void openNotificationAccessSettings() {
        Intent intent = new Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }
}
