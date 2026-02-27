// ignore_for_file: avoid_types_as_parameter_names, use_build_context_synchronously
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
      // 🔥 APPBAR SUDAH DIHAPUS TOTAL DI SINI
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN 1: RINGKASAN STATUS ---
            // 🔥 TAMBAHKAN SPACER BIAR GAK KETUTUP STATUS BAR HP
            const SizedBox(height: 5),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
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

            // --- BAGIAN 3: LEADERBOARD ---
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
    ); // 🔥 KURUNG TUTUP SCAFFOLD DI SINI (DULU ERROR DI SINI)
  }

  // ... (Fungsi _buildOverallStatus, _statusMiniBox, _buildUnitStatsGrid, _buildSmallProgress, _buildTyremanLeaderboard tetap sama)

  Widget _buildOverallStatus() {
    String tglIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int weekdayIni = DateTime.now().weekday;
    int dayOfMonth = DateTime.now().day;
    int grupAktif = (dayOfMonth % 3 == 0) ? 3 : (dayOfMonth % 3);

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
            isJadwal = (group == grupAktif);
          } else {
            isJadwal = (group == weekdayIni);
          }
          return isJadwal && last != tglIni;
        }).length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              _statusMiniBox(
                  "AMAN", aman, Colors.green, Icons.check_circle_outline),
              _statusMiniBox(
                  "TEMUAN", temuan, Colors.orange, Icons.warning_amber_rounded),
              _statusMiniBox(
                  "OVERDUE", overdue, Colors.red, Icons.timer_outlined),
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
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Text("$count",
                style: TextStyle(
                    // 🔥 ANGKA STATUS GEDEIN
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, color: color)),
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
              stream: FirebaseFirestore.instance
                  .collection('inspections')
                  .snapshots(),
              builder: (context, insSnapshot) {
                if (!insSnapshot.hasData) return const SizedBox();

                var monthIns = insSnapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['timestamp'] == null) return false;
                  DateTime date = (data['timestamp'] as Timestamp).toDate();
                  return DateFormat('MM-yyyy').format(date) == monthYear;
                }).toList();

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
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.6, // Disesuaikan biar konten muat
                  ),
                  itemCount: unitGroups.keys.length,
                  itemBuilder: (context, index) {
                    String className = unitGroups.keys.elementAt(index);
                    List<Map<String, dynamic>> unitsInClass =
                        unitGroups[className]!;

                    int targetPerUnit =
                        (className.toUpperCase().contains('DT') ||
                                className.toUpperCase().contains('HD'))
                            ? 10
                            : 4;

                    int totalPlanBulanan = unitsInClass.length * targetPerUnit;

                    var codesInClass = unitsInClass
                        .map((u) =>
                            u['unit_code']?.toString().toLowerCase() ?? "")
                        .toSet();

                    var checkedInClass = monthIns.where((ins) {
                      var insData = ins.data() as Map<String, dynamic>;
                      return codesInClass.contains(
                          insData['unit_code']?.toString().toLowerCase());
                    }).toList();

                    int totalInput = checkedInClass.length;
                    double qtyPercent = totalPlanBulanan == 0
                        ? 0
                        : (totalInput / totalPlanBulanan) * 100;

                    int totalTepatJadwal = checkedInClass.where((ins) {
                      var data = ins.data() as Map<String, dynamic>;
                      return data['is_accurate'] == true;
                    }).length;

                    double accPercent = totalPlanBulanan == 0
                        ? 0
                        : (totalTepatJadwal / totalPlanBulanan) * 100;

                    bool isGood = qtyPercent >= 100 && accPercent >= 100;
                    Color cardColor =
                        isGood ? Colors.green.shade50 : Colors.red.shade50;
                    IconData statusIcon = isGood
                        ? Icons.sentiment_satisfied_alt
                        : Icons.sentiment_dissatisfied;
                    Color iconColor = isGood ? Colors.green : Colors.red;

                    return Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(statusIcon, color: iconColor, size: 24),
                          const SizedBox(height: 4),
                          Text(className,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 10)),
                          Text("Unit: ${unitsInClass.length}",
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSmallProgress(
                                  qtyPercent.clamp(0, 100),
                                  "QTY",
                                  qtyPercent >= 100
                                      ? Colors.green
                                      : Colors.orange),
                              _buildSmallProgress(
                                  accPercent.clamp(0, 100),
                                  "ACC",
                                  accPercent >= 100 ? Colors.blue : Colors.red),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text("$totalInput / $totalPlanBulanan",
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                );
              });
        });
  }

  Widget _buildSmallProgress(double value, String label, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 35, // 🔥 Gedein Lingkaran
              width: 35,
              child: CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 4,
                backgroundColor: Colors.grey[200],
                color: color,
              ),
            ),
            Text("${value.toStringAsFixed(0)}%",
                style: const TextStyle(
                    // 🔥 Gedein Tulisan %
                    fontSize: 8,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                // 🔥 Gedein Tulisan QTY/ACC
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: color)),
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
          DateTime insDate = (data['timestamp'] as Timestamp).toDate();
          return DateFormat('MM-yyyy').format(insDate) == monthYear;
        });

        for (var doc in filtered) {
          List nrps = (doc.data() as Map<String, dynamic>)['team_nrp'] ?? [];
          for (var nrp in nrps) {
            String n = nrp.toString().toLowerCase();
            points[n] = (points[n] ?? 0) + 1;
          }
        }
        var sorted = points.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        var top5 = sorted.take(5).toList();

        return Column(
          children: top5.map((e) {
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
                        radius: 14, // 🔥 Gedein Avatar
                        backgroundColor: Colors.orange.shade50,
                        child: Text(name[0],
                            style: const TextStyle(
                                fontSize: 12, color: Colors.orange))),
                    title: Text(name,
                        style: const TextStyle(
                            // 🔥 Gedein Nama
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    trailing: Text("${e.value} Unit",
                        style: const TextStyle(
                            // 🔥 Gedein Jumlah Unit
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold)),
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
