import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FormInspectionScreen extends StatefulWidget {
  final String unitCode;
  final String unitId;

  const FormInspectionScreen(
      {super.key, required this.unitCode, required this.unitId});

  @override
  State<FormInspectionScreen> createState() => _FormInspectionScreenState();
}

class _FormInspectionScreenState extends State<FormInspectionScreen> {
  String? selectedLocation;
  bool isUrgent = false;
  final TextEditingController _descController = TextEditingController();
  bool isSubmitting = false;

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  List<Map<String, dynamic>> _allUsers = [];
  final List<Map<String, dynamic>> _selectedTeam = [];
  String _searchQuery = "";

  final List<String> locations = [
    '1.Pitstop',
    '2.Workshop',
    '3.Moving',
    '4.Refueling'
  ];

  @override
  void initState() {
    super.initState();
    _fetchTyremanList();
  }

  Future<void> _fetchTyremanList() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'tyreman')
          .get();
      setState(() {
        _allUsers = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      debugPrint("Gagal ambil user: $e");
    }
  }

  // --- FUNGSI NOTIFIKASI DIHAPUS DARI SINI (PINDAH KE CLOUD FUNCTIONS) ---

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitInspection() async {
    if (selectedLocation == null || _selectedTeam.isEmpty) {
      _showSnackBar("❌ Lengkapi Lokasi & Tim dulu!", Colors.red);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      DateTime finalDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // Gunakan lowercase & underscores sesuai aturan Firebase kita
      String docId =
          "${widget.unitCode.toLowerCase()}_${finalDateTime.millisecondsSinceEpoch}";
      List<String> teamNrps =
          _selectedTeam.map((t) => t['nrp'].toString().toLowerCase()).toList();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference insRef =
          FirebaseFirestore.instance.collection('inspections').doc(docId);
      DocumentReference unitRef =
          FirebaseFirestore.instance.collection('units').doc(widget.unitId);

      // 1. Simpan Data Inspeksi
      batch.set(insRef, {
        'unit_code': widget.unitCode.toLowerCase(),
        'timestamp': FieldValue.serverTimestamp(),
        'actual_time': finalDateTime.toIso8601String(),
        'tanggal_cek': DateFormat('yyyy-MM-dd').format(finalDateTime),
        'lokasi': selectedLocation!.toLowerCase(),
        'condition': isUrgent ? 'temuan' : 'aman',
        'finding_desc': _descController.text.trim(),
        'team_nrp': teamNrps,
        'is_accurate': true, // Target KPI Accuracy 100%
      });

      // 2. Update Status Unit di Koleksi Master
      batch.update(unitRef, {
        'condition': isUrgent ? 'temuan' : 'aman',
        'last_check': DateFormat('yyyy-MM-dd').format(finalDateTime),
        'updated_at': FieldValue.serverTimestamp(),
        'last_inspector_team': teamNrps,
      });

      // --- EKSEKUSI BATCH ---
      await batch.commit();

      // Feedback user
      _showSnackBar(
          isUrgent
              ? "✅ Temuan Tersimpan! Notif dikirim sistem."
              : "✅ Laporan Aman Tersimpan!",
          Colors.green);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      if (mounted) setState(() => isSubmitting = false);
      _showSnackBar("❌ Gagal: $e", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("INSPEKSI ${widget.unitCode.toUpperCase()}"),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CARD INFO UNIT
            Card(
              color: Colors.blueGrey.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.local_shipping,
                        color: Colors.blueGrey),
                    title: Text("UNIT: ${widget.unitCode.toUpperCase()}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Pastikan unit dalam posisi aman"),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.access_time, color: Colors.orange),
                    title: const Text("Jam Pengecekan"),
                    subtitle: Text(
                        "Klik untuk ubah: ${selectedTime.format(context)}"),
                    onTap: () => _selectTime(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // PILIH TEAM TYREMAN
            const Text("PILIH TIM TYREMAN",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: "Cari Nama/NRP...",
                prefixIcon: const Icon(Icons.person_search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
            if (_searchQuery.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12)),
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView(
                  shrinkWrap: true,
                  children: _allUsers
                      .where((u) =>
                          u['nrp'].toString().contains(_searchQuery) ||
                          u['nama']
                              .toString()
                              .toLowerCase()
                              .contains(_searchQuery))
                      .map((u) => ListTile(
                            title: Text(u['nama'] ?? ""),
                            subtitle: Text("NRP: ${u['nrp']}"),
                            onTap: () {
                              setState(() {
                                if (!_selectedTeam
                                    .any((item) => item['nrp'] == u['nrp'])) {
                                  _selectedTeam.add(u);
                                }
                                _searchQuery = "";
                              });
                            },
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _selectedTeam
                  .map((t) => InputChip(
                        label: Text(t['nama']),
                        onDeleted: () =>
                            setState(() => _selectedTeam.remove(t)),
                        deleteIconColor: Colors.red,
                      ))
                  .toList(),
            ),
            const Divider(height: 40),

            // INPUT LOKASI
            const Text("LOKASI UNIT",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
              value: selectedLocation,
              items: locations
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (val) => setState(() => selectedLocation = val),
            ),
            const SizedBox(height: 20),

            // INPUT TEMUAN
            const Text("CATATAN TEMUAN",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Contoh: Ban kiri aus...",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text("ADA TEMUAN?",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Unit butuh perbaikan segera"),
              secondary: Icon(Icons.warning_amber_rounded,
                  color: isUrgent ? Colors.orange : Colors.grey),
              value: isUrgent,
              activeColor: Colors.orange,
              onChanged: (val) => setState(() => isUrgent = val),
            ),
            const SizedBox(height: 30),

            // TOMBOL SUBMIT
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSubmitting ? null : _submitInspection,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("KIRIM LAPORAN",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
