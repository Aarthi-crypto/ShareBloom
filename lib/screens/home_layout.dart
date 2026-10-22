import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:share_bloom/models/user_model.dart';
import 'package:share_bloom/theme/app_theme.dart';

import 'package:share_bloom/screens/home_screen.dart';
import 'package:share_bloom/screens/my_needs_screen.dart';
import 'package:share_bloom/screens/share_item_screen.dart';
import 'package:share_bloom/screens/notifications_screen.dart';
import 'package:share_bloom/screens/available_resources_screen.dart';
import 'package:share_bloom/screens/profile_screen.dart';
import 'package:share_bloom/screens/login_screen.dart';

class HomeLayout extends StatefulWidget {
  final UserModel currentUser;

  const HomeLayout({
    super.key,
    required this.currentUser,
  });

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout>
    with SingleTickerProviderStateMixin {

  int selectedIndex = 0;

  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// NEW: realtime listener for instant badge update
  StreamSubscription? notificationListener;

  @override
  void initState() {
    super.initState();

    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _drawerAnimation = CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    );

    /// Save device token
    _saveDeviceToken();

    /// 🔔 instant badge update listener
    _listenNotificationChanges();

    FirebaseMessaging.onMessage.listen((message) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.notification?.title ?? "New Notification",
          ),
        ),
      );
    });
  }

  void _listenNotificationChanges() {
    notificationListener = _db
        .collection("notifications")
        .where("forUser", isEqualTo: widget.currentUser.email)
        .snapshots()
        .listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _saveDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();

      if (token == null) return;

      await _db
          .collection("users")
          .doc(widget.currentUser.uid)
          .update({
        "fcmToken": token,
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    notificationListener?.cancel();
    _drawerController.dispose();
    super.dispose();
  }

  Stream<int> getNotificationCount() {
    if (widget.currentUser.email.isEmpty) {
      return const Stream.empty();
    }

    return _db
        .collection("notifications")
        .where("forUser", isEqualTo: widget.currentUser.email)
        .where("read", isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> logout() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {

    final bool isReceiver =
        widget.currentUser.role.toLowerCase() == "receiver";

    final List<Widget> pages = [
      HomeScreen(user: widget.currentUser),
      isReceiver
          ? MyNeedsScreen(user: widget.currentUser)
          : ShareItemScreen(user: widget.currentUser),
      NotificationsScreen(user: widget.currentUser),
      AvailableResourcesScreen(user: widget.currentUser),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.65,
        child: Drawer(
          backgroundColor: const Color(0xFF1A1A2E),
          child: SafeArea(
            child: FadeTransition(
              opacity: _drawerAnimation,
              child: ProfileScreen(
                profileUser: widget.currentUser,
                currentUser: widget.currentUser,
              ),
            ),
          ),
        ),
      ),

      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _drawerController.forward();
        } else {
          _drawerController.reverse();
        }
      },

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () {
          setState(() {
            selectedIndex = 1;
          });
        },
        child: Icon(
          isReceiver ? Icons.list_alt : Icons.add,
        ),
      ),

      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildNavItem(Icons.home, 0),
              buildNotificationIcon(),
              const SizedBox(width: 40),
              buildNavItem(Icons.inventory_2_outlined, 3),
              buildSettingsIcon(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildNavItem(IconData icon, int index) {

    final isSelected = selectedIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? AppTheme.primary
              : Colors.transparent,
        ),
        child: Icon(
          icon,
          color: isSelected
              ? Colors.white
              : Colors.grey,
        ),
      ),
    );
  }

  Widget buildNotificationIcon() {

    final isSelected = selectedIndex == 2;

    return StreamBuilder<int>(
      stream: getNotificationCount(),
      builder: (context, snapshot) {

        final count = snapshot.data ?? 0;

        return InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            setState(() {
              selectedIndex = 2;
            });
          },
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppTheme.primary
                      : Colors.transparent,
                ),
                child: Icon(
                  Icons.notifications,
                  color: isSelected
                      ? Colors.white
                      : Colors.grey,
                ),
              ),
              if (count > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count > 99 ? "99+" : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget buildSettingsIcon() {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Logout"),
            content: const Text(
                "Are you sure you want to logout?"),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  logout();
                },
                child: const Text("Logout"),
              ),
            ],
          ),
        );
      },
      child: const Icon(
        Icons.settings,
        color: Colors.grey,
      ),
    );
  }
}