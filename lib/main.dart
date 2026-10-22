import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';

/// 🔔 Background message handler
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint("Background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// 🚨 IMPORTANT FIX
  /// Firebase Messaging causes crash on Web if service worker is missing.
  /// So we enable it only for mobile platforms.
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    /// Request notification permission
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    /// Get FCM token (debugging)
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint("FCM TOKEN: $token");
  }

  runApp(const ShareBloomApp());
}

class ShareBloomApp extends StatefulWidget {
  const ShareBloomApp({Key? key}) : super(key: key);

  @override
  State<ShareBloomApp> createState() => _ShareBloomAppState();
}

class _ShareBloomAppState extends State<ShareBloomApp> {
  bool isDark = true;

  void toggleTheme() {
    setState(() {
      isDark = !isDark;
    });
  }

  @override
  void initState() {
    super.initState();

    /// 🚨 Messaging listeners only for mobile
    if (!kIsWeb) {
      /// App opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("Notification clicked: ${message.notification?.title}");
      });

      /// Foreground notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Foreground notification: ${message.notification?.title}");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(
            overscroll: false,
          ),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}