import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tyre_ms/features/form_inspection_screen.dart';

class TyremanTab extends StatefulWidget {
  const TyremanTab({super.key});

  @override
  State<TyremanTab> createState() => _TyremanTabState();
}

class _TyremanTabState extends State<TyremanTab> {
  String searchQuery = "";

  int get _currentScheduleGroup {
    int day = DateTime.now().day;
    int group = day % 3;
    return group == 0 ? 3 : group;
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

          // Daftar Unit
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('units').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs.where((doc) {
                  return doc['unit_code']
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    String code = data['unit_code'] ?? "Unknown";
                    int? group = data['plan_group'];
                    String status = data['current_status'] ??
                        'white'; // Sesuaikan field name

                    return ListTile(
                      leading: Icon(Icons.local_shipping,
                          color: _getStatusColor(status)),
                      title: Text(code.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          data['vehicle_desc']?.toString().toUpperCase() ??
                              "-"),
                      trailing: _buildPlanBadge(group),
                      onTap: () {
                        // --- SEKARANG PINTUNYA SUDAH DIBUKA ---
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FormInspectionScreen(
                              unitCode: code,
                              unitId: doc.id, // ID Dokumen Firestore
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

  Widget _buildPlanBadge(int? unitGroup) {
    if (unitGroup == null) return const SizedBox.shrink();
    bool isOnPlan = unitGroup == _currentScheduleGroup;
    if (!isOnPlan) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        "ON PLAN",
        style: TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'white':
        return Colors.grey.shade400;
      default:
        return Colors.grey.shade300;
    }
  }
}
