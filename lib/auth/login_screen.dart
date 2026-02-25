import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tyre_ms/features/dashboard_screen.dart';

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
    // 2. Sesuai aturan: NRP diubah ke lowercase sebelum dicek ke Firebase
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
      // Mencari dokumen berdasarkan ID NRP (String)
      var userDoc =
          await FirebaseFirestore.instance.collection('users').doc(nrp).get();

      if (userDoc.exists) {
        String dbPassword = userDoc.data()?['password'] ?? '';
        // 3. Sesuai instruksi: Default role adalah tyreman (bukan mekanik)
        String userRole = userDoc.data()?['role'] ?? 'tyreman';

        if (dbPassword == password) {
          if (!mounted) return;

          // LOGIN BERHASIL: Navigator sekarang mengenali DashboardScreen dari import di atas
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
              // Logo TMS
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
                // Diubah ke text karena ID Firebase kita lowercase string
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: "NRP (Contoh: 01121174)",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                      color: const Color(0xFFFF8C00),
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Lupa Password
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

              // Tombol Login
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : prosesLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("LOGIN",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 50),

              // Slogan Bawah
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      "Utamakan Keselamatan, Tingkatkan Performamu,",
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Jaga Unit Tetap Beroperasi",
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
