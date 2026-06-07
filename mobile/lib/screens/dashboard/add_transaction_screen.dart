import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/categories.dart';
import '../../core/models/suggestion_model.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/transaction_enums.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/app_logger.dart';
import '../../widgets/neumorphic_button.dart';
import '../../widgets/neumorphic_container.dart';
import '../../widgets/neumorphic_text_field.dart';

class AddTransactionScreen extends StatefulWidget {
  /// Pass an existing transaction to enter edit mode.
  final TransactionModel? editTransaction;

  /// Pass a suggestion to pre-fill the form from AI-detected data.
  final SuggestionModel? prefill;

  const AddTransactionScreen({super.key, this.editTransaction, this.prefill});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const _tag = 'AddTransactionScreen';

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TransactionType _type = TransactionType.EXPENSE;
  String? _selectedCategory;
  String _selectedCurrency = 'USD';

  bool get _isEditing => widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      AppLogger.d(_tag, 'Opening in edit mode for id: ${widget.editTransaction!.id}');
      final tx = widget.editTransaction!;
      _amountController.text = tx.amount.toString();
      _descriptionController.text = tx.description;
      _selectedDate = tx.transactionDate;
      _type = tx.type;
      _selectedCategory = tx.category;
      _selectedCurrency = tx.currency;
    } else if (widget.prefill != null) {
      // Pre-fill from an AI suggestion
      final p = widget.prefill!;
      AppLogger.d(_tag, 'Opening in prefill mode from suggestion: ${p.id}');
      if (p.amount != null) _amountController.text = p.amount!.toStringAsFixed(2);
      if (p.description != null) _descriptionController.text = p.description!;
      if (p.transactionDate != null) _selectedDate = p.transactionDate!;
      if (p.type == 'INCOME') _type = TransactionType.INCOME;
      _selectedCategory = p.category;
      if (p.currency != null) _selectedCurrency = p.currency!;
    } else {
      AppLogger.d(_tag, 'Opening in add mode');
    }
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryGreen,
            onPrimary: Colors.white,
            onSurface: AppColors.lightTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      AppLogger.d(_tag, 'Date selected: $picked');
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _showCategoryPicker() {
    AppLogger.d(_tag, 'Opening category picker, type: $_type');
    final isExpense = _type == TransactionType.EXPENSE;
    final groups = isExpense
        ? [
            ('Expense Categories', AppCategories.expenseCategories),
            ('Charitable (Islamic)', AppCategories.islamicCategories),
          ]
        : [
            ('Income Categories', AppCategories.incomeCategories),
          ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryPickerSheet(
        groups: groups,
        selected: _selectedCategory,
        onSelect: (value) {
          AppLogger.i(_tag, 'Category selected: $value');
          setState(() => _selectedCategory = value);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showCurrencyPicker() {
    AppLogger.d(_tag, 'Opening currency picker');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CurrencyPickerSheet(
        selected: _selectedCurrency,
        onSelect: (code) {
          AppLogger.i(_tag, 'Currency selected: $code');
          setState(() => _selectedCurrency = code);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _save() async {
    AppLogger.i(_tag, 'Save tapped — isEditing: $_isEditing');

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      AppLogger.w(_tag, 'Validation failed: invalid amount "${_amountController.text}"');
      _showSnack('Please enter a valid amount greater than 0');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      AppLogger.w(_tag, 'Validation failed: empty description');
      _showSnack('Please enter a description');
      return;
    }
    if (_selectedCategory == null) {
      AppLogger.w(_tag, 'Validation failed: no category selected');
      _showSnack('Please select a category');
      return;
    }

    final user = DatabaseService.getCurrentUser();
    final userId = user?.id ?? 'local_user';

    if (_isEditing) {
      final updated = TransactionModel(
        id: widget.editTransaction!.id,
        userId: userId,
        amount: amount,
        currency: _selectedCurrency,
        transactionDate: _selectedDate,
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        type: _type,
        status: widget.editTransaction!.status,
        createdAt: widget.editTransaction!.createdAt,
        updatedAt: DateTime.now(),
      );
      await DatabaseService.updateTransactionById(widget.editTransaction!.id, updated);
      AppLogger.i(_tag, 'Transaction updated: ${updated.id}');
    } else {
      final transaction = TransactionModel(
        id: const Uuid().v4(),
        userId: userId,
        amount: amount,
        currency: _selectedCurrency,
        transactionDate: _selectedDate,
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        type: _type,
        status: TransactionStatus.COMPLETED,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await DatabaseService.addTransaction(transaction);
      AppLogger.i(_tag, 'Transaction created: ${transaction.id}');
    }

    if (mounted) Navigator.pop(context, true);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(),
              const SizedBox(height: AppConstants.spaceXL),
              Text(
                _isEditing ? 'Edit Transaction' : 'Add Transaction',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppConstants.spaceL),
              _buildTypeSelector(),
              const SizedBox(height: AppConstants.spaceXL),
              _buildAmountRow(),
              const SizedBox(height: AppConstants.spaceL),
              NeumorphicTextField(
                controller: _descriptionController,
                hintText: 'Description',
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: AppConstants.spaceL),
              _buildCategorySelector(),
              const SizedBox(height: AppConstants.spaceL),
              NeumorphicTextField(
                controller: _dateController,
                hintText: 'Date',
                prefixIcon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: _selectDate,
              ),
              const SizedBox(height: AppConstants.spaceXXXL),
              NeumorphicButton(
                isPrimary: true,
                onPressed: _save,
                child: Text(
                  _isEditing ? 'Update Transaction' : 'Save Transaction',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: AppConstants.fontL,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: const NeumorphicContainer(
        width: 45,
        height: 45,
        shape: BoxShape.circle,
        child: Icon(Icons.close, size: 24),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        _typeChip(TransactionType.EXPENSE, 'Expense', AppColors.expenseRed),
        const SizedBox(width: AppConstants.spaceL),
        _typeChip(TransactionType.INCOME, 'Income', AppColors.incomeGreen),
      ],
    );
  }

  Widget _typeChip(TransactionType type, String label, Color color) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _selectedCategory = null; // reset category on type change
        }),
        child: NeumorphicContainer(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceM),
          isInset: isSelected,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: _showCurrencyPicker,
          child: NeumorphicContainer(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedCurrency,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppConstants.fontM),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spaceS),
        Expanded(
          child: NeumorphicTextField(
            controller: _amountController,
            hintText: '0.00',
            prefixIcon: Icons.attach_money,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final icon = _selectedCategory != null
        ? AppCategories.iconFor(_selectedCategory)
        : Icons.category_outlined;
    final isIslamic = AppCategories.isIslamic(_selectedCategory);

    return GestureDetector(
      onTap: _showCategoryPicker,
      child: NeumorphicContainer(
        isInset: _selectedCategory != null,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceM,
          vertical: AppConstants.spaceM,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isIslamic ? AppColors.primaryGreen : null),
            const SizedBox(width: AppConstants.spaceM),
            Expanded(
              child: Text(
                _selectedCategory ?? 'Select Category',
                style: TextStyle(
                  fontSize: AppConstants.fontM,
                  color: _selectedCategory != null
                      ? (isIslamic ? AppColors.primaryGreen : null)
                      : (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
              ),
            ),
            if (isIslamic)
              const Text('☽', style: TextStyle(fontSize: 14, color: AppColors.primaryGreen)),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Category Picker Bottom Sheet ──────────────────────────────────────────────

class _CategoryPickerSheet extends StatelessWidget {
  final List<(String, List<CategoryItem>)> groups;
  final String? selected;
  final ValueChanged<String> onSelect;

  const _CategoryPickerSheet({
    required this.groups,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusL)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceL, AppConstants.spaceM, AppConstants.spaceL, AppConstants.spaceXL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spaceL),
          Text('Select Category', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppConstants.spaceL),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: groups.map((group) {
                  final (label, items) = group;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppConstants.spaceS),
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: label.contains('Islamic')
                                ? AppColors.primaryGreen
                                : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: AppConstants.spaceS,
                        runSpacing: AppConstants.spaceS,
                        children: items.map((item) {
                          final isSelected = selected == item.value;
                          return GestureDetector(
                            onTap: () => onSelect(item.value),
                            child: NeumorphicContainer(
                              isInset: isSelected,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.spaceM,
                                vertical: AppConstants.spaceS,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 16,
                                    color: isSelected
                                        ? AppColors.primaryGreen
                                        : (item.isIslamic ? AppColors.primaryGreen : null),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: AppConstants.fontS,
                                      color: isSelected ? AppColors.primaryGreen : null,
                                      fontWeight: isSelected ? FontWeight.bold : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppConstants.spaceL),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Currency Picker Bottom Sheet ──────────────────────────────────────────────

class _CurrencyPickerSheet extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _CurrencyPickerSheet({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusL)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceL, AppConstants.spaceM, AppConstants.spaceL, AppConstants.spaceXL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spaceL),
          Text('Select Currency', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppConstants.spaceM),
          ...AppCategories.currencies.map((currency) {
            final isSelected = currency.code == selected;
            return GestureDetector(
              onTap: () => onSelect(currency.code),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spaceM,
                  horizontal: AppConstants.spaceS,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        currency.symbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppConstants.fontL,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currency.code, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(currency.name, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppConstants.spaceS),
        ],
      ),
    );
  }
}
