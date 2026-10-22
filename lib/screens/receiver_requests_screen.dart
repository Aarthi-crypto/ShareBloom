import 'package:flutter/material.dart';
import 'package:share_bloom/data/dummy_data.dart';
import 'package:share_bloom/theme/app_theme.dart';

class ReceiverRequestsScreen extends StatefulWidget {
  const ReceiverRequestsScreen({super.key});

  @override
  State<ReceiverRequestsScreen> createState() => _ReceiverRequestsScreenState();
}

class _ReceiverRequestsScreenState extends State<ReceiverRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    final needs = DummyData.needs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Requests",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          "Receiver needs list (senders can view & accept).",
          style: TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 18),

        Expanded(
          child: ListView.builder(
            itemCount: needs.length,
            itemBuilder: (context, index) {
              final n = needs[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withOpacity(0.92),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${n.type} • Qty: ${n.qty}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Receiver: ${n.receiverName} • ${n.city}",
                            style: const TextStyle(color: AppTheme.muted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Status: ${n.status}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    if (n.status == "Pending") ...[
                      ElevatedButton(
                        onPressed: () {
                          DummyData.needs[index] = DummyData.needs[index]
                              .copyWith(status: "Accepted");

                          DummyData.notifications.add({
                            "title": "Need Accepted",
                            "body":
                            "Need accepted: ${n.type} (${n.qty}) for ${n.receiverName}",
                          });

                          setState(() {});
                        },
                        child: const Text("Accept"),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          DummyData.needs[index] = DummyData.needs[index]
                              .copyWith(status: "Rejected");

                          DummyData.notifications.add({
                            "title": "Need Rejected",
                            "body":
                            "Need rejected: ${n.type} (${n.qty}) for ${n.receiverName}",
                          });

                          setState(() {});
                        },
                        child: const Text("Reject"),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}