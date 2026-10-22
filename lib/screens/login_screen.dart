import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_bloom/screens/home_layout.dart';
import 'package:share_bloom/screens/register_screen.dart';
import 'package:share_bloom/models/user_model.dart';
import 'package:share_bloom/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn =
  GoogleSignIn();
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  bool loading = false;
  bool showPass = false;

  @override
  void initState() {
    super.initState();
    _initPush();
  }

  Future<void> _initPush() async {
    await FirebaseMessaging.instance
        .requestPermission();
  }

  Future<void> login() async {

    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (email.isEmpty ||
        pass.isEmpty) {
      _msg("Enter email & password");
      return;
    }

    try {
      setState(() => loading = true);

      final cred =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      await _loadUserAndNavigate(cred.user!);

    } on FirebaseAuthException catch (e) {
      _msg(e.message ?? "Login failed");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> googleLogin() async {
    try {

      final googleUser =
      await _googleSignIn.signIn();

      if (googleUser == null) return;

      final googleAuth =
      await googleUser.authentication;

      final credential =
      GoogleAuthProvider.credential(
        accessToken:
        googleAuth.accessToken,
        idToken:
        googleAuth.idToken,
      );

      final userCred =
      await _auth.signInWithCredential(
          credential);

      await _loadUserAndNavigate(
          userCred.user!);

    } catch (_) {
      _msg("Google login failed");
    }
  }

  Future<void> _loadUserAndNavigate(
      User firebaseUser) async {

    final docRef =
    _db.collection("users")
        .doc(firebaseUser.uid);

    final doc = await docRef.get();

    /// 🔥 If user doc does not exist → create minimal profile
    if (!doc.exists) {
      await docRef.set({
        "uid": firebaseUser.uid,
        "name":
        firebaseUser.displayName ??
            "User",
        "email":
        firebaseUser.email,
        "phone":
        firebaseUser.phoneNumber ??
            "",
        "city": "",
        "role": "receiver",

        // 🔥 New fields default
        "address": "",
        "landmark": "",
        "latitude": 0.0,
        "longitude": 0.0,

        "createdAt":
        FieldValue.serverTimestamp(),
      });
    }

    final updatedDoc =
    await docRef.get();

    final userModel =
    UserModel.fromMap(
        updatedDoc.data()!);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeLayout(
            currentUser: userModel),
      ),
    );
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
        AppTheme.primary,
        content: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
      const Color(0xFF141428),
      body: Center(
        child: Container(
          width: 420,
          padding:
          const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color:
            const Color(0xFF1F1F35),
            borderRadius:
            BorderRadius.circular(
                20),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,
              children: [

                const Text(
                  "Login",
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                _field(emailCtrl, "Email",
                    keyboard:
                    TextInputType
                        .emailAddress),

                const SizedBox(height: 14),

                TextField(
                  controller: passCtrl,
                  obscureText: !showPass,
                  cursorColor:
                  Colors.white,
                  style:
                  const TextStyle(
                      color:
                      Colors.white),
                  decoration:
                  _inputDecoration(
                      "Password")
                      .copyWith(
                    suffixIcon:
                    IconButton(
                      icon: Icon(
                        showPass
                            ? Icons
                            .visibility_off
                            : Icons
                            .visibility,
                        color:
                        Colors.white70,
                      ),
                      onPressed: () =>
                          setState(() =>
                          showPass =
                          !showPass),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                    loading
                        ? null
                        : login,
                    child: loading
                        ? const CircularProgressIndicator(
                      color:
                      Colors
                          .white,
                    )
                        : const Text(
                      "Login",
                      style: TextStyle(
                          fontWeight:
                          FontWeight
                              .bold),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "New user? Register here",
                    style: TextStyle(
                        color:
                        Colors.white70),
                  ),
                ),

                const SizedBox(height: 20),

                const Divider(
                    color: Colors.white24),

                const SizedBox(height: 18),

                SizedBox(
                  height: 50,
                  child:
                  OutlinedButton.icon(
                    onPressed:
                    googleLogin,
                    style:
                    OutlinedButton
                        .styleFrom(
                      side: const BorderSide(
                          color:
                          Colors
                              .white30),
                      foregroundColor:
                      Colors.white,
                    ),
                    icon: const Icon(
                      Icons.login,
                      color:
                      Colors.white,
                    ),
                    label: const Text(
                        "Continue with Google"),
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
      decoration:
      _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(
      String label) {
    return InputDecoration(
      labelText: label,
      labelStyle:
      const TextStyle(
          color:
          Colors.white70),
      floatingLabelStyle:
      const TextStyle(
          color:
          Colors.white),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(16),
        borderSide:
        const BorderSide(
            color:
            Colors.white24),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(16),
        borderSide:
        const BorderSide(
            color:
            Colors.white),
      ),
    );
  }
}