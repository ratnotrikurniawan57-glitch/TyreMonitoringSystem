import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TyreRepairTracker extends StatefulWidget {
  final String role;
  const TyreRepairTracker({super.key, required this.role});

  @override
  State<TyreRepairTracker> createState() => _TyreRepairTrackerState();
}

class _TyreRepairTrackerState extends State<TyreRepairTracker> {
  final List<String> _externalWorkflow = [
    'WS (CHPP)', 'Admin Out', 'Logistik CHPP', 'Transit Tuhup', 
    'Vendor Received (Tuhup)', 'Vendor Workshop (BPN)', 'Repair Finish (BPN)', 
    'Logistik Tuhup (In)', 'Logistik CHPP (In)', 'Admin In', 'Ready'
  ];

  final List<String> _internalWorkflow = ['WS', 'Repairing', 'Ready'];

  // --- 1. FITUR LIHAT HISTORI (BOTTOM SHEET) ---
  void _showHistory(String docId, String sn) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text("Riwayat Perjalanan: $sn", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('tyre_repairs')
                      .doc(docId)
                      .collection('history')
                      .orderBy('updated_at', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    var historyDocs = snapshot.data!.docs;
                    if (historyDocs.isEmpty) return const Center(child: Text("Belum ada histori."));

                    return ListView.builder(
                      itemCount: historyDocs.length,
                      itemBuilder: (context, index) {
                        var hData = historyDocs[index].data() as Map<String, dynamic>;
                        DateTime date = (hData['updated_at'] as Timestamp).toDate();
                        return ListTile(
                          leading: const Icon(Icons.history, color: Colors.orange),
                          title: Text(hData['status'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text("${hData['location']} • ${DateFormat('dd MMM yyyy').format(date)}"),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 2. DIALOG UPDATE STATUS DENGAN KALENDER ---
  Future<void> _showUpdateDialog(String docId, String currentStatus, String type) async {
    List<String> workflow = type == 'External' ? _externalWorkflow : _internalWorkflow;
    String? selectedNewStatus = currentStatus;
    DateTime selectedDate = DateTime.now(); 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Update Status & Tanggal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: workflow.contains(currentStatus) ? currentStatus : workflow[0],
                isExpanded: true,
                items: workflow.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (v) => selectedNewStatus = v,
                decoration: const InputDecoration(labelText: "Status Baru", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Tanggal Kejadian:", style: TextStyle(fontSize: 12)),
                subtitle: Text(DateFormat('dd MMMM yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("BATAL")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
              onPressed: () async {
                if (selectedNewStatus != null) {
                  await _executeStatusUpdate(docId, selectedNewStatus!, selectedDate);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("SIMPAN", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _executeStatusUpdate(String docId, String newStatus, DateTime manualDate) async {
    String location = "CHPP";
    if (newStatus.contains("Tuhup")) { location = "Tuhup"; }
    if (newStatus.contains("BPN") || newStatus.contains("Vendor")) { location = "Balikpapan"; }

    await FirebaseFirestore.instance.collection('tyre_repairs').doc(docId).update({
      'status': newStatus,
      'location': location,
      'updated_at': Timestamp.fromDate(manualDate),
    });

    await FirebaseFirestore.instance.collection('tyre_repairs').doc(docId).collection('history').add({
      'status': newStatus,
      'location': location,
      'updated_at': Timestamp.fromDate(manualDate),
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = widget.role.toLowerCase() == 'admin';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("TIRE REPAIR MONITORING", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF8C00),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tyre_repairs').where('status', isNotEqualTo: 'Ready').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;

          int totalCount = docs.length;
          Map<String, int> sizeCount = {};
          int extCount = 0;
          int intCount = 0;

          for (var d in docs) {
            var data = d.data() as Map<String, dynamic>;
            String size = data['size'] ?? 'N/A';
            if ((data['repair_type'] ?? 'External') == 'External') { extCount++; } else { intCount++; }
            sizeCount[size] = (sizeCount[size] ?? 0) + 1;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    _buildSummaryCard("TOTAL", totalCount.toString(), Colors.black),
                    _buildSummaryCard("EXTERNAL", extCount.toString(), Colors.redAccent),
                    _buildSummaryCard("INTERNAL", intCount.toString(), Colors.green),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: sizeCount.entries.map((e) => Container(
                    margin: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text("${e.key}: ${e.value}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.blue[50],
                    ),
                  )).toList(),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String type = data['repair_type'] ?? 'External';
                    Timestamp? upTs = data['updated_at'] as Timestamp?;
                    String lastUpdate = upTs != null ? DateFormat('dd/MM/yy').format(upTs.toDate()) : '-';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ExpansionTile(
                        leading: Icon(type == 'External' ? Icons.local_shipping : Icons.build, color: type == 'External' ? Colors.red : Colors.green),
                        title: Text("${data['sn']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${data['status']} (Up: $lastUpdate)"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Size: ${data['size']}"),
                                Text("Vendor: ${data['vendor'] ?? '-'}"),
                                Text("Lokasi: ${data['location'] ?? 'CHPP'}"),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    // TOMBOL LIHAT HISTORI
                                    OutlinedButton.icon(
                                      onPressed: () => _showHistory(docs[index].id, data['sn']),
                                      icon: const Icon(Icons.history, size: 16),
                                      label: const Text("RIWAYAT"),
                                    ),
                                    const SizedBox(width: 10),
                                    if (isAdmin) 
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
                                        onPressed: () => _showUpdateDialog(docs[index].id, data['status'], type),
                                        child: const Text("UPDATE", style: TextStyle(color: Colors.white)),
                                      ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF8C00),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTireRepairPage())),
        label: const Text("ADD TIRE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String count, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
              Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HALAMAN TAMBAH TIRE (FULL FORM DENGAN PATH & VENDOR) ---
class AddTireRepairPage extends StatefulWidget {
  const AddTireRepairPage({super.key});
  @override
  State<AddTireRepairPage> createState() => _AddTireRepairPageState();
}

class _AddTireRepairPageState extends State<AddTireRepairPage> {
  final snController = TextEditingController();
  final newItemController = TextEditingController();
  
  String selectedSize = '27.00R49';
  String selectedPath = 'External';
  String selectedVendor = 'PT. Citra Pratama';

  List<String> sizeList = ['27.00R49', '33.00R51', '40.00R57'];
  List<String> vendorList = ['PT. Citra Pratama', 'Rema Tip Top', 'Bridgestone'];

  void _addItem(String title, List<String> list, Function(String) onSet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Tambah $title Baru"),
        content: TextField(
          controller: newItemController, 
          decoration: InputDecoration(hintText: "Nama $title"), 
          textCapitalization: TextCapitalization.characters
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("BATAL")),
          ElevatedButton(onPressed: () {
            if (newItemController.text.isNotEmpty) {
              setState(() { 
                list.add(newItemController.text); 
                onSet(newItemController.text); 
              });
              newItemController.clear(); 
              Navigator.pop(context);
            }
          }, child: const Text("SIMPAN"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Tire Repair")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: snController, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: "S/N Tire")),
            const SizedBox(height: 20),
            // DROPWDOWN SIZE + TOMBOL TAMBAH
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedSize,
                    items: sizeList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => selectedSize = v!),
                    decoration: const InputDecoration(labelText: "Size"),
                  ),
                ),
                IconButton(onPressed: () => _addItem("Size", sizeList, (v) => selectedSize = v), icon: const Icon(Icons.add_circle, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 20),
            // REPAIR PATH (INTERNAL / EXTERNAL)
            const Align(alignment: Alignment.centerLeft, child: Text("Repair Path:", style: TextStyle(fontWeight: FontWeight.bold))),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Internal', label: Text('Internal')), 
                ButtonSegment(value: 'External', label: Text('External'))
              ],
              selected: {selectedPath},
              onSelectionChanged: (val) => setState(() => selectedPath = val.first),
            ),
            // FORM VENDOR HANYA MUNCUL JIKA EXTERNAL
            if (selectedPath == 'External') ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedVendor,
                      items: vendorList.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) => setState(() => selectedVendor = v!),
                      decoration: const InputDecoration(labelText: "Vendor"),
                    ),
                  ),
                  IconButton(onPressed: () => _addItem("Vendor", vendorList, (v) => selectedVendor = v), icon: const Icon(Icons.add_business, color: Colors.blue)),
                ],
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, 
              height: 55, 
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
                onPressed: _saveData,
                child: const Text("SAVE TIRE DATA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            )
          ],
        ),
      ),
    );
  }

  void _saveData() async {
    if (snController.text.isEmpty) return;
    var docRef = await FirebaseFirestore.instance.collection('tyre_repairs').add({
      'sn': snController.text.toUpperCase(),
      'size': selectedSize,
      'repair_type': selectedPath,
      'vendor': selectedPath == 'External' ? selectedVendor : 'Internal',
      'status': selectedPath == 'External' ? 'WS (CHPP)' : 'WS',
      'location': 'CHPP',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Simpan history awal
    await docRef.collection('history').add({
      'status': selectedPath == 'External' ? 'WS (CHPP)' : 'WS',
      'location': 'CHPP',
      'updated_at': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }
}