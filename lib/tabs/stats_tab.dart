import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    // Filter manual di aplikasi untuk bulan ini
    String currentMonthYear = DateFormat('MM-yyyy').format(now);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN 1: RINGKASAN STATUS UNIT ---
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text("RINGKASAN STATUS UNIT",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            _buildOverallStatus(),

            // --- BAGIAN 2: PERFORMA PER KELAS ---
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
                  const Text("TOP TYREMAN",
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

        int green =
            snap.data!.docs.where((d) => d['current_status'] == 'green').length;
        int yellow = snap.data!.docs
            .where((d) => d['current_status'] == 'yellow')
            .length;
        int white =
            snap.data!.docs.where((d) => d['current_status'] == 'white').length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _statusMiniBox("AMAN", green, Colors.green),
              _statusMiniBox("PANTAU", yellow, Colors.orange),
              _statusMiniBox("BELUM", white, Colors.grey),
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
        if (!unitSnapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        return StreamBuilder<QuerySnapshot>(
          // STREAM AMAN: Tanpa filter where yang bikin muter
          stream:
              FirebaseFirestore.instance.collection('inspections').snapshots(),
          builder: (context, insSnapshot) {
            if (!insSnapshot.hasData) return const SizedBox();

            // Filter manual berdasarkan bulan ini dari timestamp
            var filteredIns = insSnapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['timestamp'] == null) return false;
              DateTime date = (data['timestamp'] as Timestamp).toDate();
              return DateFormat('MM-yyyy').format(date) == monthYear;
            }).toList();

            Map<String, List<String>> classes = {};
            for (var doc in unitSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              String desc = data['vehicle_desc'] ?? 'LAINNYA';
              String unitId = doc.id;
              if (!classes.containsKey(desc)) classes[desc] = [];
              classes[desc]!.add(unitId);
            }

            List<String> checkedUnits = filteredIns
                .map((d) =>
                    (d.data() as Map<String, dynamic>)['unit_code']
                        ?.toString() ??
                    '')
                .toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classes.keys.length,
              itemBuilder: (context, index) {
                String className = classes.keys.elementAt(index);
                List<String> allUnits = classes[className]!;
                int countChecked =
                    allUnits.where((u) => checkedUnits.contains(u)).length;
                double qtyPercent = allUnits.isEmpty
                    ? 0
                    : (countChecked / allUnits.length) * 100;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    title: Text(className.toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(
                            "Qty: $countChecked/${allUnits.length} Unit (${qtyPercent.toStringAsFixed(0)}%)",
                            style: const TextStyle(fontSize: 11)),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: qtyPercent / 100,
                          backgroundColor: Colors.grey.shade200,
                          color: qtyPercent == 100 ? Colors.green : Colors.blue,
                          minHeight: 6,
                        ),
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

        Map<String, int> tyremanPoints = {};

        // Filter manual bulan ini
        var filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['timestamp'] == null) return false;
          DateTime date = (data['timestamp'] as Timestamp).toDate();
          return DateFormat('MM-yyyy').format(date) == monthYear;
        });

        for (var doc in filteredDocs) {
          final data = doc.data() as Map<String, dynamic>;
          List<dynamic> nrps = data['team_nrp'] ?? [];
          for (var nrp in nrps) {
            String n = nrp.toString().toLowerCase();
            tyremanPoints[n] = (tyremanPoints[n] ?? 0) + 1;
          }
        }

        var sortedList = tyremanPoints.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (sortedList.isEmpty)
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Belum ada data inspeksi bulan ini",
                      style: TextStyle(color: Colors.grey))));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedList.length,
          itemBuilder: (context, index) {
            final entry = sortedList[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Text("${index + 1}",
                        style: const TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold))),
                title: Text(entry.key, style: const TextStyle(fontSize: 14)),
                trailing: Text("${entry.value} X",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue)),
              ),
            );
          },
        );
      },
    );
  }
}
