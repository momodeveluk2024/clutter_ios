import 'package:flutter/material.dart';

import '../core/providers/recommendation_provider.dart';

/// Thumbs-up / thumbs-down buttons that close the recommendation feedback
/// loop. Drop into any rec card. Phase 1g.
///
/// Accept fires the feedback event but does NOT remove the card (it's still
/// useful — the user accepted it). Reject removes the card optimistically
/// via the provider and posts 'rejected' so the rec engine excludes it.
class RecommendationFeedbackButtons extends StatelessWidget {
  const RecommendationFeedbackButtons({
    super.key,
    required this.card,
    required this.provider,
  });

  final RecommendationCard card;
  final RecommendationProvider provider;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Helpful',
          icon: const Icon(Icons.thumb_up_outlined, size: 18),
          onPressed: () => provider.accept(card),
        ),
        IconButton(
          tooltip: 'Not for me',
          icon: const Icon(Icons.thumb_down_outlined, size: 18),
          onPressed: () => provider.reject(card),
        ),
      ],
    );
  }
}
