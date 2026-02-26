import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? startTime : endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  Future<void> _shareToWhatsApp() async {
    final String startStr = startTime.format(context);
    final String endStr = endTime.format(context);

    DateTime startFilter = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, startTime.hour, startTime.minute);
    DateTime endFilter = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, endTime.hour, endTime.minute);

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('inspections')
          .where('timestamp', isGreaterThanOrEqualTo: startFilter)
          .where('timestamp', isLessThanOrEqualTo: endFilter)
          .orderBy('timestamp', descending: false)
          .get();

      if (!mounted) return;
      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("⚠️ Tidak ada data di server pada jam tersebut")));
        return;
      }

      String pesan = "*LAPORAN TYREMAN KOLEKTIF*\n";
      pesan += "📅 Tanggal: ${DateFormat('dd/MM/yyyy').format(selectedDate)}\n";
      pesan += "⏰ Jam: $startStr - $endStr\n";
      pesan += "----------------------------\n\n";

      int nomorUrut = 1;
      for (var doc in snapshot.docs) {
        var data = doc.data();
        String unit = (data['unit_code'] ?? "N/A").toString().toUpperCase();
        String lokasi = data['lokasi'] ?? "-";
        String kondisi = data['condition'] == 'temuan' ? "⚠️ TEMUAN" : "✅ AMAN";

        pesan += "$nomorUrut. *UNIT: $unit*\n";
        pesan += "📍 Lokasi: $lokasi\n";
        pesan += "🛠 Kondisi: $kondisi\n";
        pesan += "----------------------------\n";
        nomorUrut++;
      }

      pesan += "\n✅ Total: ${snapshot.docs.length} Unit Selesai.";
      pesan += "\n📌 _Sent via TMS App_";

      final String url = "https://wa.me/?text=${Uri.encodeComponent(pesan)}";
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error Share WA: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // HEADER & FILTER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade900,
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const Text("ANTRIAN LAPORAN (OFFLINE)",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 15),
                _buildFilterButton(
                  icon: Icons.calendar_today,
                  label:
                      "Tanggal: ${DateFormat('dd/MM/yyyy').format(selectedDate)}",
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030));
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: _buildFilterButton(
                            icon: Icons.access_time,
                            label: startTime.format(context),
                            onTap: () => _selectTime(true))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _buildFilterButton(
                            icon: Icons.access_time_filled,
                            label: endTime.format(context),
                            onTap: () => _selectTime(false))),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: _shareToWhatsApp,
                    icon: const Icon(Icons.share),
                    label: const Text("KIRIM REKAP KE WA",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // LIST DATA ANTRIAN (HANYA PENDING)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('inspections')
                  .orderBy('timestamp', descending: true)
                  .snapshots(includeMetadataChanges: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter HANYA yang masih pending (hasPendingWrites)
                final pendingDocs = snapshot.data!.docs
                    .where((doc) => doc.metadata.hasPendingWrites)
                    .toList();

                if (pendingDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_done_rounded,
                            color: Colors.green.shade300, size: 60),
                        const SizedBox(height: 10),
                        const Text("SEMUA DATA TERKIRIM",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        const Text("Tidak ada antrian di HP ini.",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud_off, color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Text("MENUNGGU SINYAL...",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...pendingDocs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.orange.shade50,
                        child: ListTile(
                          leading: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.orange)),
                          title: Text(
                              "UNIT: ${data['unit_code']?.toString().toUpperCase() ?? '??'}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Lokasi: ${data['lokasi'] ?? '-'}"),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
