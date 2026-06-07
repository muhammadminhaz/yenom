import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/categories.dart';
import '../../core/models/suggestion_model.dart';
import '../../widgets/neumorphic_container.dart';

class SuggestionCard extends StatelessWidget {
  final SuggestionModel suggestion;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = suggestion.isExpense;
    final typeColor = isExpense ? AppColors.expenseRed : AppColors.incomeGreen;
    final isIslamic = AppCategories.isIslamic(suggestion.category);
    final symbol = AppCategories.symbolFor(suggestion.currency ?? 'USD');
    final dateFmt = DateFormat('d MMM yyyy');

    return NeumorphicContainer(
      padding: const EdgeInsets.all(AppConstants.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source badge + haram warning
          Row(
            children: [
              _SourceBadge(source: suggestion.source),
              const Spacer(),
              if (suggestion.isHaram)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spaceS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppConstants.radiusXS),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 12, color: Colors.amber),
                      SizedBox(width: 3),
                      Text(
                        'Check permissibility',
                        style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppConstants.spaceM),

          // Amount + type icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Icon(
                  AppCategories.iconFor(suggestion.category),
                  color: typeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            suggestion.description ?? 'Transaction',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppConstants.fontM),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isIslamic) ...[
                          const SizedBox(width: 4),
                          const Text('☽',
                              style: TextStyle(fontSize: 12, color: AppColors.primaryGreen)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      suggestion.category ?? 'Uncategorized',
                      style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: AppConstants.fontXS,
                          fontWeight: FontWeight.w500),
                    ),
                    if (suggestion.transactionDate != null)
                      Text(
                        dateFmt.format(suggestion.transactionDate!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    suggestion.amount != null
                        ? '${isExpense ? '-' : '+'}$symbol${suggestion.amount!.toStringAsFixed(2)}'
                        : 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppConstants.fontL,
                      color: typeColor,
                    ),
                  ),
                  if (suggestion.aiConfidence != null)
                    Text(
                      '${(suggestion.aiConfidence! * 100).toInt()}% match',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),

          // Haram reason
          if (suggestion.isHaram && suggestion.haramReason != null) ...[
            const SizedBox(height: AppConstants.spaceS),
            Container(
              padding: const EdgeInsets.all(AppConstants.spaceS),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppConstants.radiusXS),
              ),
              child: Text(
                suggestion.haramReason!,
                style: const TextStyle(fontSize: AppConstants.fontXS, color: Colors.amber),
              ),
            ),
          ],

          const SizedBox(height: AppConstants.spaceL),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Skip'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.expenseRed,
                    side: const BorderSide(color: AppColors.expenseRed),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spaceM),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Transaction'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String source;
  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final isGmail = source == 'GMAIL';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceS, vertical: 2),
      decoration: BoxDecoration(
        color: (isGmail ? Colors.redAccent : Colors.blueAccent).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusXS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGmail ? Icons.email_outlined : Icons.sms_outlined,
            size: 11,
            color: isGmail ? Colors.redAccent : Colors.blueAccent,
          ),
          const SizedBox(width: 3),
          Text(
            source,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isGmail ? Colors.redAccent : Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}
