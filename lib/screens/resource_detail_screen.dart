import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_bloom/models/resource_item.dart';
import 'package:share_bloom/models/user_model.dart';
import 'package:share_bloom/services/firestore_service.dart';
import 'package:share_bloom/services/location_service.dart';
import 'package:share_bloom/theme/app_theme.dart';
import 'package:share_bloom/screens/profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourceDetailScreen extends StatefulWidget {
  final String resourceId;
  final UserModel currentUser;

  const ResourceDetailScreen({
    super.key,
    required this.resourceId,
    required this.currentUser,
  });

  @override
  State<ResourceDetailScreen> createState() =>
      _ResourceDetailScreenState();
}

class _ResourceDetailScreenState
    extends State<ResourceDetailScreen> {

  final FirestoreService _firestore =
  FirestoreService();

  double? distanceKm;

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

  Future<void> _openMaps(
      double lat, double lng) async {

    final Uri url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng");

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _calculateDistance(
      double lat, double lng) async {

    final pos =
    await LocationService.getCurrentLocation();

    if (pos == null) return;

    final d = LocationService.distanceKm(
        pos.latitude,
        pos.longitude,
        lat,
        lng);

    setState(() {
      distanceKm = d;
    });
  }

  Future<void> _callUser(String phone) async {
    final Uri phoneUri =
    Uri.parse("tel:$phone");

    await launchUrl(phoneUri);
  }

  void _openProfile(ResourceItem item) {

    final profileUser = UserModel(
      uid: item.sharedByUid,
      name: item.sharedBy,
      email: item.sharedByEmail,
      phone: item.sharedByPhone,
      city: item.city,
      role: "sender",
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          profileUser: profileUser,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  Future<void> markCompleted(String id) async {

    await FirebaseFirestore.instance
        .collection("resources")
        .doc(id)
        .update({
      "status": "Completed",
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Resource marked as completed"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<ResourceItem>(
        stream: _firestore.getResourceById(
            widget.resourceId),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final item = snapshot.data!;

          if (distanceKm == null &&
              item.latitude != 0 &&
              item.longitude != 0) {
            _calculateDistance(
                item.latitude, item.longitude);
          }

          final statusColor =
          getStatusColor(item.status);

          final bool isSender =
              widget.currentUser.uid ==
                  item.sharedByUid;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFF1F1F35),
                    borderRadius:
                    BorderRadius.circular(
                        20),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [

                          Expanded(
                            child: Text(
                              item.title,
                              style:
                              const TextStyle(
                                fontSize: 22,
                                fontWeight:
                                FontWeight
                                    .bold,
                                color: Colors
                                    .white,
                              ),
                            ),
                          ),

                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                                horizontal:
                                12,
                                vertical:
                                6),
                            decoration:
                            BoxDecoration(
                              color: statusColor
                                  .withOpacity(
                                  0.2),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                  20),
                            ),
                            child: Text(
                              item.status,
                              style:
                              TextStyle(
                                color:
                                statusColor,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 10),

                      Text(
                        "${item.condition} • Qty: ${item.qty}",
                        style: const TextStyle(
                            color:
                            Colors.white70),
                      ),

                      const SizedBox(
                          height: 8),

                      Text(
                        "City: ${item.city}",
                        style: const TextStyle(
                            color:
                            Colors.white70),
                      ),

                      if (distanceKm != null)
                        Text(
                          "Distance: ${distanceKm!.toStringAsFixed(2)} km away",
                          style: const TextStyle(
                              color: Colors
                                  .white70),
                        ),

                      const SizedBox(
                          height: 16),

                      const Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                          color: Colors
                              .white,
                        ),
                      ),

                      const SizedBox(
                          height: 6),

                      Text(
                        item.description
                            .isEmpty
                            ? "No description provided."
                            : item.description,
                        style: const TextStyle(
                            color:
                            Colors.white70),
                      ),

                      const SizedBox(
                          height: 20),

                      const Text(
                        "Pickup Location",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                          color: Colors
                              .white,
                        ),
                      ),

                      const SizedBox(
                          height: 6),

                      Text(
                        item.address,
                        style: const TextStyle(
                            color:
                            Colors.white70),
                      ),

                      if (item.landmark
                          .isNotEmpty)
                        Text(
                          "Landmark: ${item.landmark}",
                          style:
                          const TextStyle(
                              color: Colors
                                  .white70),
                        ),

                      const SizedBox(
                          height: 20),

                      GestureDetector(
                        onTap: () =>
                            _openProfile(
                                item),
                        child: const Text(
                          "View Sender Profile",
                          style: TextStyle(
                            color:
                            Colors.white70,
                            decoration:
                            TextDecoration
                                .underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  style:
                  ElevatedButton
                      .styleFrom(
                    backgroundColor:
                    AppTheme.primary,
                    minimumSize:
                    const Size
                        .fromHeight(50),
                  ),
                  onPressed: () =>
                      _callUser(
                          item.sharedByPhone),
                  child: const Text("Call"),
                ),

                const SizedBox(height: 14),

                ElevatedButton(
                  style:
                  ElevatedButton
                      .styleFrom(
                    backgroundColor:
                    AppTheme.secondary,
                    minimumSize:
                    const Size
                        .fromHeight(50),
                  ),
                  onPressed: () =>
                      _openMaps(
                          item.latitude,
                          item.longitude),
                  child: const Text(
                      "Open in Maps"),
                ),

                /// only sender can complete
                if (item.status ==
                    "Accepted" &&
                    isSender)
                  Padding(
                    padding:
                    const EdgeInsets
                        .only(top: 14),
                    child:
                    ElevatedButton(
                      style:
                      ElevatedButton
                          .styleFrom(
                        backgroundColor:
                        Colors.blue,
                        minimumSize:
                        const Size
                            .fromHeight(
                            50),
                      ),
                      onPressed: () =>
                          markCompleted(
                              item.id),
                      child: const Text(
                          "Mark as Completed"),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}