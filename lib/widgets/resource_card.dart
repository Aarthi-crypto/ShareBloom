import 'package:flutter/material.dart';
import 'package:share_bloom/models/resource_item.dart';
import 'package:share_bloom/theme/app_theme.dart';
import 'package:share_bloom/widgets/animated_card_wrapper.dart';

class ResourceCard extends StatelessWidget {
  final ResourceItem item;
  final VoidCallback? onRequest;

  const ResourceCard({
    super.key,
    required this.item,
    this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCardWrapper(
      keepAlive: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withOpacity(0.92),
          boxShadow: const [
            BoxShadow(
              blurRadius: 30,
              offset: Offset(0, 18),
              color: Color.fromRGBO(0, 0, 0, 0.08),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${item.title} • ${item.condition} • Qty: ${item.qty}",
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "City: ${item.city} • Shared by: ${item.sharedBy}",
              style: const TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 10),
            Text(
              item.description.isEmpty ? "No description added." : item.description,
              style: const TextStyle(fontSize: 13),
            ),
            const Spacer(),
            if (onRequest != null)
              Align(
                alignment: Alignment.bottomLeft,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onRequest,
                  child: const Text(
                    "Request This",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}