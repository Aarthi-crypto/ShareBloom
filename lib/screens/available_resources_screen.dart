import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_bloom/models/user_model.dart';
import 'package:share_bloom/theme/app_theme.dart';

class AvailableResourcesScreen extends StatefulWidget {
  final UserModel user;

  const AvailableResourcesScreen({
    super.key,
    required this.user,
  });

  @override
  State<AvailableResourcesScreen> createState() =>
      _AvailableResourcesScreenState();
}

class _AvailableResourcesScreenState
    extends State<AvailableResourcesScreen> {

  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  Color getStatusColor(String status) {
    switch (status) {
      case "Accepted":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      case "Pending":
        return Colors.orange;
      case "Completed":
        return Colors.blue;
      default:
        return AppTheme.primary;
    }
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    final userCity =
    widget.user.city.trim().toLowerCase();

    final stream =
    _db.collection("resources").snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1B),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Text(
                  "Something went wrong.",
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            final filteredDocs = docs.where((doc) {

              final data =
              doc.data() as Map<String, dynamic>;

              final city =
              (data["city"] ?? "")
                  .toString()
                  .trim()
                  .toLowerCase();

              final status =
                  data["status"] ?? "Available";

              return city == userCity &&
                  (status == "Available" ||
                      status == "Pending");
            }).toList();

            if (filteredDocs.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  children: const [
                    SizedBox(height: 250),
                    Center(
                      child: Text(
                        "No resources available.",
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
                padding: const EdgeInsets.all(20),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {

                  final data =
                  filteredDocs[index].data()
                  as Map<String, dynamic>;

                  final title = data["title"] ?? "";
                  final qty = data["qty"] ?? 0;
                  final city = data["city"] ?? "";
                  final condition = data["condition"] ?? "";
                  final status =
                      data["status"] ?? "Available";

                  final statusColor =
                  getStatusColor(status);

                  return Container(
                    margin:
                    const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F35),
                      borderRadius:
                      BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor
                              .withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Qty: $qty",
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Condition: $condition",
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "City: $city",
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Align(
                          alignment:
                          Alignment.centerRight,
                          child: Container(
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor
                                  .withOpacity(0.2),
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}