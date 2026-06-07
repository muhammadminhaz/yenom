import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/suggestion_model.dart';
import '../../core/providers/suggestion_provider.dart';
import '../../core/utils/app_logger.dart';
import '../../widgets/neumorphic_container.dart';
import '../dashboard/add_transaction_screen.dart';
import 'suggestion_card_widget.dart';

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> {
  static const _tag = 'SuggestionsScreen';

  @override
  void initState() {
    super.initState();
    AppLogger.d(_tag, 'SuggestionsScreen opened');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(suggestionProvider.notifier).refresh();
    });
  }

  Future<void> _handleAccept(SuggestionModel suggestion) async {
    AppLogger.i(_tag, 'Accept tapped: ${suggestion.id}');
    try {
      // Mark accepted on backend first, then open pre-filled AddTransactionScreen
      await ref.read(suggestionProvider.notifier).accept(suggestion);

      if (!mounted) return;

      // Navigate to AddTransactionScreen pre-filled with suggestion data
      final added = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => AddTransactionScreen(prefill: suggestion),
        ),
      );

      if (added == true) {
        AppLogger.i(_tag, 'Transaction added from suggestion: ${suggestion.id}');
      }
    } catch (e) {
      AppLogger.e(_tag, 'Accept failed: ${suggestion.id}', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to accept suggestion. Try again.')),
        );
      }
    }
  }

  Future<void> _handleReject(SuggestionModel suggestion) async {
    AppLogger.i(_tag, 'Reject tapped: ${suggestion.id}');
    try {
      await ref.read(suggestionProvider.notifier).reject(suggestion);
      AppLogger.d(_tag, 'Suggestion rejected: ${suggestion.id}');
    } catch (e) {
      AppLogger.e(_tag, 'Reject failed: ${suggestion.id}', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(suggestionProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppConstants.spaceL),
            _buildHeader(context),
            const SizedBox(height: AppConstants.spaceM),
            Expanded(
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (suggestions) => _buildList(suggestions),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const NeumorphicContainer(
              width: 45, height: 45,
              shape: BoxShape.circle,
              child: Icon(Icons.arrow_back_ios_new, size: 18),
            ),
          ),
          const SizedBox(width: AppConstants.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Suggestions', style: Theme.of(context).textTheme.headlineSmall),
                Text(
                  'AI-detected transactions from Gmail & SMS',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(suggestionProvider.notifier).refresh(),
            child: const NeumorphicContainer(
              width: 40, height: 40,
              shape: BoxShape.circle,
              child: Icon(Icons.refresh, size: 18, color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<SuggestionModel> suggestions) {
    if (suggestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spaceXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✦', style: TextStyle(fontSize: 48, color: AppColors.primaryGreen)),
              const SizedBox(height: AppConstants.spaceL),
              const Text(
                'No pending suggestions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppConstants.fontL),
              ),
              const SizedBox(height: AppConstants.spaceS),
              Text(
                'Connect Gmail or set up SMS notifications in Settings to auto-detect transactions.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(suggestionProvider.notifier).refresh(),
      color: AppColors.primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppConstants.spaceM),
        itemBuilder: (_, i) {
          final suggestion = suggestions[i];
          return Dismissible(
            key: ValueKey(suggestion.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppConstants.spaceL),
              decoration: BoxDecoration(
                color: AppColors.expenseRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              child: const Icon(Icons.close, color: AppColors.expenseRed),
            ),
            onDismissed: (_) => _handleReject(suggestion),
            child: SuggestionCard(
              suggestion: suggestion,
              onAccept: () => _handleAccept(suggestion),
              onReject: () => _handleReject(suggestion),
            ),
          );
        },
      ),
    );
  }
}
