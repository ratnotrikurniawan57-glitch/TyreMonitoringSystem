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
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN 1: RINGKASAN STATUS (3 KOLOM ATAS) ---
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text("MONITORING KONDISI UNIT",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
            ),
            _buildOverallStatus(),

            // --- BAGIAN 2: PERFORMA PER KELAS (GRID 3 KOLOM) ---
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 25, 16, 10),
              child: Text("PERFORMA KELAS UNIT",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
            ),
            _buildUnitStatsGrid(currentMonthYear),

            const Divider(thickness: 1, height: 40),

            // --- BAGIAN 3: LEADERBOARD TYREMAN ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("-Tyreman Activity-",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(DateFormat('MMMM yyyy').format(now).toUpperCase(),
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
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

        int aman = snap.data!.docs
            .where((d) => (d.data() as Map)['condition'] == 'aman')
            .length;
        int temuan = snap.data!.docs
            .where((d) => (d.data() as Map)['condition'] == 'temuan')
            .length;
        int belumCek = snap.data!.docs.length - (aman + temuan);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text("$count",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // --- RE-DESIGNED GRID 3 KOLOM (PAKAI RUMUS MATANG LO) ---
  Widget _buildUnitStatsGrid(String monthYear) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('units').snapshots(),
      builder: (context, unitSnapshot) {
        if (!unitSnapshot.hasData) return const SizedBox();

        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('inspections').snapshots(),
          builder: (context, insSnapshot) {
            if (!insSnapshot.hasData) return const SizedBox();

            var monthIns = insSnapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['timestamp'] == null) return false;
              DateTime date = (data['timestamp'] as Timestamp).toDate();
              return DateFormat('MM-yyyy').format(date) == monthYear;
            }).toList();

            Map<String, List<String>> unitGroups = {};
            for (var doc in unitSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              String desc = data['vehicle_desc'] ?? 'LAINNYA';
              if (!unitGroups.containsKey(desc)) unitGroups[desc] = [];
              unitGroups[desc]!.add(doc.id);
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: unitGroups.keys.length,
              itemBuilder: (context, index) {
                String className = unitGroups.keys.elementAt(index);
                List<String> unitsInClass = unitGroups[className]!;

                var checkedInClass = monthIns
                    .where((ins) =>
                        unitsInClass.contains((ins.data() as Map)['unit_code']))
                    .toList();
                int uniqueChecked = checkedInClass
                    .map((e) => (e.data() as Map)['unit_code'])
                    .toSet()
                    .length;
                double qtyPercent = (uniqueChecked / unitsInClass.length) * 100;

                int accurateCount = checkedInClass
                    .where((ins) => (ins.data() as Map)['is_accurate'] == true)
                    .length;
                double accPercent = checkedInClass.isEmpty
                    ? 0
                    : (accurateCount / checkedInClass.length) * 100;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(className,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: qtyPercent / 100,
                            strokeWidth: 5,
                            backgroundColor: Colors.grey[100],
                            color: qtyPercent >= 100
                                ? Colors.green
                                : Colors.orange,
                          ),
                          Text("${qtyPercent.toStringAsFixed(0)}%",
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Acc: ${accPercent.toStringAsFixed(0)}%",
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // --- LEADERBOARD (Tetap List karena ini Nama Orang) ---
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
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(e.key)
                  .get(),
              builder: (context, userSnap) {
                String displayName = e.key.toUpperCase();
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
                    dense: true,
                    leading: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.orange.shade50,
                      child: Text(displayName[0],
                          style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    trailing: Text("${e.value} Unit",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.orange)),
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
