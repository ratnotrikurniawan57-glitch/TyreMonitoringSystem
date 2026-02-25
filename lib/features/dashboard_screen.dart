import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import '../tabs/admin_tab.dart';
import '../tabs/tyreman_tab.dart';
import '../tabs/history_tab.dart';
import '../tabs/performance_tab.dart';

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
  String _namaUser = "..."; // Placeholder saat loading

  bool get isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    _ambilNamaUser(); // Ambil nama dari Firestore saat layar dimuat
  }

  // --- FUNGSI AMBIL NAMA ---
  void _ambilNamaUser() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.nrpAktif)
          .get();

      if (doc.exists) {
        setState(() {
          _namaUser = doc.data()?['nama'] ?? widget.nrpAktif;
        });
      }
    } catch (e) {
      debugPrint("Error ambil nama: $e");
    }
  }

  // --- FUNGSI GANTI PASSWORD (MESIN YANG TADI HILANG) ---
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
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
                    const SnackBar(
                        content: Text("Password berhasil diperbarui!")),
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
    // List halaman sesuai Tab
    final List<Widget> pages = [
      const PerformanceTab(),
      const TyremanTab(),
      const HistoryTab(),
      if (isAdmin) const AdminTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "TMS | $_namaUser",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          // 1. IKON GANTI PASSWORD
          IconButton(
            icon: const Icon(Icons.lock_reset),
            tooltip: "Ganti Password",
            onPressed: _showChangePasswordDialog, // Sekarang pasti kenal!
          ),
          // 2. IKON LOGOUT
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Stats"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.edit_document), label: "Input"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.history), label: "History"),
          if (isAdmin)
            const BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings), label: "Admin"),
        ],
      ),
    );
  }
}
