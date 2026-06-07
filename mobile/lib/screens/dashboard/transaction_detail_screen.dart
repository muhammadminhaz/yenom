import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/categories.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/transaction_enums.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/app_logger.dart';
import '../../widgets/neumorphic_button.dart';
import '../../widgets/neumorphic_container.dart';
import 'add_transaction_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  static const _tag = 'TransactionDetailScreen';

  @override
  Widget build(BuildContext context) {
    AppLogger.d(_tag, 'Viewing transaction: ${transaction.id}');

    final isExpense = transaction.type == TransactionType.EXPENSE;
    final isIslamic = AppCategories.isIslamic(transaction.category);
    final typeColor = isExpense ? AppColors.expenseRed : AppColors.incomeGreen;
    final dateFormat = DateFormat('EEEE, d MMMM yyyy');
    final currencySymbol = AppCategories.symbolFor(transaction.currency);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(context),
              const SizedBox(height: AppConstants.spaceXL),

              // Amount hero
              NeumorphicContainer(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.spaceXL),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                      child: Icon(
                        AppCategories.iconFor(transaction.category),
                        color: typeColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spaceM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${isExpense ? '-' : '+'}$currencySymbol${transaction.amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: typeColor,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isIslamic) ...[
                          const SizedBox(width: AppConstants.spaceS),
                          const Text('☽', style: TextStyle(fontSize: 20, color: AppColors.primaryGreen)),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppConstants.spaceS),
                    Text(
                      transaction.description,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spaceXL),

              // Details
              _buildDetailCard(context, [
                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: transaction.category ?? 'Uncategorized',
                  valueColor: isIslamic ? AppColors.primaryGreen : null,
                ),
                _DetailRow(
                  icon: isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                  label: 'Type',
                  value: isExpense ? 'Expense' : 'Income',
                  valueColor: typeColor,
                ),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: dateFormat.format(transaction.transactionDate),
                ),
                _DetailRow(
                  icon: Icons.currency_exchange,
                  label: 'Currency',
                  value: '${transaction.currency}  (${AppCategories.symbolFor(transaction.currency)})',
                ),
                _DetailRow(
                  icon: Icons.check_circle_outline,
                  label: 'Status',
                  value: transaction.status.name,
                ),
                _DetailRow(
                  icon: Icons.access_time_outlined,
                  label: 'Added on',
                  value: DateFormat('d MMM yyyy, h:mm a').format(transaction.createdAt),
                ),
              ]),

              const SizedBox(height: AppConstants.spaceXXL),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: NeumorphicButton(
                      onPressed: () => _edit(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryGreen),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceL),
                  Expanded(
                    child: NeumorphicButton(
                      onPressed: () => _confirmDelete(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.expenseRed),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.expenseRed)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spaceXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const NeumorphicContainer(
            width: 45,
            height: 45,
            shape: BoxShape.circle,
            child: Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
        const SizedBox(width: AppConstants.spaceM),
        Text('Transaction Details', style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }

  Widget _buildDetailCard(BuildContext context, List<_DetailRow> rows) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(AppConstants.spaceL),
      width: double.infinity,
      child: Column(
        children: rows.map((row) {
          final isLast = rows.last == row;
          return Column(
            children: [
              Row(
                children: [
                  Icon(row.icon, size: 18, color: AppColors.primaryGreen),
                  const SizedBox(width: AppConstants.spaceM),
                  Text(
                    row.label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    row.value,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppConstants.fontS,
                      color: row.valueColor,
                    ),
                  ),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: AppConstants.spaceM),
                Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                const SizedBox(height: AppConstants.spaceM),
              ],
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    AppLogger.i(_tag, 'Edit tapped for: ${transaction.id}');
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(editTransaction: transaction),
      ),
    );
    if (updated == true && context.mounted) {
      AppLogger.d(_tag, 'Transaction edited, popping detail screen');
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    AppLogger.w(_tag, 'Delete requested for: ${transaction.id}');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Delete "${transaction.description}" for '
          '${AppCategories.symbolFor(transaction.currency)}${transaction.amount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.expenseRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      AppLogger.i(_tag, 'Confirmed delete for: ${transaction.id}');
      await DatabaseService.deleteTransactionById(transaction.id);
      if (context.mounted) Navigator.pop(context, true);
    } else {
      AppLogger.d(_tag, 'Delete cancelled');
    }
  }
}

class _DetailRow {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}
