import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PerformanceTab extends StatelessWidget {
  const PerformanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String currentMonthYear = DateFormat('MM-yyyy').format(now);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN 1: RINGKASAN STATUS (REAL-TIME) ---
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text("MONITORING KONDISI UNIT",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            _buildOverallStatus(),

            // --- BAGIAN 2: PERFORMA PER KELAS (QTY & ACCURACY) ---
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text("PERFORMA KELAS UNIT",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            _buildUnitStats(currentMonthYear),

            const Divider(thickness: 1, height: 40),

            // --- BAGIAN 3: LEADERBOARD TYREMAN ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("-Tyreman Activity-",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(DateFormat('MMMM yyyy').format(now).toUpperCase(),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildTyremanLeaderboard(currentMonthYear),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatus() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('units').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const LinearProgressIndicator();

        // Hitung berdasarkan field 'condition' yang baru
        int aman = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['condition'] == 'aman';
        }).length;

        int temuan = snap.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['condition'] == 'temuan';
        }).length;

        int belumCek = snap.data!.docs.length - (aman + temuan);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _statusMiniBox("AMAN", aman, Colors.green),
              _statusMiniBox("TEMUAN", temuan, Colors.orange),
              _statusMiniBox("OVERDUE", belumCek, Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _statusMiniBox(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text("$count",
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitStats(String monthYear) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('units').snapshots(),
      builder: (context, unitSnapshot) {
        if (!unitSnapshot.hasData) return const SizedBox();

        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('inspections').snapshots(),
          builder: (context, insSnapshot) {
            if (!insSnapshot.hasData) return const SizedBox();

            // 1. Ambil data inspeksi bulan ini
            var monthIns = insSnapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['timestamp'] == null) return false;
              DateTime date = (data['timestamp'] as Timestamp).toDate();
              return DateFormat('MM-yyyy').format(date) == monthYear;
            }).toList();

            // 2. Kelompokkan Unit ID berdasarkan Kelas (Vehicle Desc)
            Map<String, List<String>> unitGroups = {};
            for (var doc in unitSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              String desc = data['vehicle_desc'] ?? 'LAINNYA';
              if (!unitGroups.containsKey(desc)) unitGroups[desc] = [];
              unitGroups[desc]!.add(doc.id);
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: unitGroups.keys.length,
              itemBuilder: (context, index) {
                String className = unitGroups.keys.elementAt(index);
                List<String> unitsInClass = unitGroups[className]!;

                // Hitung Quantity (Berapa unit di kelas ini yang sudah dicek bulan ini)
                var checkedInClass = monthIns
                    .where((ins) =>
                        unitsInClass.contains((ins.data() as Map)['unit_code']))
                    .toList();

                // Unikkan unit_code biar kalau 1 unit dicek 2x gak dobel hitung Qty
                int uniqueChecked = checkedInClass
                    .map((e) => (e.data() as Map)['unit_code'])
                    .toSet()
                    .length;

                double qtyPercent = (uniqueChecked / unitsInClass.length) * 100;

                // Hitung Accuracy (Dari inspeksi yang dilakukan, berapa yang is_accurate: true)
                int accurateCount = checkedInClass
                    .where((ins) => (ins.data() as Map)['is_accurate'] == true)
                    .length;

                double accPercent = checkedInClass.isEmpty
                    ? 0
                    : (accurateCount / checkedInClass.length) * 100;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(className,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Qty: ${qtyPercent.toStringAsFixed(0)}%",
                                style: TextStyle(
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.w600)),
                            Text("Accuracy: ${accPercent.toStringAsFixed(0)}%",
                                style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: qtyPercent / 100,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            color: Colors.blue,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTyremanLeaderboard(String monthYear) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('inspections').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        Map<String, int> points = {};
        var filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['timestamp'] == null) return false;
          return DateFormat('MM-yyyy')
                  .format((data['timestamp'] as Timestamp).toDate()) ==
              monthYear;
        });

        for (var doc in filtered) {
          List nrps = (doc.data() as Map)['team_nrp'] ?? [];
          for (var nrp in nrps) {
            String n = nrp.toString().toLowerCase();
            points[n] = (points[n] ?? 0) + 1;
          }
        }

        var sorted = points.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Column(
          children: sorted.map((e) {
            return FutureBuilder<DocumentSnapshot>(
              // ASUMSI: Koleksi user lo namanya 'users' dan ID dokumennya adalah NRP
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(e.key)
                  .get(),
              builder: (context, userSnap) {
                String displayName = e.key
                    .toUpperCase(); // Default pakai NRP kalau nama gak ketemu

                if (userSnap.hasData && userSnap.data!.exists) {
                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>;
                  displayName = userData['nama'] ?? e.key.toUpperCase();
                }

                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Text(displayName[0],
                          style: const TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text("NRP: ${e.key}"),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${e.value}",
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue)),
                        const Text("Unit",
                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
