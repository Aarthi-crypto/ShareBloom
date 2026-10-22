import 'package:flutter/material.dart';
import 'package:share_bloom/models/user_model.dart';
import 'package:share_bloom/theme/app_theme.dart';

class PublicProfileScreen extends StatelessWidget {
  final UserModel user;

  const PublicProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: const Text("User Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${user.name}",
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            Text("Email: ${user.email}",
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            Text("Phone: ${user.phone}",
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            Text("City: ${user.city}",
                style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}