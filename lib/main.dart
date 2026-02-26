import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'auth/login_screen.dart';
import 'core/theme/app_theme.dart';

// --- 1. HANDLER NOTIF SAAT APLIKASI MATI ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Notif masuk pas aplikasi mati: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. INISIALISASI FIREBASE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. SETTING OFFLINE MODE
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 4. SETUP NOTIFIKASI
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Minta izin ke HP
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // --- 5. OTOMATIS MASUK GRUP NOTIF TEMUAN ---
  // Semua HP yang instal ini otomatis "Join" grup temuan_unit
  await messaging.subscribeToTopic('temuan_unit');
  debugPrint("Selesai: HP sudah join ke grup temuan_unit");

  // --- AMBIL TOKEN (Opsional buat debugging) ---
  String? token = await messaging.getToken();
  debugPrint("================================================");
  debugPrint("KODE ALAMAT HP LO (TOKEN): $token");
  debugPrint("================================================");

  // Set handler buat background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TMS Mobile',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
