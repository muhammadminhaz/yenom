import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/categories.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/transaction_enums.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/app_logger.dart';
import '../../widgets/neumorphic_container.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  static const _tag = 'TransactionsListScreen';

  final _searchController = TextEditingController();
  String _typeFilter = 'All';       // 'All' | 'Income' | 'Expense'
  String _categoryFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    AppLogger.d(_tag, 'Initialized');
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> _filtered(List<TransactionModel> all) {
    AppLogger.d(_tag, 'Filtering ${all.length} transactions — type: $_typeFilter, category: $_categoryFilter, search: "$_searchQuery"');
    return all.where((tx) {
      final matchType = _typeFilter == 'All' ||
          (_typeFilter == 'Income' && tx.type == TransactionType.INCOME) ||
          (_typeFilter == 'Expense' && tx.type == TransactionType.EXPENSE);
      final matchCategory = _categoryFilter == 'All' || tx.category == _categoryFilter;
      final matchSearch = _searchQuery.isEmpty ||
          tx.description.toLowerCase().contains(_searchQuery) ||
          (tx.category ?? '').toLowerCase().contains(_searchQuery);
      return matchType && matchCategory && matchSearch;
    }).toList();
  }

  List<String> _allCategories(List<TransactionModel> all) {
    final cats = all.map((t) => t.category ?? 'Other').toSet().toList()..sort();
    return ['All', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    final all = DatabaseService.getAllTransactions().reversed.toList();
    final filtered = _filtered(all);
    final categories = _allCategories(all);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, filtered.length),
            const SizedBox(height: AppConstants.spaceS),
            _buildSearchBar(),
            const SizedBox(height: AppConstants.spaceS),
            _buildTypeFilter(),
            const SizedBox(height: AppConstants.spaceS),
            _buildCategoryChips(categories),
            const SizedBox(height: AppConstants.spaceS),
            Expanded(child: _buildList(filtered)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceL, AppConstants.spaceL, AppConstants.spaceL, 0,
      ),
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
                Text('Transactions', style: Theme.of(context).textTheme.headlineSmall),
                Text('$count records', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
      child: NeumorphicContainer(
        isInset: true,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search transactions…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      AppLogger.d(_tag, 'Search cleared');
                    },
                    child: const Icon(Icons.close, size: 18),
                  )
                : null,
            hintStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontSize: AppConstants.fontM,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
      child: Row(
        children: ['All', 'Income', 'Expense'].map((type) {
          final isSelected = _typeFilter == type;
          Color? color;
          if (type == 'Income') color = AppColors.incomeGreen;
          if (type == 'Expense') color = AppColors.expenseRed;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: AppConstants.spaceS),
              child: GestureDetector(
                onTap: () {
                  AppLogger.d(_tag, 'Type filter changed to: $type');
                  setState(() => _typeFilter = type);
                },
                child: NeumorphicContainer(
                  isInset: isSelected,
                  padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceS),
                  child: Center(
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: AppConstants.fontS,
                        fontWeight: isSelected ? FontWeight.bold : null,
                        color: isSelected ? (color ?? AppColors.primaryGreen) : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryChips(List<String> categories) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceL),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppConstants.spaceS),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = _categoryFilter == cat;
          final isIslamic = AppCategories.isIslamic(cat);
          return GestureDetector(
            onTap: () {
              AppLogger.d(_tag, 'Category filter changed to: $cat');
              setState(() => _categoryFilter = cat);
            },
            child: NeumorphicContainer(
              isInset: isSelected,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceM, vertical: AppConstants.spaceXS,
              ),
              child: Row(
                children: [
                  if (isIslamic) ...[
                    const Text('☽', style: TextStyle(fontSize: 12, color: AppColors.primaryGreen)),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    cat,
                    style: TextStyle(
                      fontSize: AppConstants.fontS,
                      color: isSelected
                          ? (isIslamic ? AppColors.primaryGreen : AppColors.primaryGreen)
                          : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      AppLogger.d(_tag, 'No transactions to display');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: AppConstants.spaceM),
            Text(
              'No transactions found',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceL, AppConstants.spaceS, AppConstants.spaceL, AppConstants.spaceXL,
      ),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppConstants.spaceM),
      itemBuilder: (_, i) => _buildSwipeableTile(transactions[i]),
    );
  }

  Widget _buildSwipeableTile(TransactionModel tx) {
    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppConstants.spaceL),
        decoration: BoxDecoration(
          color: AppColors.expenseRed.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.expenseRed),
      ),
      confirmDismiss: (_) => _confirmDelete(tx),
      onDismissed: (_) async {
        AppLogger.i(_tag, 'Transaction swiped-deleted: ${tx.id}');
        await DatabaseService.deleteTransactionById(tx.id);
        setState(() {});
      },
      child: _TransactionTile(
        transaction: tx,
        onTap: () => _openDetail(tx),
      ),
    );
  }

  Future<bool> _confirmDelete(TransactionModel tx) async {
    AppLogger.w(_tag, 'Swipe-delete confirm for: ${tx.id}');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Delete "${tx.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.expenseRed)),
          ),
        ],
      ),
    );
    if (result != true) AppLogger.d(_tag, 'Swipe-delete cancelled for: ${tx.id}');
    return result ?? false;
  }

  Future<void> _openDetail(TransactionModel tx) async {
    AppLogger.d(_tag, 'Opening detail for: ${tx.id}');
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: tx)),
    );
    if (changed == true) {
      AppLogger.d(_tag, 'Detail returned change=true, refreshing');
      setState(() {});
    }
  }
}

// ── Transaction Tile ──────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;

  const _TransactionTile({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final isExpense = tx.type == TransactionType.EXPENSE;
    final isIslamic = AppCategories.isIslamic(tx.category);
    final typeColor = isExpense ? AppColors.expenseRed : AppColors.incomeGreen;
    final symbol = AppCategories.symbolFor(tx.currency);
    final dateFormat = DateFormat('d MMM yyyy');

    return GestureDetector(
      onTap: onTap,
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
              child: Icon(
                AppCategories.iconFor(tx.category),
                color: typeColor,
                size: 22,
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
                          tx.description,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isIslamic)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text('☽', style: TextStyle(fontSize: 12, color: AppColors.primaryGreen)),
                        ),
                    ],
                  ),
                  Text(
                    '${tx.category ?? 'Uncategorized'} • ${dateFormat.format(tx.transactionDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.spaceS),
            Text(
              '${isExpense ? '-' : '+'}$symbol${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: typeColor,
                fontSize: AppConstants.fontM,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
