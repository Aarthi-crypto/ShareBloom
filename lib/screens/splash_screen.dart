import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_bloom/screens/login_screen.dart';
import 'package:share_bloom/screens/home_layout.dart';
import 'package:share_bloom/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_bloom/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {

    await Future.delayed(const Duration(seconds: 2));

    try {

      final user = _auth.currentUser;

      if (!mounted) return;

      /// USER ALREADY LOGGED IN
      if (user != null) {

        final doc =
        await _db.collection("users").doc(user.uid).get();

        /// CHECK IF USER DOCUMENT EXISTS
        if (doc.exists && doc.data() != null) {

          final userModel =
          UserModel.fromMap(doc.data()!);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeLayout(
                currentUser: userModel,
              ),
            ),
          );

        } else {

          /// DOCUMENT MISSING → FORCE LOGIN AGAIN
          await _auth.signOut();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
          );

        }

      } else {

        /// USER NOT LOGGED IN
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );

      }

    } catch (e) {

      /// 🔴 If Firestore fails, avoid crash
      debugPrint("Splash error: $e");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/bg1.jpg", fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.45)),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white.withOpacity(0.12),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Image.asset("assets/logo.jpg", fit: BoxFit.cover),
                ),
                const SizedBox(height: 18),
                const Text(
                  "ShareBloom",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Sharing made meaningful",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: 210,
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(50),
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}