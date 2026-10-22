import 'package:flutter/material.dart';
import 'package:share_bloom/theme/app_theme.dart';
import 'package:share_bloom/widgets/hover_tile.dart';

class Sidebar extends StatelessWidget {
  final String name;
  final String role;
  final String city;
  final int selectedIndex;
  final bool collapsed;
  final Function(int) onSelect;
  final VoidCallback onLogout;

  const Sidebar({
    super.key,
    required this.name,
    required this.role,
    required this.city,
    required this.selectedIndex,
    required this.collapsed,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final width = collapsed ? 88.0 : 280.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 40,
            offset: Offset(0, 18),
            color: Color.fromRGBO(0, 0, 0, 0.12),
          ),
        ],
      ),
      child: Column(
        children: [
          // user box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isEmpty ? "SB" : name.substring(0, 2).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${role.toUpperCase()} • $city",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.muted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),

          const SizedBox(height: 14),

          Expanded(
            child: ListView(
              children: [
                _sideItem(Icons.home_rounded, "Home", 0),
                _sideItem(Icons.dashboard_rounded, "Dashboard", 1),

                if (role == "receiver") ...[
                  _sideItem(Icons.inventory_2_rounded, "Available", 2),
                  _sideItem(Icons.edit_note_rounded, "Post Needs", 3),
                  _sideItem(Icons.assignment_rounded, "My Requests", 4),
                  _sideItem(Icons.notifications_rounded, "Notifications", 5),
                ] else ...[
                  _sideItem(Icons.inventory_2_rounded, "Available", 2),
                  _sideItem(Icons.volunteer_activism_rounded, "Share Item", 3),
                  _sideItem(Icons.assignment_rounded, "Receiver Requests", 4),
                  _sideItem(Icons.notifications_rounded, "Notifications", 5),
                ],

                _sideItem(Icons.person_rounded, "Profile", 6),
                _sideItem(Icons.settings_rounded, "Settings", 7),

                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 6),

                HoverTile(
                  active: false,
                  onTap: onLogout,
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, color: Colors.red),
                      if (!collapsed) ...[
                        const SizedBox(width: 12),
                        const Text(
                          "Logout",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.red,
                          ),
                        )
                      ],
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideItem(IconData icon, String text, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HoverTile(
        active: selectedIndex == index,
        onTap: () => onSelect(index),
        child: Row(
          children: [
            Icon(icon),
            if (!collapsed) ...[
              const SizedBox(width: 12),
              Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ],
        ),
      ),
    );
  }
}