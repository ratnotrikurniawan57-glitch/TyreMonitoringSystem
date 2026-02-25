import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormInspectionScreen extends StatefulWidget {
  final String unitCode;
  final String unitId;

  const FormInspectionScreen(
      {super.key, required this.unitCode, required this.unitId});

  @override
  State<FormInspectionScreen> createState() => _FormInspectionScreenState();
}

class _FormInspectionScreenState extends State<FormInspectionScreen> {
  // --- VARIABEL KONTROL ---
  String? selectedLocation;
  bool isUrgent = false;
  final TextEditingController _descController = TextEditingController();
  bool isSubmitting = false;

  // --- VARIABEL MULTI-TYREMAN ---
  List<Map<String, dynamic>> _allUsers =
      []; // Master data tyreman dari Firestore
  final List<Map<String, dynamic>> _selectedTeam =
      []; // Tim yang dipilih untuk tugas ini
  String _searchQuery = "";

  final List<String> locations = ['Pitstop', 'Workshop', 'Moving', 'Refueling'];

  @override
  void initState() {
    super.initState();
    _fetchTyremanList(); // Ambil daftar nama tyreman saat form dibuka
  }

  // AMBIL DAFTAR TYREMAN DARI DATABASE
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

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  // LOGIKA SIMPAN DATA
  Future<void> _submitInspection() async {
    if (selectedLocation == null) {
      _showSnackBar("❌ Pilih Lokasi dulu!", Colors.red);
      return;
    }
    if (_selectedTeam.isEmpty) {
      _showSnackBar("❌ Pilih minimal 1 orang tim!", Colors.red);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      // 1. Cek Akurasi (Target 100%)
      var unitDoc = await FirebaseFirestore.instance
          .collection('units')
          .doc(widget.unitId)
          .get();
      int planGroup = unitDoc.data()?['plan_group'] ?? 0;
      int day = DateTime.now().day;
      int currentTargetGroup = (day % 3 == 0) ? 3 : day % 3;
      bool isAccurate = (planGroup == currentTargetGroup);

      // 2. Ambil semua NRP dari tim yang dipilih (Array)
      List<String> teamNrps =
          _selectedTeam.map((t) => t['nrp'].toString()).toList();

      // 3. Simpan ke koleksi Inspections (1 Data untuk semua)
      await FirebaseFirestore.instance.collection('inspections').add({
        'unit_code': widget.unitCode.toLowerCase(),
        'timestamp': FieldValue.serverTimestamp(),
        'lokasi': selectedLocation!.toLowerCase(),
        'status': isUrgent ? 'yellow' : 'green',
        'finding_desc': _descController.text.trim(),
        'team_nrp': teamNrps, // DISIMPAN SEBAGAI ARRAY
        'is_accurate': isAccurate,
      });

      // 4. Update Status di Master Unit
      await FirebaseFirestore.instance
          .collection('units')
          .doc(widget.unitId)
          .update({
        'current_status': isUrgent ? 'yellow' : 'green',
        'last_check': FieldValue.serverTimestamp(),
        'last_team': teamNrps,
      });

      if (!mounted) return;
      _showSnackBar(
          "✅ Berhasil disimpan untuk ${teamNrps.length} orang", Colors.green);
      Navigator.pop(context);
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INFO UNIT
            Card(
              color: Colors.blueGrey.shade50,
              child: ListTile(
                leading: const Icon(Icons.local_shipping),
                title: Text("Unit: ${widget.unitCode.toUpperCase()}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),

            // INPUT TIM (PENCARIAN)
            const Text("TIM PENGECEKAN",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: "Ketik Nama atau NRP tim...",
                prefixIcon: const Icon(Icons.person_add),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),

            // HASIL PENCARIAN USER
            if (_searchQuery.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10)),
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
                            title: Text(u['nama']),
                            subtitle: Text("NRP: ${u['nrp']}"),
                            onTap: () {
                              setState(() {
                                if (!_selectedTeam
                                    .any((item) => item['nrp'] == u['nrp'])) {
                                  _selectedTeam.add(u);
                                }
                                _searchQuery = ""; // Reset search
                              });
                            },
                          ))
                      .toList(),
                ),
              ),

            // DAFTAR TIM TERPILIH (CHIPS)
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _selectedTeam
                  .map((t) => Chip(
                        backgroundColor: Colors.blue.shade100,
                        label: Text(t['nama']),
                        onDeleted: () =>
                            setState(() => _selectedTeam.remove(t)),
                      ))
                  .toList(),
            ),

            const Divider(height: 40),

            // LOKASI
            const Text("LOKASI", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10))),
              value: selectedLocation,
              items: locations
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (val) => setState(() => selectedLocation = val),
            ),

            const SizedBox(height: 20),

            // CATATAN TEMUAN
            const Text("CATATAN / TEMUAN",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),

            // SWITCH KUNING (URGENT)
            SwitchListTile(
              title: const Text("ADA TEMUAN (KUNING)",
                  style: TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold)),
              value: isUrgent,
              onChanged: (val) => setState(() => isUrgent = val),
            ),

            const SizedBox(height: 30),

            // TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white),
                onPressed: isSubmitting ? null : _submitInspection,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SIMPAN LAPORAN"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
