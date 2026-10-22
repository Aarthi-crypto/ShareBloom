import 'package:flutter/material.dart';
import 'package:share_bloom/data/dummy_data.dart';
import 'package:share_bloom/models/user_model.dart';

class DashboardScreen extends StatelessWidget {
  final UserModel user;
  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final totalResources = DummyData.resources.length;
    final totalNeeds = DummyData.needs.length;
    final totalUsers = DummyData.users.length;

    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      children: [
        _stat("Total Users", totalUsers.toString(), Icons.people_rounded),
        _stat("Resources Shared", totalResources.toString(),
            Icons.inventory_2_rounded),
        _stat("Needs Posted", totalNeeds.toString(), Icons.edit_note_rounded),
      ],
    );
  }

  Widget _stat(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withOpacity(0.85),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 38),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}