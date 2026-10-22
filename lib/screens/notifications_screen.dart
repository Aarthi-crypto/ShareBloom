import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_bloom/models/user_model.dart';
import 'package:share_bloom/theme/app_theme.dart';
import 'package:share_bloom/screens/profile_screen.dart';
import 'package:share_bloom/screens/resource_detail_screen.dart';
import 'package:share_bloom/screens/chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final UserModel user;

  const NotificationsScreen({
    super.key,
    required this.user,
  });

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {

  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {});
  }

  Stream<QuerySnapshot> getNotifications() {
    return _db
        .collection("notifications")
        .where("forUser", isEqualTo: widget.user.email)
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String id) async {
    await _db
        .collection("notifications")
        .doc(id)
        .update({"read": true});
  }

  Future<void> handleAction({
    required String notificationId,
    required String resourceId,
    required String needId,
    required String action,
  }) async {

    final resourceRef =
    _db.collection("resources").doc(resourceId);

    final needRef =
    _db.collection("needs").doc(needId);

    final resourceSnap = await resourceRef.get();
    final needSnap = await needRef.get();

    if (!resourceSnap.exists || !needSnap.exists) return;

    final resourceData =
    resourceSnap.data() as Map<String, dynamic>;

    final needData =
    needSnap.data() as Map<String, dynamic>;

    await _db.runTransaction((transaction) async {

      if (action == "Accepted") {

        transaction.update(resourceRef, {
          "status": "Accepted",
          "acceptedByEmail": widget.user.email,
        });

        transaction.update(needRef, {
          "status": "Accepted",
        });

        transaction.update(
            _db.collection("notifications").doc(notificationId), {
          "status": "Accepted",
          "read": true,
        });
      }

      if (action == "Rejected") {

        transaction.update(resourceRef, {
          "status": "Available",
          "matchedWithEmail": null,
          "matchedNeedId": null,
        });

        transaction.update(needRef, {
          "matchedResourceId": null,
        });

        transaction.update(
            _db.collection("notifications").doc(notificationId), {
          "status": "Rejected",
          "read": true,
        });
      }
    });

    /// 🔔 NOTIFICATIONS AFTER TRANSACTION

    if (action == "Accepted") {

      /// Sender confirmation
      await _db.collection("notifications").add({
        "forUser": resourceData["sharedByEmail"],
        "title": "Request Accepted",
        "body":
        "You accepted the request for your shared resource.",
        "resourceId": resourceId,
        "needId": needId,
        "type": "resource_update",
        "status": "Accepted",
        "read": false,
        "createdAt": FieldValue.serverTimestamp(),
      });

      /// Receiver notification
      await _db.collection("notifications").add({
        "forUser": needData["receiverEmail"],
        "title": "Resource Accepted",
        "body":
        "The sender accepted your request for the resource.",
        "resourceId": resourceId,
        "needId": needId,
        "type": "resource_update",
        "status": "Accepted",
        "read": false,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    if (action == "Rejected") {

      await _db.collection("notifications").add({
        "forUser": needData["receiverEmail"],
        "title": "Request Rejected",
        "body":
        "The sender rejected your request for the resource.",
        "resourceId": resourceId,
        "needId": needId,
        "type": "resource_update",
        "status": "Rejected",
        "read": false,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
        action == "Accepted" ? Colors.green : Colors.red,
        content: Text("Request $action"),
      ),
    );
  }

  void handleNavigation(Map<String, dynamic> data) {

    final type = data["type"] ?? "";

    if (type == "match_profile") {

      final otherUid = data["otherUid"];
      if (otherUid == null) return;

      final profileUser = UserModel(
        uid: otherUid,
        name: data["otherName"] ?? "",
        email: data["otherEmail"] ?? "",
        phone: data["otherPhone"] ?? "",
        city: data["otherCity"] ?? "",
        role: data["otherRole"] ?? "receiver",
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            profileUser: profileUser,
            currentUser: widget.user,
          ),
        ),
      );
      return;
    }

    if (type == "chat") {

      final otherUser = UserModel(
        uid: data["otherUid"] ?? "",
        name: data["otherName"] ?? "",
        email: data["otherEmail"] ?? "",
        phone: data["otherPhone"] ?? "",
        city: data["otherCity"] ?? "",
        role: data["otherRole"] ?? "sender",
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            currentUser: widget.user,
            otherUser: otherUser,
          ),
        ),
      );
      return;
    }

    if (type == "resource_update" &&
        data["resourceId"] != null) {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ResourceDetailScreen(
                resourceId: data["resourceId"],
                currentUser: widget.user,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1B),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: getNotifications(),
          builder: (context, snapshot) {

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  children: const [
                    SizedBox(height: 250),
                    Center(
                      child: Text(
                        "No notifications yet.",
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
                itemCount: docs.length,
                itemBuilder: (context, index) {

                  final doc = docs[index];

                  final data =
                  doc.data() as Map<String, dynamic>;

                  final status =
                      data["status"] ?? "Pending";

                  final isRead =
                      data["read"] ?? false;

                  return GestureDetector(
                    onTap: () {
                      markAsRead(doc.id);
                      handleNavigation(data);
                    },
                    child: AnimatedContainer(
                      duration:
                      const Duration(milliseconds: 200),
                      margin:
                      const EdgeInsets.only(bottom: 14),
                      padding:
                      const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isRead
                            ? const Color(0xFF1F1F35)
                            : const Color(0xFF2A2A45),
                        borderRadius:
                        BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary
                                .withOpacity(0.15),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [

                          Text(
                            data["title"] ?? "",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            data["body"] ?? "",
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (status == "Pending")
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        handleAction(
                                          notificationId:
                                          doc.id,
                                          resourceId:
                                          data["resourceId"],
                                          needId:
                                          data["needId"],
                                          action: "Accepted",
                                        ),
                                    child: const Text("Accept"),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton
                                        .styleFrom(
                                      backgroundColor:
                                      Colors.red,
                                    ),
                                    onPressed: () =>
                                        handleAction(
                                          notificationId:
                                          doc.id,
                                          resourceId:
                                          data["resourceId"],
                                          needId:
                                          data["needId"],
                                          action: "Rejected",
                                        ),
                                    child: const Text("Reject"),
                                  ),
                                ),
                              ],
                            )
                          else
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 12),
                              decoration: BoxDecoration(
                                color: status == "Accepted"
                                    ? Colors.green
                                    .withOpacity(0.2)
                                    : Colors.red
                                    .withOpacity(0.2),
                                borderRadius:
                                BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: status == "Accepted"
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
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