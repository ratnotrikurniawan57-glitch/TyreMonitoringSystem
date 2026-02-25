import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime =
      const TimeOfDay(hour: 6, minute: 0); // Default Shift Pagi
  TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);

  Future<void> _shareToWhatsApp() async {
    // 1. Ambil format teks sebelum masuk ke proses async
    final String startStr = startTime.format(context);
    final String endStr = endTime.format(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 2. Siapkan filter waktu untuk Firestore
    DateTime startFilter = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, startTime.hour, startTime.minute);
    DateTime endFilter = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, endTime.hour, endTime.minute);

    try {
      // 3. Tarik data dari koleksi 'inspections'
      var snapshot = await FirebaseFirestore.instance
          .collection('inspections')
          .where('timestamp', isGreaterThanOrEqualTo: startFilter)
          .where('timestamp', isLessThanOrEqualTo: endFilter)
          .orderBy('timestamp', descending: false)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text("⚠️ Tidak ada data pada jam tersebut")),
        );
        return;
      }

      // 4. Susun Pesan WhatsApp
      String pesan = "*LAPORAN TYREMAN KOLEKTIF*\n";
      pesan +=
          "📅 Tanggal: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}\n";
      pesan += "⏰ Jam: $startStr - $endStr\n";
      pesan += "----------------------------\n\n";

      for (var doc in snapshot.docs) {
        var data = doc.data();
        String unit = (data['unit_code'] ?? "N/A").toString().toUpperCase();
        String lokasi = data['lokasi'] ?? "-";
        String status = (data['status'] ?? "green").toString().toUpperCase();
        String desc = data['finding_desc'] ?? "";
        String tyreman = data['nama_tyreman'] ?? "Tyreman";

        pesan += "🛞 *UNIT: $unit*\n";
        pesan += "📍 Lokasi: $lokasi\n";
        pesan += "📊 Status: $status\n";
        if (desc.isNotEmpty) pesan += "⚠️ Temuan: $desc\n";
        pesan += "👷 Tyreman: $tyreman\n";
        pesan += "----------------------------\n";
      }

      // 5. Eksekusi Pengiriman WA (Gunakan HTTPS agar lebih kompatibel)
      final String url = "https://wa.me/?text=${Uri.encodeComponent(pesan)}";
      final Uri whatsappUrl = Uri.parse(url);

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback cara manual jika canLaunchUrl gagal (beberapa device butuh ini)
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error Share WA: $e");
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text("❌ Terjadi kesalahan: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header & Filter Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade900,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const Text("REKAP LAPORAN SHIFT",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 15),
                // Pilih Tanggal
                _buildFilterItem(
                  icon: Icons.calendar_today,
                  label:
                      "Tanggal: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
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
                // Pilih Jam
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterItem(
                        icon: Icons.access_time,
                        label: "Mulai: ${startTime.format(context)}",
                        onTap: () async {
                          TimeOfDay? picked = await showTimePicker(
                              context: context, initialTime: startTime);
                          if (picked != null) {
                            setState(() => startTime = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildFilterItem(
                        icon: Icons.access_time_filled,
                        label: "Selesai: ${endTime.format(context)}",
                        onTap: () async {
                          TimeOfDay? picked = await showTimePicker(
                              context: context, initialTime: endTime);
                          if (picked != null) setState(() => endTime = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Tombol Share
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _shareToWhatsApp,
                    icon: const Icon(Icons.share),
                    label: const Text("KIRIM LAPORAN KE WA",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          // Preview Area
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                      "Data history akan ditarik otomatis\nberdasarkan rentang waktu di atas",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.orange.shade700),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
