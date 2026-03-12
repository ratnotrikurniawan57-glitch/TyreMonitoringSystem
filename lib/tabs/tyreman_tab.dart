// ignore_for_file: use_build_context_synchronously, avoid_types_as_parameter_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../features/form_inspection_screen.dart';
import 'package:flutter/foundation.dart';

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
        temuanDesc = data['finding_desc'] ?? "Tidak ada deskripsi";
        fotoUrl = data['photo_url'] ?? "";
      } else {
        temuanDesc = "Data temuan tidak ditemukan di history.";
      }

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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(fotoUrl,
                          height: 150, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],
                  const SizedBox(height: 15),
                  const Text("Apakah unit sudah selesai diperbaiki?"),
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
                        content: Text("✅ Unit $unitId: Perbaikan Selesai")));
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
      if (kDebugMode) print("Error Firestore: $e");
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
            padding: const EdgeInsets.all(8.0),
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
              stream: FirebaseFirestore.instance.collection('units').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs.map((doc) {
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
                }).where((item) =>
                    item['id'].toString().toLowerCase().contains(searchQuery))
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
                  padding: const EdgeInsets.all(6),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var item = docs[index];
                    var dataUnit = item['data'] as Map<String, dynamic>;
                    String status = item['status'] as String;
                    String id = item['id'] as String;
                    String vDesc = dataUnit['vehicle_desc'] ?? "-";

                    return AnimatedBuilder(
                      animation: _blinkController,
                      builder: (context, child) {
                        Color bgColor = Colors.white;
                        Color txtColor = Colors.black;

                        if (status == 'red') {
                          bgColor = Colors.red.shade700;
                          txtColor = Colors.white;
                        } else if (status == 'green') {
                          bgColor = Colors.green.shade600;
                          txtColor = Colors.white;
                        } else if (status == 'yellow_blink') {
                          bgColor = Color.lerp(Colors.yellow.shade700, 
                              Colors.orange.shade900, _blinkController.value)!;
                          txtColor = Colors.white;
                        }

                        return InkWell(
                          onTap: () {
                            if (status == 'yellow_blink') {
                              _showCloseFindingDialog(id);
                            } else {
                              int target = dataUnit['kpi_target'] ?? 10;
                              int group = dataUnit['plan_group'] ?? 1;
                              bool isJadwal = (target == 10) 
                                  ? (group == groupProdHariIni) : (group == hariIni);
                              bool isAccurate = (isJadwal && status == 'red');

                              Navigator.push(context, MaterialPageRoute(
                                builder: (c) => FormInspectionScreen(
                                  unitId: id, unitCode: id, isAccurate: isAccurate,
                                )));
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black12),
                              boxShadow: [
                                BoxShadow(
                                  // 🔥 FIX: withOpacity ganti ke withValues
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                )
                              ],
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(id.toUpperCase(),
                                          style: TextStyle(
                                              color: txtColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text(vDesc.toUpperCase(),
                                            style: TextStyle(
                                                // 🔥 FIX: withOpacity ganti ke withValues
                                                color: txtColor.withValues(alpha: 0.8),
                                                fontSize: 7,
                                                fontWeight: FontWeight.w500),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                ),
                                if (status == 'green')
                                  const Positioned(top: 3, right: 3, 
                                      child: Icon(Icons.check_circle, size: 10, color: Colors.white)),
                              ],
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