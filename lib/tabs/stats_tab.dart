import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("PERFORMA KELAS UNIT",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _buildUnitStats(startOfMonth, endOfMonth),
            const Divider(thickness: 2),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                  "TOP TYREMAN - ${DateFormat('MMMM yyyy').format(now).toUpperCase()}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _buildTyremanLeaderboard(startOfMonth, endOfMonth),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitStats(DateTime start, DateTime end) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('units').snapshots(),
      builder: (context, unitSnapshot) {
        if (!unitSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('inspections')
              .where('timestamp', isGreaterThanOrEqualTo: start)
              .where('timestamp', isLessThanOrEqualTo: end)
              .snapshots(),
          builder: (context, insSnapshot) {
            if (!insSnapshot.hasData) return const SizedBox();

            Map<String, List<String>> classes = {};

            // PERBAIKAN: Gunakan Map data() agar lebih aman saat cek field
            for (var doc in unitSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              // Jika field vehicle_desc tidak ada, pakai 'LAINNYA'
              String desc = data.containsKey('vehicle_desc')
                  ? data['vehicle_desc']
                  : 'LAINNYA';
              String unitId = doc.id;

              if (!classes.containsKey(desc)) classes[desc] = [];
              classes[desc]!.add(unitId);
            }

            List<String> checkedUnits = insSnapshot.data!.docs
                .map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return data.containsKey('unit_code')
                      ? data['unit_code'].toString()
                      : '';
                })
                .where((id) => id.isNotEmpty)
                .toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classes.keys.length,
              itemBuilder: (context, index) {
                String className = classes.keys.elementAt(index);
                List<String> allUnitsInClass = classes[className]!;

                int countChecked = allUnitsInClass
                    .where((u) => checkedUnits.contains(u))
                    .length;
                double qtyPercent = allUnitsInClass.isEmpty
                    ? 0
                    : (countChecked / allUnitsInClass.length) * 100;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(className.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(
                            "Qty: $countChecked/${allUnitsInClass.length} Unit (${qtyPercent.toStringAsFixed(0)}%)"),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: qtyPercent / 100,
                          backgroundColor: Colors.grey.shade300,
                          color: qtyPercent == 100 ? Colors.green : Colors.blue,
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

  Widget _buildTyremanLeaderboard(DateTime start, DateTime end) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('inspections')
          .where('timestamp', isGreaterThanOrEqualTo: start)
          .where('timestamp', isLessThanOrEqualTo: end)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        Map<String, int> tyremanPoints = {};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          List<dynamic> nrps = data['team_nrp'] ?? [];
          for (var nrp in nrps) {
            String n = nrp.toString().toLowerCase();
            tyremanPoints[n] = (tyremanPoints[n] ?? 0) + 1;
          }
        }

        var sortedList = tyremanPoints.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedList.length,
          itemBuilder: (context, index) {
            final entry = sortedList[index];
            return ListTile(
              leading: CircleAvatar(child: Text("${index + 1}")),
              title: Text(entry.key),
              trailing: Text("${entry.value} X",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue)),
            );
          },
        );
      },
    );
  }
}
