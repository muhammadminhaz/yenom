import 'package:flutter/material.dart';

class CategoryItem {
  final String value;
  final String label;
  final IconData icon;
  final bool isIslamic;

  const CategoryItem({
    required this.value,
    required this.label,
    required this.icon,
    this.isIslamic = false,
  });
}

class CurrencyItem {
  final String code;
  final String symbol;
  final String name;

  const CurrencyItem({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

class AppCategories {
  static const List<CategoryItem> expenseCategories = [
    CategoryItem(value: 'Food & Dining', label: 'Food & Dining', icon: Icons.restaurant_outlined),
    CategoryItem(value: 'Transport', label: 'Transport', icon: Icons.directions_car_outlined),
    CategoryItem(value: 'Shopping', label: 'Shopping', icon: Icons.shopping_bag_outlined),
    CategoryItem(value: 'Bills & Utilities', label: 'Bills & Utilities', icon: Icons.receipt_long_outlined),
    CategoryItem(value: 'Healthcare', label: 'Healthcare', icon: Icons.local_hospital_outlined),
    CategoryItem(value: 'Education', label: 'Education', icon: Icons.school_outlined),
    CategoryItem(value: 'Housing & Rent', label: 'Housing & Rent', icon: Icons.home_outlined),
    CategoryItem(value: 'Entertainment', label: 'Entertainment', icon: Icons.movie_outlined),
    CategoryItem(value: 'Other', label: 'Other', icon: Icons.more_horiz),
  ];

  static const List<CategoryItem> islamicCategories = [
    CategoryItem(value: 'Sadaqah', label: 'Sadaqah', icon: Icons.favorite_outline, isIslamic: true),
    CategoryItem(value: 'Zakat', label: 'Zakat', icon: Icons.volunteer_activism_outlined, isIslamic: true),
    CategoryItem(value: 'Fitrana', label: 'Fitrana', icon: Icons.wb_sunny_outlined, isIslamic: true),
  ];

  static const List<CategoryItem> incomeCategories = [
    CategoryItem(value: 'Salary', label: 'Salary', icon: Icons.account_balance_wallet_outlined),
    CategoryItem(value: 'Business', label: 'Business', icon: Icons.business_center_outlined),
    CategoryItem(value: 'Freelance', label: 'Freelance', icon: Icons.laptop_outlined),
    CategoryItem(value: 'Investment', label: 'Investment (Halal)', icon: Icons.trending_up),
    CategoryItem(value: 'Gift', label: 'Gift', icon: Icons.card_giftcard_outlined),
    CategoryItem(value: 'Other Income', label: 'Other Income', icon: Icons.more_horiz),
  ];

  static const List<CurrencyItem> currencies = [
    CurrencyItem(code: 'USD', symbol: '\$', name: 'US Dollar'),
    CurrencyItem(code: 'BDT', symbol: '৳', name: 'Bangladeshi Taka'),
    CurrencyItem(code: 'GBP', symbol: '£', name: 'British Pound'),
    CurrencyItem(code: 'EUR', symbol: '€', name: 'Euro'),
    CurrencyItem(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal'),
    CurrencyItem(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham'),
    CurrencyItem(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
    CurrencyItem(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
    CurrencyItem(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    CurrencyItem(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
  ];

  static bool isIslamic(String? category) =>
      islamicCategories.any((c) => c.value == category);

  static IconData iconFor(String? category) {
    if (category == null) return Icons.category_outlined;
    for (final c in [...expenseCategories, ...incomeCategories, ...islamicCategories]) {
      if (c.value == category) return c.icon;
    }
    return Icons.category_outlined;
  }

  static String symbolFor(String currencyCode) {
    return currencies
        .firstWhere(
          (c) => c.code == currencyCode,
          orElse: () => const CurrencyItem(code: 'USD', symbol: '\$', name: 'US Dollar'),
        )
        .symbol;
  }

  // Returns expense + Islamic for EXPENSE type, income-only for INCOME type
  static List<CategoryItem> forTransactionType(bool isExpense) {
    if (isExpense) return [...expenseCategories, ...islamicCategories];
    return incomeCategories;
  }
}
