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
  // --- VARIABEL KONTROL ---
  String? selectedLocation;
  bool isUrgent = false;
  final TextEditingController _descController = TextEditingController();
  bool isSubmitting = false;

  // --- VARIABEL MULTI-TYREMAN ---
  List<Map<String, dynamic>> _allUsers = [];
  final List<Map<String, dynamic>> _selectedTeam = [];
  String _searchQuery = "";

  final List<String> locations = ['Pitstop', 'Workshop', 'Moving', 'Refueling'];

  @override
  void initState() {
    super.initState();
    _fetchTyremanList();
  }

  // AMBIL DAFTAR TYREMAN (Fokus ke Role Tyreman)
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

  // LOGIKA SIMPAN DATA (Sakti & Akurat)
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
      // 1. Ambil Data Unit untuk cek Akurasi & Target
      var unitDoc = await FirebaseFirestore.instance
          .collection('units')
          .doc(widget.unitId)
          .get();
      var data = unitDoc.data() ?? {};

      int planGroup = data['plan_group'] ?? 0;
      int kpiTarget = data['kpi_target'] ?? 10;

      DateTime now = DateTime.now();
      String tanggalHariIni = DateFormat('yyyy-MM-dd').format(now);

      // 2. LOGIKA AKURASI SAKTI (Produksi vs Support)
      bool isAccurate = false;
      if (kpiTarget == 10) {
        // Rumus Produksi: Rotasi 3 hari (Grup 1, 2, 3)
        int groupProdHariIni = (now.day % 3) == 0 ? 3 : (now.day % 3);
        isAccurate = (planGroup == groupProdHariIni);
      } else {
        // Rumus Support: Sesuai Hari Kalender (weekday 1-7)
        isAccurate = (planGroup == now.weekday);
      }

      // 3. Mapping NRP Tim (Pastikan lowercase sesuai aturan Firebase kita)
      List<String> teamNrps =
          _selectedTeam.map((t) => t['nrp'].toString().toLowerCase()).toList();

      // 4. Simpan ke Riwayat Inspeksi (History)
      await FirebaseFirestore.instance.collection('inspections').add({
        'unit_code': widget.unitCode.toLowerCase(),
        'timestamp': FieldValue.serverTimestamp(),
        'tanggal_cek': tanggalHariIni,
        'lokasi': selectedLocation!.toLowerCase(),
        'condition': isUrgent ? 'temuan' : 'aman',
        'finding_desc': _descController.text.trim(),
        'team_nrp': teamNrps,
        'is_accurate': isAccurate,
      });

      // 5. Update Status di Dokumen Unit (INILAH YANG MERUBAH WARNA DASHBOARD)
      await FirebaseFirestore.instance
          .collection('units')
          .doc(widget.unitId)
          .update({
        'condition': isUrgent ? 'temuan' : 'aman',
        'last_check': tanggalHariIni, // Kunci agar unit jadi Putih/Hijau
        'updated_at': FieldValue.serverTimestamp(),
        'last_inspector_team': teamNrps,
      });

      if (!mounted) return;
      _showSnackBar("✅ Laporan Berhasil Terkirim!", Colors.green);
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
            // CARD INFO UNIT
            Card(
              elevation: 0,
              color: Colors.blueGrey.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading:
                    const Icon(Icons.local_shipping, color: Colors.blueGrey),
                title: Text("UNIT: ${widget.unitCode.toUpperCase()}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    const Text("Pastikan unit dalam posisi aman sebelum dicek"),
              ),
            ),
            const SizedBox(height: 20),

            // INPUT TIM TYREMAN
            const Text("PILIH TIM TYREMAN",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: "Cari Nama/NRP...",
                prefixIcon: const Icon(Icons.person_search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade100,
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
                constraints: const BoxConstraints(maxHeight: 200),
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

            // CHIPS TIM TERPILIH
            const SizedBox(height: 10),
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

            // LOKASI UNIT
            const Text("LOKASI UNIT",
                style: TextStyle(fontWeight: FontWeight.bold)),
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
            const Text("CATATAN TAMBAHAN",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                  hintText: "Contoh: Ban kiri pecah, perlu ganti segera...",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),

            const SizedBox(height: 10),

            // TOGGLE TEMUAN (KUNING KEDIP)
            Container(
              decoration: BoxDecoration(
                color: isUrgent ? Colors.orange.shade50 : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SwitchListTile(
                title: const Text("ADA TEMUAN?",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    const Text("Aktifkan jika unit butuh perbaikan segera"),
                secondary: Icon(Icons.warning_amber_rounded,
                    color: isUrgent ? Colors.orange : Colors.grey),
                value: isUrgent,
                activeColor: Colors.orange,
                onChanged: (val) => setState(() => isUrgent = val),
              ),
            ),

            const SizedBox(height: 30),

            // TOMBOL KIRIM
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: isSubmitting ? null : _submitInspection,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("KIRIM LAPORAN",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
