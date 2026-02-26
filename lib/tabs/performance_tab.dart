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
            // --- BAGIAN 1: RINGKASAN STATUS ---
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text("MONITORING KONDISI UNIT",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
            ),
            _buildOverallStatus(),

            // --- BAGIAN 2: PERFORMA PER KELAS ---
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
    String tglIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int weekdayIni = DateTime.now().weekday;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('units').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const LinearProgressIndicator();
        var docs = snap.data!.docs;

        int aman = docs.where((d) {
          var data = d.data() as Map<String, dynamic>;
          return data['condition'] == 'aman' && data['last_check'] == tglIni;
        }).length;

        int temuan = docs.where((d) {
          var data = d.data() as Map<String, dynamic>;
          return data['condition'] == 'temuan';
        }).length;

        int overdue = docs.where((d) {
          var data = d.data() as Map<String, dynamic>;
          int target = data['kpi_target'] ?? 10;
          int group = data['plan_group'] ?? 0;
          String last = data['last_check'] ?? "";

          bool isJadwal = false;
          if (target == 10) {
            int day = DateTime.now().day;
            int grupSekarang = (day % 3 == 0) ? 3 : (day % 3);
            isJadwal = (group == grupSekarang);
          } else {
            isJadwal = (group == weekdayIni);
          }
          return isJadwal && last != tglIni;
        }).length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              _statusMiniBox("AMAN (HARI INI)", aman, Colors.green,
                  Icons.check_circle_outline),
              _statusMiniBox("TEMUAN AKTIF", temuan, Colors.orange,
                  Icons.warning_amber_rounded),
              _statusMiniBox(
                  "BELUM DICEK", overdue, Colors.red, Icons.timer_outlined),
            ],
          ),
        );
      },
    );
  }

  Widget _statusMiniBox(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 5),
            Text("$count",
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 8, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitStatsGrid(String monthYear) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('units').snapshots(),
      builder: (context, unitSnapshot) {
        if (!unitSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('inspections').snapshots(),
          builder: (context, insSnapshot) {
            if (!insSnapshot.hasData) return const SizedBox();

            // Filter Inspeksi berdasarkan Bulan
            var monthIns = insSnapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['timestamp'] == null) return false;
              DateTime date = (data['timestamp'] as Timestamp).toDate();
              return DateFormat('MM-yyyy').format(date) == monthYear;
            }).toList();

            // Grouping Unit berdasarkan Vehicle Desc
            Map<String, List<Map<String, dynamic>>> unitGroups = {};
            for (var doc in unitSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              String desc = data['vehicle_desc'] ?? 'LAINNYA';
              if (!unitGroups.containsKey(desc)) unitGroups[desc] = [];
              unitGroups[desc]!.add(data);
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.7, // Ditinggiin dikit biar muat teks bawah
              ),
              itemCount: unitGroups.keys.length,
              itemBuilder: (context, index) {
                String className = unitGroups.keys.elementAt(index);
                List<Map<String, dynamic>> unitsInClass =
                    unitGroups[className]!;

                // LOGIKA TARGET DISKUSI: DT/HD = 10x, Support/Lainnya = 4x
                int targetPerUnit =
                    (className.toUpperCase().contains('SUPPORT') ||
                            className.toUpperCase().contains('GREADER') ||
                            className.toUpperCase().contains('LOADER'))
                        ? 4
                        : 10;

                int totalUnit = unitsInClass.length;
                int totalTargetKPI = totalUnit * targetPerUnit;

                // Hitung total form masuk untuk kelas ini
                var codesInClass = unitsInClass
                    .map((u) => u['unit_code']?.toString().toLowerCase() ?? "")
                    .toSet();
                var checkedInClass = monthIns.where((ins) {
                  var insData = ins.data() as Map<String, dynamic>;
                  return codesInClass
                      .contains(insData['unit_code']?.toString().toLowerCase());
                }).toList();

                int totalFormMasuk = checkedInClass.length;
                double qtyPercent = totalTargetKPI == 0
                    ? 0
                    : (totalFormMasuk / totalTargetKPI) * 100;

                // Accuracy
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
                      Text(className,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 8)),
                      Text("Tot = $totalUnit",
                          style:
                              const TextStyle(fontSize: 8, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSmallProgress(qtyPercent.clamp(0, 100), "QTY",
                              qtyPercent >= 100 ? Colors.green : Colors.orange),
                          _buildSmallProgress(accPercent, "ACC",
                              accPercent >= 100 ? Colors.blue : Colors.red),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text("$totalFormMasuk / $totalTargetKPI",
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.bold)),
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

  Widget _buildSmallProgress(double value, String label, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 3,
                backgroundColor: Colors.grey[100],
                color: color,
              ),
            ),
            Text("${value.toStringAsFixed(0)}%",
                style:
                    const TextStyle(fontSize: 7, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 7, fontWeight: FontWeight.bold, color: color)),
      ],
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
            // Ambil top 5 aja biar gak kepanjangan
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(e.key)
                  .get(),
              builder: (context, userSnap) {
                String name = e.key.toUpperCase();
                if (userSnap.hasData && userSnap.data!.exists) {
                  name =
                      (userSnap.data!.data() as Map<String, dynamic>)['nama'] ??
                          e.key.toUpperCase();
                }
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade100)),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.orange.shade50,
                        child: Text(name[0],
                            style: const TextStyle(
                                fontSize: 10, color: Colors.orange))),
                    title: Text(name,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    trailing: Text("${e.value} Unit",
                        style: const TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.bold)),
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
