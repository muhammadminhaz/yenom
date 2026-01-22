import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/neumorphic_container.dart';
import '../../widgets/neumorphic_button.dart';
import '../../widgets/neumorphic_text_field.dart';

import 'package:intl/intl.dart';
import '../../core/models/transaction_model.dart';
import '../../core/models/transaction_enums.dart';
import '../../core/services/database_service.dart';
import 'package:uuid/uuid.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TransactionType _type = TransactionType.EXPENSE;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.lightTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  void _saveTransaction() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0 || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid amount and description')),
      );
      return;
    }

    final user = DatabaseService.getCurrentUser();
    final userId = user?.id ?? 'dummy_user_id';

    final transaction = TransactionModel(
      id: const Uuid().v4(),
      userId: userId,
      amount: amount,
      currency: 'USD',
      transactionDate: _selectedDate,
      description: _descriptionController.text,
      category: _categoryController.text,
      type: _type,
      status: TransactionStatus.COMPLETED,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await DatabaseService.addTransaction(transaction);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(context),
              const SizedBox(height: AppConstants.spaceXL),
              Text(
                'Add Transaction',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppConstants.spaceL),
              _buildTypeSelector(),
              const SizedBox(height: AppConstants.spaceXL),
              NeumorphicTextField(
                controller: _amountController,
                hintText: 'Amount',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppConstants.spaceL),
              NeumorphicTextField(
                controller: _descriptionController,
                hintText: 'Description',
                prefixIcon: Icons.description_outlined,
              ),
              const SizedBox(height: AppConstants.spaceL),
              NeumorphicTextField(
                controller: _categoryController,
                hintText: 'Category',
                prefixIcon: Icons.category_outlined,
              ),
              const SizedBox(height: AppConstants.spaceL),
              NeumorphicTextField(
                controller: _dateController,
                hintText: 'Date',
                prefixIcon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: AppConstants.spaceXXXL),
              NeumorphicButton(
                isPrimary: true,
                onPressed: _saveTransaction,
                child: const Text(
                  'Save Transaction',
                  style: TextStyle(
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

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _type = TransactionType.EXPENSE),
            child: NeumorphicContainer(
              padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceM),
              isInset: _type == TransactionType.EXPENSE,
              child: Center(
                child: Text(
                  'Expense',
                  style: TextStyle(
                    color: _type == TransactionType.EXPENSE ? AppColors.expenseRed : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spaceL),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _type = TransactionType.INCOME),
            child: NeumorphicContainer(
              padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceM),
              isInset: _type == TransactionType.INCOME,
              child: Center(
                child: Text(
                  'Income',
                  style: TextStyle(
                    color: _type == TransactionType.INCOME ? AppColors.incomeGreen : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
}
