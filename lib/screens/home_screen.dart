import 'package:flutter/material.dart';
import 'package:share_bloom/theme/app_theme.dart';
import 'package:share_bloom/models/resource_item.dart';
import 'package:share_bloom/models/user_model.dart';
import 'package:share_bloom/screens/resource_detail_screen.dart';
import 'package:share_bloom/services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestore = FirestoreService();

  /// 🔄 Pull to refresh
  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final userCity = widget.user.city.trim().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1B),
      body: SafeArea(
        child: Column(
          children: [

            /// HEADER
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary,
                    AppTheme.secondary,
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.waving_hand, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Hi, ${widget.user.name}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// TITLE
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Resources in Your City",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// RESOURCE LIST
            Expanded(
              child: StreamBuilder<List<ResourceItem>>(
                stream: _firestore.getResources(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final resources = snapshot.data!
                      .where((r) =>
                  r.city.trim().toLowerCase() == userCity)
                      .toList();

                  if (resources.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        children: const [
                          SizedBox(height: 250),
                          Center(
                            child: Text(
                              "No resources in your city yet.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: resources.length,
                      itemBuilder: (context, index) {
                        return buildResourceCard(
                          context,
                          resources[index],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildResourceCard(BuildContext context, ResourceItem resource) {

    Color statusColor;

    switch (resource.status) {
      case "Available":
        statusColor = Colors.green;
        break;
      case "Pending":
        statusColor = Colors.orange;
        break;
      case "Accepted":
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      color: const Color(0xFF1F1F35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(
          Icons.inventory_2,
          color: Colors.white,
        ),
        title: Text(
          resource.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Qty: ${resource.qty}",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              resource.city,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                resource.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResourceDetailScreen(
                resourceId: resource.id,
                currentUser: widget.user,
              ),
            ),
          );
        },
      ),
    );
  }
}