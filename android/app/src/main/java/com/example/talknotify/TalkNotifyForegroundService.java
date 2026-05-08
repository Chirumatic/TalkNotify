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
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.speech.RecognitionListener;
import android.speech.RecognizerIntent;
import android.speech.SpeechRecognizer;
import android.speech.tts.TextToSpeech;
import android.util.Log;

import androidx.core.app.NotificationCompat;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
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
    private SpeechRecognizer speechRecognizer;
    private Handler handler;
    private boolean backgroundListeningEnabled = false;
    private boolean isListeningForCommands = false;

    // Static reference so NotificationListener can call it directly
    public static TalkNotifyForegroundService instance;

    @Override
    public void onCreate() {
        super.onCreate();
        instance = this;
        handler = new Handler(Looper.getMainLooper());

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

        // Check if background listening should start
        SharedPreferences prefs = getSharedPreferences("talknotify_prefs", Context.MODE_PRIVATE);
        backgroundListeningEnabled = prefs.getBoolean("background_listening", false);
        if (backgroundListeningEnabled) {
            handler.postDelayed(this::startBackgroundListening, 2000);
        }

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
        stopBackgroundListening();
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

        // Store for background voice commands
        lastSender = sender;
        lastMessage = message;
        lastApp = appSource;

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

    /** Speak arbitrary text */
    private void speak(String text) {
        if (!ttsReady || tts == null) return;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "cmd_" + System.currentTimeMillis());
        } else {
            tts.speak(text, TextToSpeech.QUEUE_FLUSH, null);
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

    /** Start background speech recognition loop */
    public void startBackgroundListening() {
        if (isListeningForCommands) return;
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            Log.w(TAG, "Speech recognition not available");
            return;
        }

        isListeningForCommands = true;
        Log.d(TAG, "Starting background voice listening");

        handler.post(() -> {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this);
            speechRecognizer.setRecognitionListener(new RecognitionListener() {
                @Override public void onReadyForSpeech(Bundle p) {}
                @Override public void onBeginningOfSpeech() {}
                @Override public void onRmsChanged(float v) {}
                @Override public void onBufferReceived(byte[] b) {}
                @Override public void onPartialResults(Bundle b) {}
                @Override public void onEvent(int t, Bundle b) {}

                @Override
                public void onResults(Bundle results) {
                    ArrayList<String> matches = results.getStringArrayList(
                        SpeechRecognizer.RESULTS_RECOGNITION);
                    if (matches != null && !matches.isEmpty()) {
                        String command = matches.get(0).toLowerCase();
                        Log.d(TAG, "Background command heard: " + command);
                        processBackgroundCommand(command);
                    }
                    // Restart listening after processing
                    if (backgroundListeningEnabled && isListeningForCommands) {
                        handler.postDelayed(TalkNotifyForegroundService.this::restartListening, 1000);
                    }
                }

                @Override
                public void onError(int error) {
                    Log.d(TAG, "Speech error: " + error);
                    isListeningForCommands = false;
                    // Restart after a short delay on error
                    if (backgroundListeningEnabled) {
                        handler.postDelayed(TalkNotifyForegroundService.this::startBackgroundListening, 3000);
                    }
                }

                @Override
                public void onEndOfSpeech() {
                    isListeningForCommands = false;
                }
            });

            Intent intent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
            intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
            intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault());
            intent.putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1);
            intent.putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, getPackageName());
            speechRecognizer.startListening(intent);
        });
    }

    private void restartListening() {
        isListeningForCommands = false;
        if (speechRecognizer != null) {
            speechRecognizer.destroy();
            speechRecognizer = null;
        }
        startBackgroundListening();
    }

    /** Stop background speech recognition */
    public void stopBackgroundListening() {
        backgroundListeningEnabled = false;
        isListeningForCommands = false;
        if (speechRecognizer != null) {
            handler.post(() -> {
                speechRecognizer.destroy();
                speechRecognizer = null;
            });
        }
    }

    /** Process a voice command heard in the background */
    private void processBackgroundCommand(String command) {
        // Get latest message from static store
        String latestSender = lastSender;
        String latestMessage = lastMessage;
        String latestApp = lastApp;

        if (command.contains("read") || command.contains("latest message")) {
            if (latestMessage != null) {
                announceMessage(latestSender, latestApp, latestMessage);
            } else {
                speak("You have no messages.");
            }
        } else if (command.contains("who texted") || command.contains("who messaged")) {
            if (latestSender != null) {
                speak(latestSender + " sent you a message via " + latestApp);
            } else {
                speak("No recent messages.");
            }
        } else if (command.contains("stop")) {
            if (tts != null) tts.stop();
        } else if (command.contains("repeat")) {
            if (latestMessage != null) {
                announceMessage(latestSender, latestApp, latestMessage);
            }
        } else if (command.contains("driving mode on")) {
            SharedPreferences prefs = getSharedPreferences("talknotify_prefs", Context.MODE_PRIVATE);
            prefs.edit().putBoolean("driving_mode", true).apply();
            speak("Driving mode activated.");
        } else if (command.contains("driving mode off")) {
            SharedPreferences prefs = getSharedPreferences("talknotify_prefs", Context.MODE_PRIVATE);
            prefs.edit().putBoolean("driving_mode", false).apply();
            speak("Driving mode deactivated.");
        }
    }

    // Store last message for background commands
    public static String lastSender;
    public static String lastMessage;
    public static String lastApp;

    /** Check if Do Not Disturb hours are active */
    private boolean isDndActive() {        SharedPreferences prefs = getSharedPreferences("talknotify_prefs", Context.MODE_PRIVATE);
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
