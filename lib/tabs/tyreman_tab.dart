// ignore_for_file: use_build_context_synchronously, avoid_types_as_parameter_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../features/form_inspection_screen.dart';

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

  void _showCloseFindingDialog(String unitId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Perbaikan"),
        content: Text(
            "Apakah unit ${unitId.toUpperCase()} sudah selesai diperbaiki dan siap operasi?"),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      "✅ Unit $unitId: Perbaikan Selesai oleh $_currentNRP")));
            },
            child: const Text("YA, SELESAI",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari Kode Unit...",
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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

                      // LOGIKA WARNA SAKTI
                      String status = 'white'; // Default

                      if (condition != 'aman') {
                        status = 'yellow_blink'; // Prioritas 1: Rusak/Temuan
                      } else {
                        // Cek apakah jadwalnya hari ini
                        bool isJadwal = (target == 10)
                            ? (group == groupProdHariIni)
                            : (group == hariIni);

                        if (isJadwal && lastCheck != tglIni) {
                          status = 'red'; // Prioritas 2: Jadwal Cek & Belum Cek
                        } else if (lastCheck == tglIni) {
                          status = 'green'; // Prioritas 3: Sudah Cek Hari Ini
                        }
                      }

                      return {'data': data, 'status': status, 'id': id};
                    })
                    .where(
                        (item) => item['id'].toString().contains(searchQuery))
                    .toList();

                // SORTING
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
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var item = docs[index];
                    String status = item['status'] as String;
                    String id = item['id'] as String;

                    return InkWell(
                      onTap: () {
                        if (status == 'yellow_blink') {
                          _showCloseFindingDialog(id);
                        } else {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (c) => FormInspectionScreen(
                                        unitId: id,
                                        unitCode: id,
                                      )));
                        }
                      },
                      child: AnimatedBuilder(
                        animation: _blinkController,
                        builder: (context, child) {
                          Color bgColor = Colors.white;
                          if (status == 'red') bgColor = Colors.red;
                          if (status == 'green') bgColor = Colors.green;
                          if (status == 'yellow_blink') {
                            bgColor = Color.lerp(
                                Colors.yellow.shade700,
                                Colors.orange.shade900,
                                _blinkController.value)!;
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(8),
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
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
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
