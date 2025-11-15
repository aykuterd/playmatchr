import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }

      // On iOS, try to get APNS token but don't fail if unavailable (simulator)
      if (Platform.isIOS) {
        try {
          String? apnsToken = await _fcm.getAPNSToken();
          if (apnsToken != null) {
            debugPrint('APNS Token: $apnsToken');
          } else {
            debugPrint('APNS token is null - running on simulator?');
            // Simulator'da APNS token olmadığı için return ediyoruz
            return;
          }
        } catch (e) {
          debugPrint('Could not get APNS token: $e');
          debugPrint('This is expected on iOS simulator');
          // Simulator'da hata alırız, devam etmiyoruz
          return;
        }
      }

      // FCM token'ı al
      try {
        String? token = await _fcm.getToken();
        if (token != null) {
          debugPrint("Firebase Messaging Token: $token");
        }
      } catch (e) {
        debugPrint('Failed to get FCM token: $e');
      }

      // Handle incoming messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
        }
      });
    } catch (e) {
      debugPrint('Push notification initialization error: $e');
      rethrow; // Hatayı yukarı fırlat ki main.dart'ta yakalansın
    }
  }
}
