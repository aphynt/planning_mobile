import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:survey/pages/pages.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/date_symbol_data_local.dart';

// Handler untuk background message
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // wajib
  print("🔕 Background Message: ${message.messageId}");
  print("🔕 Title: ${message.notification?.title}");
  print("🔕 Body: ${message.notification?.body}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Background FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inisialisasi notifikasi lokal
  await NotificationService.initLocalNotification();

  if (kIsWeb) {
    await FirebaseMessaging.instance.requestPermission();

    // Hanya import dart:js jika di web
    // importJsWorker();
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  

  Future<void> _setupFCM() async {
    // Minta izin notifikasi
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('🔐 Permission: ${settings.authorizationStatus}');

    // Token FCM
    String? token = await FirebaseMessaging.instance.getToken();
    print("📲 FCM Token: $token");

    // Saat app dibuka dan pesan diterima
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground Message: ${message.messageId}');
      if (message.notification != null) {
        NotificationService.showNotification(
          title: message.notification!.title ?? 'No Title',
          body: message.notification!.body ?? 'No Body',
        );
      }
    });

    // Saat notifikasi diklik (app background atau terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🟢 Notifikasi diklik!');
      // Bisa diarahkan ke halaman tertentu, misal:
      // Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage()));
    });

    // Cek jika app dibuka dari notifikasi (terminated state)
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 App dibuka dari terminated oleh notifikasi');
      // Arahkan ke halaman tertentu jika diperlukan
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlannER App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
