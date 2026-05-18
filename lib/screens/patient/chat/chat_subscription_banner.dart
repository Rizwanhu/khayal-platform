import 'package:flutter/material.dart';

import '../../../core/chat/chat_subscription_period.dart';

/// Shows paid plan + billing period above the patient chat thread.
class ChatSubscriptionBanner extends StatelessWidget {
  const ChatSubscriptionBanner({super.key, required this.display});

  final ChatSubscriptionPeriodDisplay display;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8F0E9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              display.planLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4A6B52),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              display.rangeLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5C7260),
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
