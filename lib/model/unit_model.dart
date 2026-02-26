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
    {
      'code': 'ct010-0013',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 1,
      'target': 4
    },
    {
      'code': 'ct010-0015',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 2,
      'target': 4
    },
    {
      'code': 'ct010-0017',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 3,
      'target': 4
    },
    {
      'code': 'ct010-0019',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 1,
      'target': 4
    },
    {
      'code': 'dt020-0148',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt020-0149',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt020-0151',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt020-0152',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt020-0157',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt020-0161',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt020-0164',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt020-0165',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt020-0166',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt020-0167',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt020-0168',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt020-0169',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt020-0170',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt020-0171',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt020-0172',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt020-0174',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt020-0176',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt020-0179',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt020-0180',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt020-0189',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt020-0190',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt020-0191',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt020-0192',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt020-0193',
      'brand': 'VOLVO',
      'desc': 'DT 20 TON',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt030-0085',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt030-0086',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt030-0087',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt030-0088',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt030-0093',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt030-0095',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt030-0096',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt030-0097',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt030-0098',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt030-0099',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt030-0100',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt030-0102',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt030-0103',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt030-0106',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt030-0110',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt030-0190',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt030-0191',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt030-0192',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt030-0193',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt030-0194',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt030-0214',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt030-0215',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt030-0216',
      'brand': 'VOLVO',
      'desc': 'DT 30 TON',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt090-0047',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt090-0058',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt090-0092',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt090-0093',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt090-0513',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt090-0514',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt090-0527',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt090-0528',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt090-0533',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt090-0534',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt090-0535',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt090-0536',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt090-0617',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt090-0618',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt090-0619',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt090-0620',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt090-0621',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt090-0622',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt090-0625',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt090-0626',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt090-0627',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt090-0628',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt090-0629',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt090-0630',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt090-0631',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt090-0632',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt090-0701',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt090-0702',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt090-0710',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt090-0712',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt090-0717',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt090-0718',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt090-0761',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt090-0762',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt090-0774',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt090-0778',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt090-0780',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt090-0784',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt090-0786',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt090-0787',
      'brand': 'KOMATSU',
      'desc': 'HD785-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'ft020-0057',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 2,
      'target': 4
    },
    {
      'code': 'ft020-0081',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 3,
      'target': 4
    },
    {
      'code': 'ft020-0082',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 1,
      'target': 4
    },
    {
      'code': 'ft020-0083',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 2,
      'target': 4
    },
    {
      'code': 'ft020-0088',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 3,
      'target': 4
    },
    {
      'code': 'gd014-0038',
      'brand': 'KOMATSU',
      'desc': 'GREADER',
      'group': 1,
      'target': 4
    },
    {
      'code': 'gd014-0039',
      'brand': 'KOMATSU',
      'desc': 'GREADER',
      'group': 2,
      'target': 4
    },
    {
      'code': 'gd016-0051',
      'brand': 'KOMATSU',
      'desc': 'GREADER',
      'group': 3,
      'target': 4
    },
    {
      'code': 'gd016-0078',
      'brand': 'KOMATSU',
      'desc': 'GREADER',
      'group': 1,
      'target': 4
    },
    {
      'code': 'gd016-0080',
      'brand': 'KOMATSU',
      'desc': 'GREADER',
      'group': 2,
      'target': 4
    },
    {
      'code': 'gd016-0100',
      'brand': 'KOMATSU',
      'desc': 'GREADER',
      'group': 3,
      'target': 4
    },
    {
      'code': 'gd016-0102',
      'brand': 'KOMATSU',
      'desc': 'GREADER',
      'group': 1,
      'target': 4
    },
    {
      'code': 'gd016-0104',
      'brand': 'KOMATSU',
      'desc': 'GREADER',
      'group': 2,
      'target': 4
    },
    {
      'code': 'gd016-0112',
      'brand': 'KOMATSU',
      'desc': 'GREADER',
      'group': 3,
      'target': 4
    },
    {
      'code': 'lt020-0024',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 1,
      'target': 4
    },
    {
      'code': 'lt020-0034',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 2,
      'target': 4
    },
    {
      'code': 'lt020-0060',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 3,
      'target': 4
    },
    {
      'code': 'lt020-0066',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 1,
      'target': 4
    },
    {
      'code': 'lt020-0067',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 2,
      'target': 4
    },
    {
      'code': 'lt020-0068',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 3,
      'target': 4
    },
    {
      'code': 'lt020-0069',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 1,
      'target': 4
    },
    {
      'code': 'mb040-0001',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 2,
      'target': 4
    },
    {
      'code': 'mb040-0002',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 3,
      'target': 4
    },
    {
      'code': 'mb040-0004',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 1,
      'target': 4
    },
    {
      'code': 'mb040-0006',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 2,
      'target': 4
    },
    {
      'code': 'mb040-0011',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 3,
      'target': 4
    },
    {
      'code': 'mb040-0012',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 1,
      'target': 4
    },
    {
      'code': 'mb040-0014',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 2,
      'target': 4
    },
    {
      'code': 'mb040-0016',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 3,
      'target': 4
    },
    {
      'code': 'mb040-0017',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 1,
      'target': 4
    },
    {
      'code': 'mb040-0018',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 2,
      'target': 4
    },
    {
      'code': 'mb040-0019',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 3,
      'target': 4
    },
    {
      'code': 'mb040-0023',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 1,
      'target': 4
    },
    {
      'code': 'mb040-0024',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 2,
      'target': 4
    },
    {
      'code': 'mb040-0025',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 3,
      'target': 4
    },
    {
      'code': 'th030-0008',
      'brand': 'KOMATSU',
      'desc': 'WHEAL LOADER',
      'group': 1,
      'target': 4
    },
    {
      'code': 'th030-0011',
      'brand': 'KOMATSU',
      'desc': 'WHEAL LOADER',
      'group': 2,
      'target': 4
    },
    {
      'code': 'wl045-0002',
      'brand': 'KOMATSU',
      'desc': 'WHEAL LOADER',
      'group': 3,
      'target': 4
    },
    {
      'code': 'wl045-0003',
      'brand': 'KOMATSU',
      'desc': 'WHEAL LOADER',
      'group': 1,
      'target': 4
    },
    {
      'code': 'ws020-0015',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 2,
      'target': 4
    },
    {
      'code': 'ws020-0022',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 3,
      'target': 4
    },
    {
      'code': 'ws020-0026',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 1,
      'target': 4
    },
    {
      'code': 'ws020-0030',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 2,
      'target': 4
    },
    {
      'code': 'ws020-0032',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 3,
      'target': 4
    },
    {
      'code': 'ws020-0034',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 1,
      'target': 4
    },
    {
      'code': 'wt020-0047',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 2,
      'target': 4
    },
    {
      'code': 'wt020-0052',
      'brand': 'VOLVO',
      'desc': 'SUPORT',
      'group': 3,
      'target': 4
    },
    {
      'code': 'wt055-0007',
      'brand': 'KOMATSU',
      'desc': 'HD 465-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'wt055-0026',
      'brand': 'KOMATSU',
      'desc': 'HD 465-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'wt055-0027',
      'brand': 'KOMATSU',
      'desc': 'HD 465-7',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt055-0178',
      'brand': 'KOMATSU',
      'desc': 'HD 465-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt055-0180',
      'brand': 'KOMATSU',
      'desc': 'HD 465-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt055-0187',
      'brand': 'KOMATSU',
      'desc': 'HD 465-7',
      'group': 3,
      'target': 10
    },
    {
      'code': 'dt055-0188',
      'brand': 'KOMATSU',
      'desc': 'HD 465-7',
      'group': 1,
      'target': 10
    },
    {
      'code': 'dt055-0189',
      'brand': 'KOMATSU',
      'desc': 'HD 465-7',
      'group': 2,
      'target': 10
    },
    {
      'code': 'dt055-0190',
      'brand': 'KOMATSU',
      'desc': 'HD 465-7',
      'group': 3,
      'target': 10
    },
    // ... data lainnya
  ];
}
