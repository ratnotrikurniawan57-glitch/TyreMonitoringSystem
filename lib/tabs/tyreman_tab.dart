// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tyre_ms/features/form_inspection_screen.dart';
import '../model/unit_model.dart'; // Pastikan import model

class TyremanTab extends StatefulWidget {
  const TyremanTab({super.key});

  @override
  State<TyremanTab> createState() => _TyremanTabState();
}

class _TyremanTabState extends State<TyremanTab>
    with SingleTickerProviderStateMixin {
  String searchQuery = "";
  late AnimationController _blinkController;

  // Ambil NRP dari email login (contoh: 12345@gmail.com jadi 12345)
  String get _currentNRP =>
      FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? "unknown";

  @override
  void initState() {
    super.initState();
    // Setting Animasi Kedip 500ms
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

  // --- FUNGSI QUICK CLOSE (DIJALANKAN SAAT KUNING DI-TAP) ---
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
    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari Kode Unit...",
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) =>
                  setState(() => searchQuery = val.toLowerCase()),
            ),
          ),

          // Daftar Unit (GridView agar muat banyak)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('units').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 1. MAPPING DATA & PENENTUAN WARNA
                var docs = snapshot.data!.docs
                    .map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String status = UnitModel.getStatusColor(
                        data['plan_group'] ?? 1,
                        data['condition'] ?? 'aman',
                        data['updated_at'] as Timestamp?,
                      );
                      return {'doc': doc, 'status': status, 'id': doc.id};
                    })
                    .where(
                        (item) => item['id'].toString().contains(searchQuery))
                    .toList();

                // 2. LOGIKA SORTING PRIORITAS
                // Urutan: 1.Kuning Kedip, 2.Merah, 3.Putih, 4.Hijau
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
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // 4 kotak ke samping
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
                              builder: (context) => FormInspectionScreen(
                                unitId: id,
                                unitCode: id,
                              ),
                            ),
                          );
                        }
                      },
                      child: AnimatedBuilder(
                        animation: _blinkController,
                        builder: (context, child) {
                          // PENENTUAN WARNA BACKGROUND
                          Color bgColor;
                          switch (status) {
                            case 'red':
                              bgColor = Colors.red;
                              break;
                            case 'green':
                              bgColor = Colors.green;
                              break;
                            case 'yellow_blink':
                              bgColor = Color.lerp(
                                  Colors.yellow.shade700,
                                  Colors.orange.shade900,
                                  _blinkController.value)!;
                              break;
                            default:
                              bgColor = Colors.white;
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: status == 'yellow_blink'
                                  ? [
                                      BoxShadow(
                                          color: Colors.orange.withOpacity(0.5),
                                          blurRadius: 5,
                                          spreadRadius: 1)
                                    ]
                                  : null,
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
