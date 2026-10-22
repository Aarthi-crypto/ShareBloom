import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_bloom/models/user_model.dart';
import 'package:share_bloom/theme/app_theme.dart';
import 'package:share_bloom/services/location_service.dart';

class MyNeedsScreen extends StatefulWidget {
  final UserModel user;
  const MyNeedsScreen({super.key, required this.user});

  @override
  State<MyNeedsScreen> createState() => _MyNeedsScreenState();
}

class _MyNeedsScreenState extends State<MyNeedsScreen> {

  final typeCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final landmarkCtrl = TextEditingController();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool loading = false;

  /// 🔹 CONFIRMATION BEFORE POSTING NEED
  Future<void> _confirmPostNeed() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Confirm Need"),
          content: const Text(
              "Are you sure you want to post this need?"
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Post"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      postNeed();
    }
  }

  List<String> _extractKeywords(String text) {
    final stopWords = ["the","and","for","with","a","an","of"];
    final cleaned = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned
        .split(" ")
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toList();
  }

  Future<void> postNeed() async {

    final type = typeCtrl.text.trim();
    final qtyText = qtyCtrl.text.trim();
    final address = addressCtrl.text.trim();
    final landmark = landmarkCtrl.text.trim();

    if (type.isEmpty || qtyText.isEmpty || address.isEmpty) {
      _msg("Fill all required fields");
      return;
    }

    final qty = int.tryParse(qtyText);
    if (qty == null || qty <= 0) {
      _msg("Enter valid quantity");
      return;
    }

    setState(() => loading = true);

    final city = widget.user.city.trim().toLowerCase();

    final fullAddress = landmark.isEmpty
        ? "$address, $city"
        : "$address, $landmark, $city";

    final coords = await LocationService.getCoordinates(fullAddress);

    double latitude = coords?["lat"] ?? 0;
    double longitude = coords?["lng"] ?? 0;

    final needRef = await _db.collection("needs").add({
      "type": type,
      "qty": qty,
      "city": city,
      "receiverName": widget.user.name,
      "receiverEmail": widget.user.email,
      "receiverUid": widget.user.uid,
      "receiverPhone": widget.user.phone,
      "address": address,
      "landmark": landmark,
      "latitude": latitude,
      "longitude": longitude,
      "status": "Pending",
      "createdAt": FieldValue.serverTimestamp(),
    });

    final needKeywords = _extractKeywords(type);

    final resources = await _db
        .collection("resources")
        .where("city", isEqualTo: city)
        .where("status", isEqualTo: "Available")
        .get();

    int bestScore = 0;
    QueryDocumentSnapshot? bestMatch;

    for (var doc in resources.docs) {

      final data = doc.data() as Map<String,dynamic>;

      /// prevent self match
      if (data["sharedByUid"] == widget.user.uid) continue;

      if (data["matchedWithEmail"] != null) continue;

      final resourceKeywords =
      _extractKeywords(data["title"] ?? "");

      int score = 0;

      for (var word in needKeywords) {
        if (resourceKeywords.contains(word)) {
          score++;
        }
      }

      if (score < 1) continue;

      final resourceQty = data["qty"] ?? 0;
      final tolerance = (resourceQty * 0.3).round();

      if ((resourceQty - qty).abs() > tolerance) continue;

      if (score > bestScore) {
        bestScore = score;
        bestMatch = doc;
      }
    }

    if (bestMatch != null) {

      final data = bestMatch!.data() as Map<String,dynamic>;

      /// update resource
      await bestMatch!.reference.update({
        "status": "Pending",
        "matchedWithEmail": widget.user.email,
        "matchedNeedId": needRef.id,
      });

      /// update need
      await needRef.update({
        "matchedResourceId": bestMatch!.id,
      });

      /// 🔔 NOTIFY SENDER
      await _db.collection("notifications").add({
        "forUser": data["sharedByEmail"],
        "title": "New Need Match",
        "body": "${widget.user.name} requested your resource.",
        "resourceId": bestMatch!.id,
        "needId": needRef.id,
        "type": "match_profile",
        "otherUid": widget.user.uid,
        "otherName": widget.user.name,
        "otherEmail": widget.user.email,
        "otherPhone": widget.user.phone,
        "otherCity": widget.user.city,
        "otherRole": widget.user.role,
        "status": "Pending",
        "read": false,
        "createdAt": FieldValue.serverTimestamp(),
      });

      /// 🔔 NOTIFY RECEIVER THAT RESOURCE EXISTS
      await _db.collection("notifications").add({
        "forUser": widget.user.email,
        "title": "Resource Found",
        "body":
        "A resource matching your need was found. Waiting for sender approval.",
        "resourceId": bestMatch!.id,
        "needId": needRef.id,
        "type": "resource_update",
        "status": "Pending",
        "read": false,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    typeCtrl.clear();
    qtyCtrl.clear();
    addressCtrl.clear();
    landmarkCtrl.clear();

    _msg("Need posted successfully!");

    setState(() => loading = false);
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primary,
        content: Text(text),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _space({double h = 14}) => SizedBox(height: h);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 30),

              const Text(
                "Post My Need",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [

                    _field(typeCtrl, "Item Title"),
                    _space(),

                    _field(qtyCtrl, "Quantity",
                        keyboard: TextInputType.number),
                    _space(),

                    _field(addressCtrl, "Full Address"),
                    _space(),

                    _field(landmarkCtrl, "Landmark (Optional)"),
                    _space(h: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: loading ? null : _confirmPostNeed,
                        child: loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          "Post Need",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}