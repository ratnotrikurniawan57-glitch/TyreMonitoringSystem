import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../tabs/admin_tab.dart';
import '../tabs/tyreman_tab.dart';
import '../tabs/history_tab.dart';
import '../tabs/stats_tab.dart';

class DashboardScreen extends StatelessWidget {
  final String nrpAktif;
  final String role;

  const DashboardScreen({
    super.key,
    required this.nrpAktif,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  @override
  Widget build(BuildContext context) {
    // Admin dapat 4 Tab, Tyreman biasa dapat 3 Tab
    int tabLength = isAdmin ? 4 : 3;

    return DefaultTabController(
      length: tabLength,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("TMS DASHBOARD",
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueGrey.shade900,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const LoginScreen())),
            )
          ],
          bottom: TabBar(
            isScrollable: false,
            tabs: [
              const Tab(icon: Icon(Icons.bar_chart), text: "Stats"),
              const Tab(icon: Icon(Icons.edit_document), text: "Input"),
              const Tab(icon: Icon(Icons.history), text: "History"),
              if (isAdmin)
                const Tab(
                    icon: Icon(Icons.admin_panel_settings), text: "Admin"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const StatsTab(), // <--- SEKARANG SUDAH MEMANGGIL FILE STATS
            const TyremanTab(),
            const HistoryTab(),
            if (isAdmin) const AdminTab(),
          ],
        ),
      ),
    );
  }
}
