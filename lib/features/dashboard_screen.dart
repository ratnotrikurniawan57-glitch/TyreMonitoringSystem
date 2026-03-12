// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import Screen & Tabs
import '../auth/login_screen.dart' as auth; // Kita beri nama alias 'auth' agar tidak bentrok
import '../tabs/admin_tab.dart';
import '../tabs/tyreman_tab.dart';
import '../tabs/history_tab.dart';
import '../tabs/performance_tab.dart';
import '../tabs/tyre_repair_tracker.dart'; 

class DashboardScreen extends StatefulWidget {
  final String nrpAktif;
  final String role;

  const DashboardScreen({
    super.key,
    required this.nrpAktif,
    required this.role,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String _namaUser = "..."; 

  bool get isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    _ambilNamaUser(); 
  }

  void _ambilNamaUser() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.nrpAktif)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _namaUser = doc.data()?['nama'] ?? widget.nrpAktif;
        });
      }
    } catch (e) {
      debugPrint("Error ambil nama: $e");
    }
  }

  void _showChangePasswordDialog() {
    final TextEditingController newPassController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ganti Password"),
        content: TextField(
          controller: newPassController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: "Masukkan password baru",
            labelText: "Password Baru",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (newPassController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.nrpAktif)
                    .update({'password': newPassController.text});
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password berhasil diperbarui!")),
                  );
                }
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- DAFTAR HALAMAN ---
    final List<Widget> pages = [
      const PerformanceTab(),      
      const TyremanTab(),         
      TyreRepairTracker(role: widget.role), // Mengirim role ke halaman repair
      const HistoryTab(),         
      if (isAdmin) const AdminTab(), 
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("TMS | $_namaUser", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_reset),
            onPressed: _showChangePasswordDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear(); 
              navigator.pushReplacement(
                MaterialPageRoute(builder: (context) => const auth.LoginScreen()), // Pakai alias 'auth'
              );
            },
          )
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
          const BottomNavigationBarItem(icon: Icon(Icons.edit_document), label: "Input"),
          const BottomNavigationBarItem(icon: Icon(Icons.build_circle), label: "Repair"), 
          const BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          if (isAdmin)
            const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin"),
        ],
      ),
    );
  }
}