import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/neumorphic_container.dart';
import 'transactions_list_screen.dart';
import 'add_transaction_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/services/database_service.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/transaction_enums.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final user = DatabaseService.getCurrentUser();
    final transactions = DatabaseService.getAllTransactions();
    
    double totalBalance = 0;
    double income = 0;
    double expenses = 0;
    
    for (var tx in transactions) {
      if (tx.type == TransactionType.INCOME) {
        income += tx.amount;
        totalBalance += tx.amount;
      } else {
        expenses += tx.amount;
        totalBalance -= tx.amount;
      }
    }

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppConstants.spaceM, right: AppConstants.spaceM),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
            );
            setState(() {}); // Refresh after returning from add screen
          },
          backgroundColor: AppColors.primaryGreen,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryGreen,
                  AppColors.primaryGreenDark,
                ],
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
              _buildSummaryRow(context),
              const SizedBox(height: AppConstants.spaceXL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const TransactionsListScreen()),
                      );
                    },
                    child: const Text(
                      'See All',
                      style: TextStyle(color: AppColors.primaryGreen),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spaceM),
              _buildTransactionsList(transactions.reversed.take(5).toList()),
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
            Text(
              'Hello, $name!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Welcome back to your wallet',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            setState(() {}); // Refresh if profile changed
          },
          child: const NeumorphicContainer(
            width: 50,
            height: 50,
            shape: BoxShape.circle,
            child: Icon(Icons.person_outline, color: AppColors.primaryGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, double total, double income, double expenses) {
    final NumberFormat formatter = NumberFormat.currency(symbol: '\$');
    
    return NeumorphicContainer(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spaceXL),
      child: Column(
        children: [
          Text(
            'Total Balance',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppConstants.spaceS),
          Text(
            formatter.format(total),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.primaryGreen,
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
                amount: formatter.format(income),
                color: AppColors.incomeGreen,
                icon: Icons.arrow_upward,
              ),
              _buildBalanceIndicator(
                context,
                label: 'Expenses',
                amount: formatter.format(expenses),
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
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: AppConstants.spaceS),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context) {
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
                const Text('25%', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const Icon(Icons.pie_chart_outline, color: AppColors.primaryGreen),
                const SizedBox(height: AppConstants.spaceS),
                Text('Top Category', style: Theme.of(context).textTheme.bodySmall),
                const Text('Food', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.spaceXL),
          child: Text('No transactions yet'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppConstants.spaceM),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final bool isExpense = tx.type == TransactionType.EXPENSE;
        final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

        return NeumorphicContainer(
          padding: const EdgeInsets.all(AppConstants.spaceM),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: (isExpense ? AppColors.expenseRed : AppColors.incomeGreen).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Icon(
                  isExpense ? Icons.shopping_bag_outlined : Icons.payments_outlined,
                  color: isExpense ? AppColors.expenseRed : AppColors.incomeGreen,
                ),
              ),
              const SizedBox(width: AppConstants.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.description,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${tx.category ?? 'Uncategorized'} • ${dateFormat.format(tx.transactionDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isExpense ? '-' : '+'}\$${tx.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isExpense ? AppColors.expenseRed : AppColors.incomeGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppConstants.spaceS),
              const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }
}
