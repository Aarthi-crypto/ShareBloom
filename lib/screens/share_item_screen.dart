import 'package:flutter/material.dart';
import 'package:share_bloom/services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_bloom/models/user_model.dart';
import 'package:share_bloom/theme/app_theme.dart';

class ShareItemScreen extends StatefulWidget {
  final UserModel user;
  const ShareItemScreen({super.key, required this.user});

  @override
  State<ShareItemScreen> createState() => _ShareItemScreenState();
}

class _ShareItemScreenState extends State<ShareItemScreen> {

  final titleCtrl = TextEditingController();
  final conditionCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final landmarkCtrl = TextEditingController();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool loading = false;

  /// 🔹 CONFIRMATION BEFORE SHARE
  Future<void> _confirmShare() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Confirm Share"),
          content: const Text("Are you sure you want to share this resource?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context,false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context,true),
              child: const Text("Share"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      shareItem();
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

  Future<void> shareItem() async {

    final title = titleCtrl.text.trim();
    final condition = conditionCtrl.text.trim();
    final qtyText = qtyCtrl.text.trim();
    final address = addressCtrl.text.trim();
    final landmark = landmarkCtrl.text.trim();
    final description = descCtrl.text.trim();

    if (title.isEmpty ||
        condition.isEmpty ||
        qtyText.isEmpty ||
        address.isEmpty) {
      _msg("Fill all required fields");
      return;
    }

    final qty = int.tryParse(qtyText);

    if (qty == null || qty <= 0) {
      _msg("Enter valid quantity");
      return;
    }

    setState(() => loading = true);

    String city = widget.user.city.trim().toLowerCase();

    final pos = await LocationService.getCurrentLocation();

    if (pos != null) {
      final detectedCity =
      await LocationService.getCityFromCoordinates(
          pos.latitude, pos.longitude);

      if (detectedCity != null) {
        city = detectedCity.toLowerCase();
      }
    }

    String fullAddress;

    if (landmark.isNotEmpty) {
      fullAddress = "$address, $landmark, $city, India";
    } else {
      fullAddress = "$address, $city, India";
    }

    final coords =
    await LocationService.getCoordinates(fullAddress);

    double lat = coords?["lat"] ?? 0;
    double lng = coords?["lng"] ?? 0;

    final resourceRef = await _db.collection("resources").add({
      "title": title,
      "condition": condition,
      "qty": qty,
      "city": city,
      "sharedBy": widget.user.name,
      "sharedByEmail": widget.user.email,
      "sharedByUid": widget.user.uid,
      "sharedByPhone": widget.user.phone,
      "description": description,
      "address": address,
      "landmark": landmark,
      "latitude": lat,
      "longitude": lng,
      "status": "Available",
      "createdAt": FieldValue.serverTimestamp(),
    });

    final resourceKeywords = _extractKeywords(title);

    final needs = await _db
        .collection("needs")
        .where("city", isEqualTo: city)
        .get();

    int bestScore = 0;
    QueryDocumentSnapshot? bestMatch;

    for (var doc in needs.docs) {

      final data = doc.data() as Map<String,dynamic>;

      if (data["status"] != "Pending") continue;
      if (data["receiverUid"] == widget.user.uid) continue;
      if (data["matchedResourceId"] != null) continue;

      final needKeywords =
      _extractKeywords(data["type"] ?? "");

      int score = 0;

      for (var word in needKeywords) {
        if (resourceKeywords.contains(word)) {
          score++;
        }
      }

      if (score < 1) continue;

      final needQty = data["qty"] ?? 0;
      final tolerance = (qty * 0.3).round();

      if ((qty - needQty).abs() > tolerance) continue;

      if (score > bestScore) {
        bestScore = score;
        bestMatch = doc;
      }
    }

    if (bestMatch != null) {

      final data = bestMatch!.data() as Map<String,dynamic>;

      await resourceRef.update({
        "status": "Pending",
        "matchedWithEmail": data["receiverEmail"],
        "matchedNeedId": bestMatch!.id,
      });

      await bestMatch!.reference.update({
        "matchedResourceId": resourceRef.id,
      });

      await _db.collection("notifications").add({
        "forUser": data["receiverEmail"],
        "title": "Resource Match Found",
        "body":
        "${widget.user.name} shared a resource matching your need.",
        "resourceId": resourceRef.id,
        "needId": bestMatch!.id,
        "type": "resource_update",
        "status": "Pending",
        "read": false,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    titleCtrl.clear();
    conditionCtrl.clear();
    qtyCtrl.clear();
    descCtrl.clear();
    addressCtrl.clear();
    landmarkCtrl.clear();

    _msg("Item shared successfully");

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
                "Share an Item",
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

                    _field(titleCtrl, "Item Title"),
                    _space(),

                    _field(conditionCtrl, "Condition"),
                    _space(),

                    _field(qtyCtrl, "Quantity",
                        keyboard: TextInputType.number),
                    _space(),

                    _field(descCtrl, "Description (Optional)"),
                    _space(),

                    _field(addressCtrl, "Full Address"),
                    _space(),

                    _field(landmarkCtrl, "Landmark (Optional)"),
                    _space(h: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: loading ? null : _confirmShare,
                        child: loading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          "Share Item",
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