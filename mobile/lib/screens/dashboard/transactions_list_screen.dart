import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/neumorphic_container.dart';
import '../../core/services/database_service.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/transaction_enums.dart';
import 'package:intl/intl.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Food', 'Work', 'Health', 'Utilities', 'Transport'];

  @override
  Widget build(BuildContext context) {
    final transactions = DatabaseService.getAllTransactions();
    final filteredTransactions = _selectedCategory == 'All'
        ? transactions
        : transactions.where((tx) => tx.category == _selectedCategory).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildFilters(),
            Expanded(
              child: _buildTransactionsList(filteredTransactions.reversed.toList()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spaceL),
      child: Row(
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
          const SizedBox(width: AppConstants.spaceL),
          Text(
            'All Transactions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Spacer(),
          const NeumorphicContainer(
            width: 45,
            height: 45,
            shape: BoxShape.circle,
            child: Icon(Icons.calendar_today, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
      child: Row(
        children: [
          ..._categories.map((category) => Padding(
                padding: const EdgeInsets.only(right: AppConstants.spaceS),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: NeumorphicContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spaceM,
                      vertical: AppConstants.spaceS,
                    ),
                    isInset: _selectedCategory == category,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: _selectedCategory == category
                            ? AppColors.primaryGreen
                            : null,
                        fontWeight: _selectedCategory == category
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ),
                )),
          ),
          const SizedBox(width: AppConstants.spaceS),
          const NeumorphicContainer(
            padding: EdgeInsets.all(AppConstants.spaceS),
            child: Icon(Icons.filter_list, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text('No transactions found'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.spaceL),
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
            ],
          ),
        );
      },
    );
  }
}
