import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- IMPORT BARU
import 'firebase_options.dart';
import 'auth/login_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard_screen.dart'; // <--- IMPORT DASHBOARD LO

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
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // --- 5. OTOMATIS MASUK GRUP NOTIF TEMUAN ---
  await messaging.subscribeToTopic('temuan_unit');
  
  // --- 6. LOGIKA AUTO-LOGIN (DITAMBAHKAN) ---
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  String? nrp = prefs.getString('userNrp');
  String? role = prefs.getString('userRole');

  // Set handler buat background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Kirim data login ke MyApp
  runApp(MyApp(
    isLoggedIn: isLoggedIn,
    nrp: nrp,
    role: role,
  ));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? nrp;
  final String? role;

  const MyApp({
    super.key, 
    required this.isLoggedIn, 
    this.nrp, 
    this.role
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TMS Mobile',
      theme: AppTheme.lightTheme,
      // LOGIKA GERBANG: Cek apakah sudah login & data lengkap
      home: (isLoggedIn && nrp != null && role != null)
          ? DashboardScreen(nrpAktif: nrp!, role: role!)
          : const LoginScreen(),
    );
  }
}