import 'package:hive/hive.dart';
import 'transaction_enums.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 1)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String currency;

  @HiveField(4)
  final DateTime transactionDate;

  @HiveField(5)
  final String description;

  @HiveField(6)
  final String? category;

  @HiveField(7)
  final TransactionType type;

  @HiveField(8)
  final TransactionStatus status;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.transactionDate,
    required this.description,
    this.category,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
}
