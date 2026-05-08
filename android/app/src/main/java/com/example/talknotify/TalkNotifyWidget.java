package com.example.talknotify;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.widget.RemoteViews;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/**
 * Home screen widget that shows the latest message.
 * Updated whenever a new message arrives via NotificationListener.
 */
public class TalkNotifyWidget extends AppWidgetProvider {

    public static final String ACTION_READ_MESSAGE = "com.example.talknotify.READ_MESSAGE";
    private static final String PREFS = "talknotify_widget";

    /** Call this to update all widgets when a new message arrives */
    public static void updateWidgets(Context context, String sender,
                                     String message, String appSource) {
        // Save to widget prefs
        SharedPreferences prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        prefs.edit()
            .putString("sender", sender)
            .putString("message", message)
            .putString("appSource", appSource)
            .putLong("timestamp", System.currentTimeMillis())
            .apply();

        // Trigger widget update
        AppWidgetManager manager = AppWidgetManager.getInstance(context);
        int[] ids = manager.getAppWidgetIds(
            new android.content.ComponentName(context, TalkNotifyWidget.class));
        if (ids.length > 0) {
            new TalkNotifyWidget().onUpdate(context, manager, ids);
        }
    }

    @Override
    public void onUpdate(Context context, AppWidgetManager manager, int[] ids) {
        SharedPreferences prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        String sender    = prefs.getString("sender", null);
        String message   = prefs.getString("message", null);
        String appSource = prefs.getString("appSource", "");
        long timestamp   = prefs.getLong("timestamp", 0);

        for (int id : ids) {
            RemoteViews views = new RemoteViews(context.getPackageName(),
                R.layout.widget_latest_message);

            if (sender != null) {
                views.setTextViewText(R.id.widget_sender, sender);
                views.setTextViewText(R.id.widget_message, message);
                views.setTextViewText(R.id.widget_app, appSource);
                String timeStr = new SimpleDateFormat("hh:mm a", Locale.getDefault())
                    .format(new Date(timestamp));
                views.setTextViewText(R.id.widget_time, timeStr);
            } else {
                views.setTextViewText(R.id.widget_sender, "No messages yet");
                views.setTextViewText(R.id.widget_message, "Tap to open TalkNotify");
                views.setTextViewText(R.id.widget_app, "");
                views.setTextViewText(R.id.widget_time, "");
            }

            // Tap widget → open app
            Intent openIntent = new Intent(context, MainActivity.class);
            PendingIntent openPending = PendingIntent.getActivity(context, 0,
                openIntent, PendingIntent.FLAG_IMMUTABLE);
            views.setOnClickPendingIntent(R.id.widget_sender, openPending);
            views.setOnClickPendingIntent(R.id.widget_message, openPending);

            // Tap Read button → trigger TTS
            Intent readIntent = new Intent(context, TalkNotifyWidget.class);
            readIntent.setAction(ACTION_READ_MESSAGE);
            PendingIntent readPending = PendingIntent.getBroadcast(context, 1,
                readIntent, PendingIntent.FLAG_IMMUTABLE);
            views.setOnClickPendingIntent(R.id.widget_read_btn, readPending);

            manager.updateAppWidget(id, views);
        }
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        super.onReceive(context, intent);

        if (ACTION_READ_MESSAGE.equals(intent.getAction())) {
            // Read message via foreground service TTS
            if (TalkNotifyForegroundService.instance != null
                    && TalkNotifyForegroundService.lastSender != null) {
                TalkNotifyForegroundService.instance.announceMessage(
                    TalkNotifyForegroundService.lastSender,
                    TalkNotifyForegroundService.lastApp,
                    TalkNotifyForegroundService.lastMessage
                );
            }
        }
    }
}
