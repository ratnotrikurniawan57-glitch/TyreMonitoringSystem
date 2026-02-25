import 'package:cloud_firestore/cloud_firestore.dart';

class UnitModel {
  // --- LOGIKA UTAMA PENENTU WARNA ---
  static String getStatusColor(
      int planGroup, String condition, Timestamp? lastCheck) {
    DateTime now = DateTime.now();
    int day = now.day;

    // 1. PRIORITAS TERTINGGI: Ada temuan ban
    // Kita cek apakah temuan itu terjadi HARI INI
    if (condition == 'temuan' &&
        lastCheck != null &&
        _isSameDay(lastCheck, now)) {
      return 'yellow_blink';
    }

    // Tgl 31: Hari Free
    if (day == 31) {
      return (lastCheck != null && _isSameMonth(lastCheck, now))
          ? 'green'
          : 'white';
    }

    // 2. CEK APAKAH SUDAH DICEK HARI INI DAN AMAN?
    if (lastCheck != null && _isSameDay(lastCheck, now)) {
      return 'green';
    }

    // 3. LOGIKA MERAH (Jadwal Hari Ini)
    bool isJadwalHariIni =
        (day % 3 == planGroup % 3) || (day % 3 == 0 && planGroup == 3);

    if (isJadwalHariIni) {
      return 'red';
    }

    // 4. SISANYA PUTIH
    return 'white';
  }

  static bool _isSameDay(Timestamp ts, DateTime now) {
    DateTime d = ts.toDate();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  static bool _isSameMonth(Timestamp ts, DateTime now) {
    DateTime d = ts.toDate();
    return d.year == now.year && d.month == now.month;
  }

  // DATA MASTER 117 UNIT (Tetap di sini)
  static List<Map<String, dynamic>> masterDataList = [
    {'code': 'dt090-001', 'brand': 'KOMATSU', 'desc': 'HD 785-7'},
    // ... data lainnya
  ];
}
