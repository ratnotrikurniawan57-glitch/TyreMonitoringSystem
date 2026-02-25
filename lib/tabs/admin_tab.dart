// ignore_for_file: use_build_context_synchronously, avoid_types_as_parameter_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../model/unit_model.dart';
import '../features/manage_user_screen.dart';

class AdminTab extends StatefulWidget {
  const AdminTab({super.key});

  @override
  State<AdminTab> createState() => _AdminTabState();
}

class _AdminTabState extends State<AdminTab> {
  String _filterPeriode = "";

  // --- FUNGSI QUICK EDIT PLAN GROUP (INT) ---
  void _quickEditPlan(String docId, int currentPlan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update Periode: ${docId.toUpperCase()}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Pilih Group Baru:"),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 2, 3].map((num) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        currentPlan == num ? Colors.blue : Colors.grey.shade300,
                    foregroundColor:
                        currentPlan == num ? Colors.white : Colors.black,
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('units')
                        .doc(docId)
                        .update({
                      'plan_group': num,
                    });
                    Navigator.pop(context);
                  },
                  child: Text("$num"),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // --- FUNGSI TAMBAH MASTER DATA ---
  Future<void> _addMasterData(String collectionName, String newValue) async {
    if (newValue.isEmpty) return;
    String cleanValue = newValue.trim().toUpperCase();
    await FirebaseFirestore.instance
        .collection('settings')
        .doc(collectionName)
        .set({
      'list': FieldValue.arrayUnion([cleanValue])
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // MENU UTAMA ATAS
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                _menuBtn("MANAGE\nUSER", Icons.group_add, Colors.blue, () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => const ManageUserScreen()));
                }),
                const SizedBox(width: 10),
                _menuBtn("TAMBAH\nUNIT", Icons.add_box, Colors.green,
                    () => _showAddUnitDialog(context)),
                const SizedBox(width: 10),
                _menuBtn("IMPORT\n117 UNIT", Icons.cloud_download,
                    Colors.purple, _importMassal),
              ],
            ),
          ),
          const Divider(thickness: 2),

          // SEARCH PERIODE & SORTING
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Cari Periode (1, 2, atau 3)...",
                prefixIcon: const Icon(Icons.filter_alt),
                suffixIcon: _filterPeriode.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _filterPeriode = ""))
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _filterPeriode = val),
            ),
          ),
          const SizedBox(height: 10),

          // GRID DAFTAR UNIT
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('units')
                  .orderBy('plan_group', descending: false)
                  .orderBy('unit_code', descending: false)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snap.data!.docs.where((d) {
                  if (_filterPeriode.isEmpty) return true;
                  return d['plan_group'].toString() == _filterPeriode;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("Data tidak ditemukan"));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var d = docs[i].data() as Map<String, dynamic>;
                    String id = docs[i].id;
                    int p = d['plan_group'] is int ? d['plan_group'] : 1;

                    return InkWell(
                      onTap: () => _quickEditPlan(id, p),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(id.toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 11),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text("G: $p",
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- FORM TAMBAH UNIT (ANTI-NUMPUK) ---
  void _showAddUnitDialog(BuildContext context) {
    final unitController = TextEditingController();
    String? selectedBrand;
    String? selectedDesc;
    int selectedPlan = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("TAMBAH UNIT BARU"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                          labelText: "Kode Unit (Contoh: DT01)")),
                  const SizedBox(height: 10),
                  _buildDynamicDropdown("brands", "Pilih Brand", selectedBrand,
                      (val) => setDialogState(() => selectedBrand = val)),
                  const SizedBox(height: 10),
                  _buildDynamicDropdown(
                      "descriptions",
                      "Pilih Kelas/Desc",
                      selectedDesc,
                      (val) => setDialogState(() => selectedDesc = val)),
                  const SizedBox(height: 20),
                  const Text("Plan Group:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [1, 2, 3]
                        .map((n) => ChoiceChip(
                              label: Text("Grup $n"),
                              selected: selectedPlan == n,
                              onSelected: (s) =>
                                  setDialogState(() => selectedPlan = n),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("BATAL")),
            ElevatedButton(
              onPressed: () async {
                if (unitController.text.isNotEmpty &&
                    selectedBrand != null &&
                    selectedDesc != null) {
                  await FirebaseFirestore.instance
                      .collection('units')
                      .doc(unitController.text.trim().toLowerCase())
                      .set({
                    'unit_code': unitController.text.trim().toLowerCase(),
                    'brand': selectedBrand,
                    'vehicle_desc': selectedDesc,
                    'plan_group': selectedPlan,
                    'current_status': 'white',
                    'updated_at': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("SIMPAN"),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DROPDOWN DINAMIS ---
  Widget _buildDynamicDropdown(
      String coll, String label, String? current, Function(String?) onChanged) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc(coll)
          .snapshots(),
      builder: (context, snap) {
        List<String> items = [];
        if (snap.hasData && snap.data!.exists) {
          items = List<String>.from(snap.data!['list'] ?? []);
        }
        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: current,
                decoration: InputDecoration(labelText: label),
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              onPressed: () => _showAddMasterDialog(coll),
            )
          ],
        );
      },
    );
  }

  // --- DIALOG TAMBAH PILIHAN (BRAND/DESC) ---
  void _showAddMasterDialog(String coll) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Tambah ${coll.toUpperCase()}"),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Masukkan nama...")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("BATAL")),
          ElevatedButton(
              onPressed: () {
                _addMasterData(coll, controller.text);
                Navigator.pop(context);
              },
              child: const Text("SIMPAN")),
        ],
      ),
    );
  }

  // --- WIDGET TOMBOL MENU ---
  Widget _menuBtn(String t, IconData i, Color c, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c)),
          child: Column(children: [
            Icon(i, color: c),
            const SizedBox(height: 5),
            Text(t,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: c, fontSize: 9, fontWeight: FontWeight.bold))
          ]),
        ),
      ),
    );
  }

  // --- FUNGSI IMPORT MASSAL ---
  Future<void> _importMassal() async {
    for (var i = 0; i < UnitModel.masterDataList.length; i++) {
      var item = UnitModel.masterDataList[i];
      await FirebaseFirestore.instance
          .collection('units')
          .doc(item['code'].toString().toLowerCase())
          .set({
        'unit_code': item['code'].toString().toLowerCase(),
        'brand': item['brand'].toString().toUpperCase(),
        'vehicle_desc': item['desc'].toString().toUpperCase(),
        'plan_group': (i % 3) + 1,
        'current_status': 'white',
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Sukses Import 117 Unit!")));
  }
}
