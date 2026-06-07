import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/suggestion_provider.dart';
import '../../widgets/neumorphic_container.dart';
import 'suggestions_screen.dart';

/// Compact banner shown on the dashboard when there are pending suggestions.
/// Hidden when count is 0.
class SuggestionBannerWidget extends ConsumerWidget {
  const SuggestionBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(suggestionProvider);
    final notifier = ref.read(suggestionProvider.notifier);
    final count = notifier.pendingCount;
    final hasHaram = notifier.hasHaram;

    if (count == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SuggestionsScreen()),
        );
        // Refresh after returning in case user accepted/rejected some
        ref.read(suggestionProvider.notifier).refresh();
      },
      child: NeumorphicContainer(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceL,
          vertical: AppConstants.spaceM,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('✦', style: TextStyle(color: AppColors.primaryGreen, fontSize: 18)),
              ),
            ),
            const SizedBox(width: AppConstants.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$count new suggestion${count > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      if (hasHaram) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.amber),
                      ],
                    ],
                  ),
                  const Text(
                    'Tap to review auto-detected transactions',
                    style: TextStyle(fontSize: AppConstants.fontXS),
                  ),
                ],
              ),
            ),
            state.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryGreen,
                    ),
                  )
                : const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primaryGreen),
          ],
        ),
      ),
    );
  }
}
