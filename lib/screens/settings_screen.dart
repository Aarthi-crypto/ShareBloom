import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback toggleTheme;

  const SettingsScreen({Key? key, required this.toggleTheme})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                "Settings",
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  title: const Text("Dark Mode"),
                  trailing: Switch(
                    value: Theme.of(context).brightness ==
                        Brightness.dark,
                    onChanged: (_) => toggleTheme(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}