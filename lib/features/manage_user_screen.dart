// ignore_for_file: use_build_context_synchronously, deprecated_member_use

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
        'createdAt': FieldValue.serverTimestamp(), // Tambahan biar rapi di DB
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Reset Password: $nrp"),
        content: TextField(
          controller: newPass,
          decoration: const InputDecoration(
              labelText: "Password Baru", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("BATAL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              if (newPass.text.isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(nrp)
                  .update({'password': newPass.text.trim()});
              Navigator.pop(c);
              _showMsg("✅ Password $nrp berhasil diupdate!", Colors.blue);
            },
            child: const Text("UPDATE", style: TextStyle(color: Colors.white)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: col, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KELOLA USER TMS"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- FORM INPUT ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Registrasi User Baru", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
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
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: "Password",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock))),
                      const SizedBox(height: 15),
                      const Text("Pilih Role:", style: TextStyle(fontWeight: FontWeight.bold)),
                      // Gaya RadioListTile yang aman dari warning
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
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: _isLoading ? null : _saveUser,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("DAFTARKAN USER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Divider(thickness: 2)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("DATABASE USER", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  Expanded(child: Divider(thickness: 2)),
                ],
              ),
            ),

            // --- LIST USER ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('nrp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(padding: EdgeInsets.all(20), child: Text("Belum ada user terdaftar."));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var user = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    String nrp = user['nrp'] ?? '-';
                    String role = user['role'] ?? 'user';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor: role == 'admin' ? Colors.red.shade100 : Colors.blue.shade100,
                            child: Text(role[0].toUpperCase(), style: TextStyle(color: role == 'admin' ? Colors.red : Colors.blue))),
                        title: Text(user['nama'].toString().toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("NRP: $nrp | Role: $role"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.vpn_key_rounded, color: Colors.orange),
                                onPressed: () => _resetPassword(nrp)),
                            IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                onPressed: () => _deleteUser(nrp)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}