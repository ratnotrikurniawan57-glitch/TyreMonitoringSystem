// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUserScreen extends StatefulWidget {
  const ManageUserScreen({super.key});

  @override
  State<ManageUserScreen> createState() => _ManageUserScreenState();
}

class _ManageUserScreenState extends State<ManageUserScreen> {
  final TextEditingController _nrpController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  String _selectedRole = 'tyreman';
  bool _isLoading = false;

  // --- FUNGSI SIMPAN USER BARU ---
  Future<void> _saveUser() async {
    if (_nrpController.text.isEmpty ||
        _namaController.text.isEmpty ||
        _passController.text.isEmpty) {
      _showMsg("Lengkapi semua data, Bos!", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      String nrp = _nrpController.text.trim().toLowerCase();
      await FirebaseFirestore.instance.collection('users').doc(nrp).set({
        'nrp': nrp,
        'nama': _namaController.text.trim().toLowerCase(),
        'password': _passController.text.trim(),
        'role': _selectedRole,
      });

      _nrpController.clear();
      _namaController.clear();
      _passController.clear();
      _showMsg("✅ User berhasil didaftarkan!", Colors.green);
    } catch (e) {
      _showMsg("❌ Gagal simpan: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI RESET PASSWORD ---
  void _resetPassword(String nrp) {
    final newPass = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("Reset Pass: $nrp"),
        content: TextField(
          controller: newPass,
          decoration: const InputDecoration(
              labelText: "Password Baru", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("BATAL")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(nrp)
                  .update({'password': newPass.text.trim()});
              Navigator.pop(c);
              _showMsg("✅ Password $nrp berhasil diupdate!", Colors.blue);
            },
            child: const Text("UPDATE"),
          )
        ],
      ),
    );
  }

  // --- FUNGSI HAPUS USER ---
  void _deleteUser(String nrp) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Hapus User?"),
        content: Text("Yakin mau hapus $nrp dari sistem?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("BATAL")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(nrp)
                  .delete();
              Navigator.pop(c);
              _showMsg("🗑️ User $nrp dihapus", Colors.red);
            },
            child: const Text("HAPUS", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  void _showMsg(String msg, Color col) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: col));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KELOLA USER"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- BAGIAN ATAS: FORM INPUT ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                          controller: _nrpController,
                          decoration: const InputDecoration(
                              labelText: "NRP",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge))),
                      const SizedBox(height: 12),
                      TextField(
                          controller: _namaController,
                          decoration: const InputDecoration(
                              labelText: "Nama Lengkap",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person))),
                      const SizedBox(height: 12),
                      TextField(
                          controller: _passController,
                          decoration: const InputDecoration(
                              labelText: "Password",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock))),
                      const SizedBox(height: 15),
                      const Text("Pilih Role:",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Tyreman"),
                        value: 'tyreman',
                        groupValue: _selectedRole,
                        onChanged: (v) => setState(() => _selectedRole = v!),
                      ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Admin"),
                        value: 'admin',
                        groupValue: _selectedRole,
                        onChanged: (v) => setState(() => _selectedRole = v!),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade900,
                              foregroundColor: Colors.white),
                          onPressed: _isLoading ? null : _saveUser,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text("DAFTARKAN USER"),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            const Divider(thickness: 2),
            const Text("DAFTAR USER TERDAFTAR",
                style: TextStyle(fontWeight: FontWeight.bold)),

            // --- BAGIAN BAWAH: LIST USER ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('nrp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator()));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var user = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;
                    String nrp = user['nrp'] ?? '-';
                    return ListTile(
                      leading: CircleAvatar(
                          child: Text(user['role'] != null
                              ? user['role'][0].toUpperCase()
                              : "U")),
                      title: Text(user['nama'].toString().toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("NRP: $nrp | Role: ${user['role']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.vpn_key,
                                  color: Colors.orange),
                              onPressed: () => _resetPassword(nrp)),
                          IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(nrp)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
