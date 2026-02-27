// ignore_for_file: use_build_context_synchronously, avoid_types_as_parameter_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../features/form_inspection_screen.dart';
import 'package:flutter/foundation.dart'; // <--- Wajib buat kDebugMode

class TyremanTab extends StatefulWidget {
  const TyremanTab({super.key});

  @override
  State<TyremanTab> createState() => _TyremanTabState();
}

class _TyremanTabState extends State<TyremanTab>
    with SingleTickerProviderStateMixin {
  String searchQuery = "";
  late AnimationController _blinkController;

  String get _currentNRP =>
      FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? "unknown";

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _showCloseFindingDialog(String unitId) async {
    try {
      // 1. Ambil data temuan terakhir dari Firestore
      var inspectionSnapshot = await FirebaseFirestore.instance
          .collection('inspections')
          .where('unit_code', isEqualTo: unitId)
          .where('condition', isEqualTo: 'temuan')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      String temuanDesc = "Memuat data temuan...";
      String fotoUrl = "";

      if (inspectionSnapshot.docs.isNotEmpty) {
        var data = inspectionSnapshot.docs.first.data();
        // 🔥 FIX: Pake 'finding_desc' sesuai data Firestore terbaru
        temuanDesc = data['finding_desc'] ?? "Tidak ada deskripsi";
        fotoUrl = data['photo_url'] ?? "";
      } else {
        temuanDesc = "Data temuan tidak ditemukan di history.";
      }

      // 2. Tampilkan Dialog dengan detail temuan
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Konfirmasi Perbaikan - ${unitId.toUpperCase()}"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Temuan Sebelumnya:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.yellow[100],
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(
                      temuanDesc,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red[900]),
                    ),
                  ),
                  if (fotoUrl.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Image.network(fotoUrl,
                        height: 100, width: 100, fit: BoxFit.cover),
                  ],
                  const SizedBox(height: 15),
                  const Text(
                      "Apakah unit sudah selesai diperbaiki dan siap operasi?"),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("BATAL")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  // Update status unit jadi 'aman'
                  await FirebaseFirestore.instance
                      .collection('units')
                      .doc(unitId)
                      .update({
                    'condition': 'aman',
                    'last_action_by': _currentNRP,
                    'updated_at': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "✅ Unit $unitId: Perbaikan Selesai oleh $_currentNRP")));
                  }
                },
                child: const Text("YA, SELESAI",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error Firestore: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Koneksi Firestore Gagal: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    int hariIni = now.weekday;
    String tglIni = DateFormat('yyyy-MM-dd').format(now);
    int groupProdHariIni = (now.day % 3) == 0 ? 3 : (now.day % 3);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0), // Padding kecilin
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari Kode Unit...",
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (val) =>
                  setState(() => searchQuery = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('units').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs
                    .map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String id = doc.id;
                      String condition = data['condition'] ?? 'aman';
                      String? lastCheck = data['last_check'];
                      int group = data['plan_group'] ?? 1;
                      int target = data['kpi_target'] ?? 10;

                      String status = 'white';

                      if (condition != 'aman') {
                        status = 'yellow_blink';
                      } else {
                        bool isJadwal = (target == 10)
                            ? (group == groupProdHariIni)
                            : (group == hariIni);

                        if (isJadwal && lastCheck != tglIni) {
                          status = 'red';
                        } else if (lastCheck == tglIni) {
                          status = 'green';
                        }
                      }

                      return {'data': data, 'status': status, 'id': id};
                    })
                    .where(
                        (item) => item['id'].toString().contains(searchQuery))
                    .toList();

                docs.sort((a, b) {
                  Map<String, int> priority = {
                    'yellow_blink': 1,
                    'red': 2,
                    'white': 3,
                    'green': 4
                  };
                  int pA = priority[a['status']] ?? 5;
                  int pB = priority[b['status']] ?? 5;
                  if (pA != pB) return pA.compareTo(pB);
                  return a['id'].toString().compareTo(b['id'].toString());
                });

                return GridView.builder(
                  padding: const EdgeInsets.all(4), // Spacing pinggir kecilin
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    // 🔥 FIX: Kolom jadi 6 biar kecil & rapi
                    crossAxisCount: 4,
                    // 🔥 FIX: Jarak antar kotak jadi 2
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var item = docs[index];
                    String status = item['status'] as String;
                    String id = item['id'] as String;

                    return AnimatedBuilder(
                      animation: _blinkController,
                      builder: (context, child) {
                        Color bgColor = Colors.white;
                        if (status == 'red') bgColor = Colors.red;
                        if (status == 'green') {
                          bgColor = const Color.fromARGB(255, 28, 34, 28);
                        }
                        if (status == 'yellow_blink') {
                          bgColor = Color.lerp(
                            Colors.yellow.shade700,
                            Colors.orange.shade900,
                            _blinkController.value,
                          )!;
                        }

                        return InkWell(
                          onTap: () {
                            if (status == 'yellow_blink') {
                              _showCloseFindingDialog(id);
                            } else {
                              var data = item['data'] as Map<String, dynamic>;
                              int target = data['kpi_target'] ?? 10;
                              int group = data['plan_group'] ?? 1;

                              bool isJadwal = (target == 10)
                                  ? (group == groupProdHariIni)
                                  : (group == hariIni);

                              bool isAccurate = (isJadwal && status == 'red');

                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (c) => FormInspectionScreen(
                                            unitId: id,
                                            unitCode: id,
                                            isAccurate: isAccurate,
                                          )));
                            }
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Center(
                              child: Text(
                                id.toUpperCase(),
                                style: TextStyle(
                                  color: (status == 'red' || status == 'green')
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  // 🔥 FIX: Font size jadi 8 buat kotak kecil
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
