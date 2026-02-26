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
  String _filterPeriode = "1";
  final List<String> _namaHari = [
    "",
    "Senin",
    "Selasa",
    "Rabu",
    "Kamis",
    "Jumat",
    "Sabtu",
    "Minggu"
  ];

  void _quickEditPlan(String docId, int currentPlan, int target) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("OPSI UNIT: ${docId.toUpperCase()}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(target == 4 ? "Ganti Hari Cek:" : "Pilih Group Baru:"),
            const SizedBox(height: 15),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: (target == 4 ? [1, 2, 3, 4, 5, 6, 7] : [1, 2, 3])
                    .map((num) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentPlan == num
                            ? Colors.blue
                            : Colors.grey.shade300,
                        foregroundColor:
                            currentPlan == num ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('units')
                            .doc(docId)
                            .update({'plan_group': num});
                        Navigator.pop(context);
                      },
                      child: Text(target == 4
                          ? _namaHari[num].substring(0, 3)
                          : "$num"),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            TextButton.icon(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text("HAPUS UNIT INI",
                  style: TextStyle(color: Colors.red)),
              onPressed: () => _confirmDeleteUnit(docId),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUnit(String docId) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: Text("Yakin mau hapus unit ${docId.toUpperCase()}?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("BATAL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('units')
                  .doc(docId)
                  .delete();
              Navigator.pop(c);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("🗑️ Unit Berhasil Dihapus!")));
            },
            child: const Text("HAPUS", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
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
                _menuBtn("SYNC MASTER\nUNIT DATA", Icons.cloud_download,
                    Colors.purple, _importMassal),
              ],
            ),
          ),
          const Divider(thickness: 2),
          // Filter Group Produksi
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                _buildFilterButton("G1", "1"),
                const SizedBox(width: 5),
                _buildFilterButton("G2", "2"),
                const SizedBox(width: 5),
                _buildFilterButton("G3", "3"),
                const SizedBox(width: 5),
                const VerticalDivider(),
                ...[1, 2, 3, 4, 5, 6, 7].map((h) => Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: _buildFilterButton(
                          _namaHari[h].substring(0, 3), h.toString()),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('units').snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snap.data!.docs
                    .where((d) => d['plan_group'].toString() == _filterPeriode)
                    .toList();
                docs.sort((a, b) => (a.id).compareTo(b.id));
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
                    int p = d['plan_group'] ?? 1;
                    int target = d['kpi_target'] ?? 10;
                    return InkWell(
                      onTap: () => _quickEditPlan(id, p, target),
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
                                    fontWeight: FontWeight.bold, fontSize: 10)),
                            const SizedBox(height: 4),
                            Text(target == 4 ? "SUP" : "PROD",
                                style: TextStyle(
                                    fontSize: 8,
                                    color: target == 4
                                        ? Colors.orange
                                        : Colors.green)),
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

  Widget _buildFilterButton(String label, String value) {
    bool isActive = _filterPeriode == value;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        backgroundColor: isActive ? Colors.blue : Colors.grey.shade200,
        foregroundColor: isActive ? Colors.white : Colors.black,
      ),
      onPressed: () => setState(() => _filterPeriode = value),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Future<void> _importMassal() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()));
    for (var item in UnitModel.masterDataList) {
      await FirebaseFirestore.instance
          .collection('units')
          .doc(item['code'].toString().toLowerCase())
          .set({
        'unit_code': item['code'].toString().toLowerCase(),
        'brand': item['brand'].toString().toUpperCase(),
        'vehicle_desc': item['desc'].toString().toUpperCase(),
        'plan_group': item['group'] ?? 1,
        'kpi_target': item['target'] ?? 10,
        'condition': 'aman',
        'last_check': null,
      });
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Sukses Sync 147 Unit dengan Target!")));
  }

  void _showAddUnitDialog(BuildContext context) {
    final unitController = TextEditingController();
    String? selectedBrand;
    String? selectedDesc;
    int selectedPlan = 1;
    int selectedTarget = 10;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("TAMBAH UNIT BARU"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: unitController,
                    decoration: const InputDecoration(labelText: "Kode Unit")),
                _buildDynamicDropdown("brands", "Brand", selectedBrand,
                    (val) => setDialogState(() => selectedBrand = val)),
                _buildDynamicDropdown("descriptions", "Desc", selectedDesc,
                    (val) => setDialogState(() => selectedDesc = val)),
                const SizedBox(height: 15),
                const Text("Target Check:"),
                Row(
                  children: [
                    Expanded(
                        child: ChoiceChip(
                            label: const Text("10x (Prod)"),
                            selected: selectedTarget == 10,
                            onSelected: (s) =>
                                setDialogState(() => selectedTarget = 10))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: ChoiceChip(
                            label: const Text("4x (Supp)"),
                            selected: selectedTarget == 4,
                            onSelected: (s) =>
                                setDialogState(() => selectedTarget = 4))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(selectedTarget == 10 ? "Pilih Group:" : "Pilih Hari:"),
                Wrap(
                  spacing: 5,
                  children:
                      (selectedTarget == 10 ? [1, 2, 3] : [1, 2, 3, 4, 5, 6, 7])
                          .map((n) => ChoiceChip(
                                label: Text(selectedTarget == 10
                                    ? "G$n"
                                    : _namaHari[n].substring(0, 3)),
                                selected: selectedPlan == n,
                                onSelected: (s) =>
                                    setDialogState(() => selectedPlan = n),
                              ))
                          .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("BATAL")),
            ElevatedButton(
              onPressed: () async {
                if (unitController.text.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('units')
                      .doc(unitController.text.trim().toLowerCase())
                      .set({
                    'unit_code': unitController.text.trim().toLowerCase(),
                    'brand': selectedBrand ?? "UNKNOWN",
                    'vehicle_desc': selectedDesc ?? "UNKNOWN",
                    'plan_group': selectedPlan,
                    'kpi_target': selectedTarget,
                    'condition': 'aman',
                    'last_check': null,
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
                    onChanged: onChanged)),
            IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () => _showAddMasterDialog(coll))
          ],
        );
      },
    );
  }

  void _showAddMasterDialog(String coll) {
    final controller = TextEditingController();
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("Tambah ${coll.toUpperCase()}"),
              content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: "Nama...")),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("BATAL")),
                ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('settings')
                          .doc(coll)
                          .set({
                        'list': FieldValue.arrayUnion(
                            [controller.text.trim().toUpperCase()])
                      }, SetOptions(merge: true));
                      Navigator.pop(context);
                    },
                    child: const Text("SIMPAN")),
              ],
            ));
  }

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
                        color: c, fontSize: 8, fontWeight: FontWeight.bold))
              ]),
            )));
  }
}
