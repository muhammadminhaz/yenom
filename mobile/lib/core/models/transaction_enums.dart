import 'package:hive/hive.dart';

part 'transaction_enums.g.dart';

@HiveType(typeId: 2)
enum TransactionType {
  @HiveField(0)
  INCOME,
  @HiveField(1)
  EXPENSE,
}

@HiveType(typeId: 3)
enum TransactionStatus {
  @HiveField(0)
  PENDING,
  @HiveField(1)
  COMPLETED,
  @HiveField(2)
  CANCELLED,
}
