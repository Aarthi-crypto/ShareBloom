import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_bloom/models/user_model.dart';
import 'package:share_bloom/screens/chat_screen.dart';
import 'package:share_bloom/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel profileUser;
  final UserModel currentUser;

  const ProfileScreen({
    super.key,
    required this.profileUser,
    required this.currentUser,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  File? _image;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool get isOwnProfile =>
      widget.currentUser.uid == widget.profileUser.uid;

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> pickImage() async {
    if (!isOwnProfile) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> callUser() async {
    if (widget.profileUser.phone.isEmpty) return;

    final Uri phoneUri =
    Uri.parse("tel:${widget.profileUser.phone}");

    await launchUrl(phoneUri);
  }

  Future<void> openMap() async {
    final address = widget.profileUser.address;
    final landmark = widget.profileUser.landmark;
    final city = widget.profileUser.city;

    if (address.isEmpty && city.isEmpty) return;

    String query;

    if (landmark.isNotEmpty) {
      query = "$address, $landmark, $city, India";
    } else {
      query = "$address, $city, India";
    }

    final Uri url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(
            query)}");

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  void copyAddress() {
    final fullAddress =
        "${widget.profileUser.address}, "
        "${widget.profileUser.landmark}, "
        "${widget.profileUser.city}";

    Clipboard.setData(ClipboardData(text: fullAddress));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Address copied")),
    );
  }

  Future<void> deleteResource(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Delete Resource"),
            content: const Text("Are you sure you want to delete this item?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel")),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Delete")),
            ],
          ),
    );

    if (confirm != true) return;

    await _db.collection("resources").doc(id).delete();
  }

  Future<void> deleteNeed(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Delete Need"),
            content: const Text("Are you sure you want to delete this need?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel")),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Delete")),
            ],
          ),
    );

    if (confirm != true) return;

    await _db.collection("needs").doc(id).delete();
  }

  /// EDIT RESOURCE
  Future<void> editResource(String id, Map<String, dynamic> data) async {
    final titleCtrl = TextEditingController(text: data["title"]);
    final conditionCtrl = TextEditingController(text: data["condition"]);
    final qtyCtrl = TextEditingController(text: data["qty"].toString());
    final descCtrl = TextEditingController(text: data["description"]);
    final addressCtrl = TextEditingController(text: data["address"]);
    final landmarkCtrl = TextEditingController(text: data["landmark"]);

    final save = await showDialog<bool>(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Edit Resource"),
            content: SingleChildScrollView(
              child: Column(
                children: [

                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: "Title"),
                  ),

                  TextField(
                    controller: conditionCtrl,
                    decoration: const InputDecoration(labelText: "Condition"),
                  ),

                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Quantity"),
                  ),

                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),

                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: "Address"),
                  ),

                  TextField(
                    controller: landmarkCtrl,
                    decoration: const InputDecoration(labelText: "Landmark"),
                  ),

                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel")),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Save")),
            ],
          ),
    );

    if (save != true) return;

    await _db.collection("resources").doc(id).update({
      "title": titleCtrl.text,
      "condition": conditionCtrl.text,
      "qty": int.parse(qtyCtrl.text),
      "description": descCtrl.text,
      "address": addressCtrl.text,
      "landmark": landmarkCtrl.text,
    });
  }

  /// EDIT NEED
  Future<void> editNeed(String id, Map<String, dynamic> data) async {
    final typeCtrl = TextEditingController(text: data["type"]);
    final qtyCtrl = TextEditingController(text: data["qty"].toString());
    final addressCtrl = TextEditingController(text: data["address"]);
    final landmarkCtrl = TextEditingController(text: data["landmark"]);

    final save = await showDialog<bool>(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Edit Need"),
            content: SingleChildScrollView(
              child: Column(
                children: [

                  TextField(
                    controller: typeCtrl,
                    decoration: const InputDecoration(labelText: "Item Title"),
                  ),

                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Quantity"),
                  ),

                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: "Address"),
                  ),

                  TextField(
                    controller: landmarkCtrl,
                    decoration: const InputDecoration(labelText: "Landmark"),
                  ),

                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel")),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Save")),
            ],
          ),
    );

    if (save != true) return;

    await _db.collection("needs").doc(id).update({
      "type": typeCtrl.text,
      "qty": int.parse(qtyCtrl.text),
      "address": addressCtrl.text,
      "landmark": landmarkCtrl.text,
    });
  }

  Widget buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedCity =
    capitalize(widget.profileUser.city);

    final formattedRole =
    capitalize(widget.profileUser.role);

    final bool isSender =
        widget.profileUser.role.toLowerCase() == "sender";

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              /// HEADER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary,
                      AppTheme.secondary
                    ],
                  ),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        backgroundImage:
                        _image != null
                            ? FileImage(_image!)
                            : null,
                        child: _image == null
                            ? const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey,
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.profileUser.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.profileUser.email,
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// ACTION BUTTONS (RESTORED)
              if (!isOwnProfile)
                Row(
                  children: [

                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                        ),
                        onPressed: callUser,
                        icon: const Icon(Icons.call),
                        label: const Text("Call"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: openMap,
                        icon: const Icon(Icons.map),
                        label: const Text("Map"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatScreen(
                                    currentUser: widget.currentUser,
                                    otherUser: widget.profileUser,
                                  ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.message),
                        label: const Text("Message"),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 35),

              if (isSender) ...[
                buildSectionTitle("Shared Items"),
                _buildResources(),
              ] else
                ...[
                  buildSectionTitle("Posted Needs"),
                  _buildNeeds(),
                ],
            ],
          ),
        ),
      ),
    );
  }

  // KEEPING YOUR RESOURCE + NEEDS UI EXACTLY SAME
  Widget _buildResources() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection("resources")
          .where("sharedByEmail",
          isEqualTo: widget.profileUser.email)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: docs.map((doc) {
            final data =
            doc.data() as Map<String, dynamic>;

            return Container(
              width: double.infinity,
              margin:
              const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F35),
                borderRadius:
                BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        Text(
                          data["title"] ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "Qty: ${data["qty"]} • ${data["condition"]}",
                          style: const TextStyle(
                              color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  Row(
                    children: [

                      if (isOwnProfile)
                        PopupMenuButton<String>(
                          icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white70),
                          onSelected: (value) {
                            if (value == "edit") {
                              editResource(
                                  doc.id, data);
                            }

                            if (value == "delete") {
                              deleteResource(doc.id);
                            }
                          },
                          itemBuilder: (context) =>
                          const [

                            PopupMenuItem(
                              value: "edit",
                              child: Text("Edit"),
                            ),

                            PopupMenuItem(
                              value: "delete",
                              child: Text("Delete"),
                            ),
                          ],
                        ),

                      const Icon(
                        Icons.inventory_2,
                        color: Colors.white54,
                      )
                    ],
                  )
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildNeeds() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection("needs")
          .where("receiverEmail",
          isEqualTo: widget.profileUser.email)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: docs.map((doc) {
            final data =
            doc.data() as Map<String, dynamic>;

            return Container(
              width: double.infinity,
              margin:
              const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F35),
                borderRadius:
                BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        Text(
                          data["type"] ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "Qty: ${data["qty"]}",
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Row(
                    children: [

                      if (isOwnProfile)
                        PopupMenuButton<String>(
                          icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white70),
                          onSelected: (value) {
                            if (value == "edit") {
                              editNeed(doc.id, data);
                            }

                            if (value == "delete") {
                              deleteNeed(doc.id);
                            }
                          },
                          itemBuilder: (context) =>
                          const [

                            PopupMenuItem(
                              value: "edit",
                              child: Text("Edit"),
                            ),

                            PopupMenuItem(
                              value: "delete",
                              child: Text("Delete"),
                            ),
                          ],
                        ),

                      const Icon(
                        Icons.help_outline,
                        color: Colors.white54,
                      )
                    ],
                  )
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}