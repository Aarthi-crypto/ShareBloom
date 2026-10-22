import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_bloom/models/user_model.dart';
import 'package:share_bloom/screens/home_layout.dart';
import 'package:share_bloom/theme/app_theme.dart';
import 'package:share_bloom/services/location_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final landmarkCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  String role = "receiver";
  bool showPass = false;
  bool loading = false;

  Future<void> register() async {

    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final city =
    cityCtrl.text.trim().toLowerCase();
    final address = addressCtrl.text.trim();
    final landmark = landmarkCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (name.isEmpty ||
        phone.isEmpty ||
        city.isEmpty ||
        address.isEmpty ||
        email.isEmpty ||
        pass.isEmpty) {
      _msg("Fill all required fields");
      return;
    }

    if (!email.contains("@")) {
      _msg("Enter valid email");
      return;
    }

    if (pass.length < 6) {
      _msg("Password must be at least 6 characters");
      return;
    }

    if (phone.length < 8) {
      _msg("Enter valid phone number");
      return;
    }

    setState(() => loading = true);

    try {

      /// 🔥 Build full address smartly
      final fullAddress = landmark.isEmpty
          ? "$address, $city"
          : "$address, $landmark, $city";

      final coords =
      await LocationService.getCoordinates(fullAddress);

      if (coords == null) {
        _msg("Could not detect location from address.");
        setState(() => loading = false);
        return;
      }

      final latitude = coords["lat"]!;
      final longitude = coords["lng"]!;

      final credential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = credential.user!;

      final userModel = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        phone: phone,
        city: city,
        role: role,
        address: address,
        landmark: landmark,
        latitude: latitude,
        longitude: longitude,
      );

      await _db
          .collection("users")
          .doc(user.uid)
          .set(userModel.toMap());

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeLayout(
            currentUser: userModel,
          ),
        ),
      );

    } on FirebaseAuthException catch (e) {
      _msg(e.message ?? "Registration failed");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primary,
        content: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF141428),
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F35),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [

                const Text(
                  "Register",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                _field(nameCtrl, "Name"),
                const SizedBox(height: 14),

                _field(phoneCtrl, "Phone",
                    keyboard: TextInputType.phone),
                const SizedBox(height: 14),

                _field(cityCtrl, "City"),
                const SizedBox(height: 14),

                _field(addressCtrl, "Full Address"),
                const SizedBox(height: 14),

                _field(landmarkCtrl,
                    "Landmark (Optional)"),
                const SizedBox(height: 14),

                DropdownButtonFormField(
                  value: role,
                  dropdownColor:
                  const Color(0xFF1F1F35),
                  style:
                  const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(
                        value: "receiver",
                        child: Text("Receiver")),
                    DropdownMenuItem(
                        value: "sender",
                        child: Text("Sender")),
                  ],
                  onChanged: (val) =>
                      setState(() => role = val!),
                  decoration: _inputDecoration("Role"),
                ),

                const SizedBox(height: 14),

                _field(emailCtrl, "Email",
                    keyboard:
                    TextInputType.emailAddress),
                const SizedBox(height: 14),

                TextField(
                  controller: passCtrl,
                  obscureText: !showPass,
                  cursorColor: Colors.white,
                  style:
                  const TextStyle(color: Colors.white),
                  decoration:
                  _inputDecoration("Password")
                      .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPass
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.white70,
                      ),
                      onPressed: () =>
                          setState(() =>
                          showPass = !showPass),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                    loading ? null : register,
                    child: loading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      "Register",
                      style: TextStyle(
                          fontWeight:
                          FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController ctrl,
      String label, {
        TextInputType keyboard =
            TextInputType.text,
      }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      cursorColor: Colors.white,
      style:
      const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle:
      const TextStyle(color: Colors.white70),
      floatingLabelStyle:
      const TextStyle(color: Colors.white),
      enabledBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(16),
        borderSide:
        const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(16),
        borderSide:
        const BorderSide(color: Colors.white),
      ),
    );
  }
}