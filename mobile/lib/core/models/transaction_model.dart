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

  /// False until this transaction has been uploaded to the cloud backend.
  /// Existing records read from an old Hive box default to false (unsynced).
  @HiveField(11)
  final bool isSynced;

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
    this.isSynced = false,
  });

  TransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    DateTime? transactionDate,
    String? description,
    String? category,
    TransactionType? type,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
