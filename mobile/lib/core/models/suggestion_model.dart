import 'package:hive/hive.dart';

part 'suggestion_model.g.dart';

@HiveType(typeId: 4)
class SuggestionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String source; // 'GMAIL' or 'SMS'

  @HiveField(3)
  final String rawMessage;

  @HiveField(4)
  final double? amount;

  @HiveField(5)
  final String? currency;

  @HiveField(6)
  final DateTime? transactionDate;

  @HiveField(7)
  final String? description;

  @HiveField(8)
  final String? category;

  @HiveField(9)
  final String? type; // 'INCOME' or 'EXPENSE'

  @HiveField(10)
  final bool isHaram;

  @HiveField(11)
  final String? haramReason;

  @HiveField(12)
  final double? aiConfidence;

  @HiveField(13)
  final String status; // 'PENDING', 'ACCEPTED', 'REJECTED'

  @HiveField(14)
  final DateTime createdAt;

  SuggestionModel({
    required this.id,
    required this.userId,
    required this.source,
    required this.rawMessage,
    this.amount,
    this.currency,
    this.transactionDate,
    this.description,
    this.category,
    this.type,
    this.isHaram = false,
    this.haramReason,
    this.aiConfidence,
    this.status = 'PENDING',
    required this.createdAt,
  });

  factory SuggestionModel.fromJson(Map<String, dynamic> json) {
    return SuggestionModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      source: json['source'] as String? ?? 'SMS',
      rawMessage: json['rawMessage'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      transactionDate: json['transactionDate'] != null
          ? DateTime.tryParse(json['transactionDate'] as String)
          : null,
      description: json['description'] as String?,
      category: json['category'] as String?,
      type: json['type'] as String?,
      isHaram: json['isHaram'] as bool? ?? false,
      haramReason: json['haramReason'] as String?,
      aiConfidence: (json['aiConfidence'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isExpense => type == 'EXPENSE';
}
