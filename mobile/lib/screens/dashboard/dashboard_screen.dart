import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/categories.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/transaction_enums.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/app_logger.dart';
import '../../widgets/neumorphic_container.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../suggestions/suggestion_banner_widget.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import 'transactions_list_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _tag = 'DashboardScreen';

  @override
  void initState() {
    super.initState();
    AppLogger.d(_tag, 'Dashboard initialized');
  }

  @override
  Widget build(BuildContext context) {
    final user = DatabaseService.getCurrentUser();
    final transactions = DatabaseService.getAllTransactions();

    final now = DateTime.now();
    final monthlyTxs = transactions
        .where((t) => t.transactionDate.year == now.year && t.transactionDate.month == now.month)
        .toList();

    double totalBalance = 0;
    double income = 0;
    double expenses = 0;
    double monthlyIncome = 0;
    double monthlyExpenses = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.INCOME) {
        income += tx.amount;
        totalBalance += tx.amount;
      } else {
        expenses += tx.amount;
        totalBalance -= tx.amount;
      }
    }

    for (final tx in monthlyTxs) {
      if (tx.type == TransactionType.INCOME) {
        monthlyIncome += tx.amount;
      } else {
        monthlyExpenses += tx.amount;
      }
    }

    final monthlySavePct = monthlyIncome > 0
        ? ((monthlyIncome - monthlyExpenses) / monthlyIncome * 100).clamp(0, 100).toStringAsFixed(0)
        : '—';

    final categoryTotals = DatabaseService.getCategoryTotals(type: TransactionType.EXPENSE);
    String topCategory = '—';
    if (categoryTotals.isNotEmpty) {
      topCategory = categoryTotals.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    AppLogger.d(_tag, 'Stats: balance=$totalBalance income=$income expenses=$expenses topCat=$topCategory');

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppConstants.spaceM, right: AppConstants.spaceM),
        child: FloatingActionButton(
          onPressed: () async {
            AppLogger.d(_tag, 'FAB tapped — opening AddTransactionScreen');
            final added = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
            );
            if (added == true) {
              AppLogger.i(_tag, 'Transaction added, refreshing dashboard');
              setState(() {});
            }
          },
          backgroundColor: AppColors.primaryGreen,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withOpacity(0.4),
                  offset: const Offset(0, 8),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppConstants.spaceXL),
              _buildHeader(context, user?.firstName ?? 'User'),
              const SizedBox(height: AppConstants.spaceXL),
              _buildBalanceCard(context, totalBalance, income, expenses),
              const SizedBox(height: AppConstants.spaceXL),
              _buildSummaryRow(context, monthlySavePct, topCategory),
              const SizedBox(height: AppConstants.spaceL),
              const SuggestionBannerWidget(),
              const SizedBox(height: AppConstants.spaceL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Transactions', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () async {
                      AppLogger.d(_tag, 'See All tapped');
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TransactionsListScreen()),
                      );
                      setState(() {});
                    },
                    child: const Text('See All', style: TextStyle(color: AppColors.primaryGreen)),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spaceM),
              _buildRecentTransactions(context, transactions.reversed.take(5).toList()),
              const SizedBox(height: AppConstants.spaceXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('As-salamu alaykum,', style: Theme.of(context).textTheme.bodyMedium),
            Text(name, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                AppLogger.d(_tag, 'Settings tapped');
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                setState(() {});
              },
              child: const NeumorphicContainer(
                width: 44, height: 44,
                shape: BoxShape.circle,
                child: Icon(Icons.settings_outlined, color: AppColors.primaryGreen, size: 20),
              ),
            ),
            const SizedBox(width: AppConstants.spaceS),
            GestureDetector(
              onTap: () async {
                AppLogger.d(_tag, 'Profile tapped');
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                setState(() {});
              },
              child: const NeumorphicContainer(
                width: 44, height: 44,
                shape: BoxShape.circle,
                child: Icon(Icons.person_outline, color: AppColors.primaryGreen, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(
      BuildContext context, double total, double income, double expenses) {
    final f = NumberFormat.currency(symbol: '\$');

    return NeumorphicContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spaceXL),
      child: Column(
        children: [
          Text('Total Balance', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppConstants.spaceS),
          Text(
            f.format(total),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: total >= 0 ? AppColors.primaryGreen : AppColors.expenseRed,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: AppConstants.spaceL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBalanceIndicator(
                context,
                label: 'Income',
                amount: f.format(income),
                color: AppColors.incomeGreen,
                icon: Icons.arrow_upward,
              ),
              _buildBalanceIndicator(
                context,
                label: 'Expenses',
                amount: f.format(expenses),
                color: AppColors.expenseRed,
                icon: Icons.arrow_downward,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceIndicator(
    BuildContext context, {
    required String label,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: AppConstants.spaceS),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, String savePct, String topCategory) {
    final isIslamic = AppCategories.isIslamic(topCategory);
    return Row(
      children: [
        Expanded(
          child: NeumorphicContainer(
            padding: const EdgeInsets.all(AppConstants.spaceM),
            child: Column(
              children: [
                const Icon(Icons.show_chart, color: AppColors.primaryGreen),
                const SizedBox(height: AppConstants.spaceS),
                Text('Monthly Save', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  savePct == '—' ? '—' : '$savePct%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spaceL),
        Expanded(
          child: NeumorphicContainer(
            padding: const EdgeInsets.all(AppConstants.spaceM),
            child: Column(
              children: [
                Icon(
                  AppCategories.iconFor(topCategory),
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(height: AppConstants.spaceS),
                Text('Top Category', style: Theme.of(context).textTheme.bodySmall),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        topCategory,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isIslamic) ...[
                      const SizedBox(width: 4),
                      const Text('☽', style: TextStyle(fontSize: 11, color: AppColors.primaryGreen)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(BuildContext context, List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spaceXL),
          child: Text('No transactions yet. Tap + to add one.'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppConstants.spaceM),
      itemBuilder: (_, i) {
        final tx = transactions[i];
        final isExpense = tx.type == TransactionType.EXPENSE;
        final isIslamic = AppCategories.isIslamic(tx.category);
        final typeColor = isExpense ? AppColors.expenseRed : AppColors.incomeGreen;
        final symbol = AppCategories.symbolFor(tx.currency);
        final dateFormat = DateFormat('d MMM');

        return GestureDetector(
          onTap: () async {
            AppLogger.d(_tag, 'Recent tx tapped: ${tx.id}');
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: tx)),
            );
            if (changed == true) setState(() {});
          },
          child: NeumorphicContainer(
            padding: const EdgeInsets.all(AppConstants.spaceM),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Icon(AppCategories.iconFor(tx.category), color: typeColor),
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
                              tx.description,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isIslamic)
                            const Text('☽', style: TextStyle(fontSize: 11, color: AppColors.primaryGreen)),
                        ],
                      ),
                      Text(
                        '${tx.category ?? 'Uncategorized'} • ${dateFormat.format(tx.transactionDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isExpense ? '-' : '+'}$symbol${tx.amount.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: typeColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
