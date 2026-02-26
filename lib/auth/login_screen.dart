import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nrpController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  bool _isLoading = false;
  bool _isObscure = true;

  void prosesLogin() async {
    String nrp = nrpController.text.trim().toLowerCase();
    String password = passController.text.trim();

    if (nrp.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("NRP dan Password wajib diisi!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var userDoc =
          await FirebaseFirestore.instance.collection('users').doc(nrp).get();

      if (userDoc.exists) {
        String dbPassword = userDoc.data()?['password'] ?? '';
        String userRole = userDoc.data()?['role'] ?? 'tyreman';

        if (dbPassword == password) {
          // GUARD: Cek apakah widget masih nempel di layar sebelum pindah halaman
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                nrpAktif: nrp,
                role: userRole,
              ),
            ),
          );
        } else {
          throw "Password salah, Brow!";
        }
      } else {
        throw "NRP $nrp tidak terdaftar!";
      }
    } catch (e) {
      // GUARD: Cek apakah widget masih nempel sebelum munculin snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // BALIKIN LOGO BAN ORANYE LO
              Image.asset(
                'assets/images/logo_tms.png',
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported,
                      size: 100, color: Colors.grey);
                },
              ),
              const SizedBox(height: 10),
              const Text(
                '- Safety First, Boost Your Performance, Keep Unit Running -',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Input NRP
              TextField(
                controller: nrpController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: "NRP (Contoh: 01121174)",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),

              // Input Password
              TextField(
                controller: passController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _isObscure ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFFFF8C00)),
                    onPressed: () => setState(() => _isObscure = !_isObscure),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),

              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Jika lupa password silakan hubungi admin",
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 25),

              // TOMBOL LOGIN ORANYE
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : prosesLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("LOGIN",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),

              const SizedBox(height: 40), // Jarak ke footer identitas

              // --- IDENTITAS APLIKASI (TMS) ---
              const Text(
                "TMS",
                style: TextStyle(
                    fontSize: 24,
                    // FontWeight.black DIGANTI JADI FontWeight.w900
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF8C00),
                    letterSpacing: 3),
              ),
              const Text(
                "- Tyre Monitoring System -",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                    fontStyle: FontStyle.italic),
              ),

              const SizedBox(height: 8),

              // --- VERSI TETAP ADA ---
              const Text(
                "Version 1.0.0",
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
