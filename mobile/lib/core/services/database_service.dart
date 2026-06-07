import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/transaction_enums.dart';
import '../models/suggestion_model.dart';
import '../utils/app_logger.dart';

class DatabaseService {
  static const String _tag = 'DatabaseService';
  static const String userBoxName = 'userBox';
  static const String transactionBoxName = 'transactionBox';
  static const String suggestionBoxName = 'suggestionBox';

  static Future<void> init() async {
    AppLogger.i(_tag, 'Initializing Hive database');
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
      AppLogger.d(_tag, 'Registered UserModelAdapter');
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionModelAdapter());
      AppLogger.d(_tag, 'Registered TransactionModelAdapter');
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TransactionTypeAdapter());
      AppLogger.d(_tag, 'Registered TransactionTypeAdapter');
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TransactionStatusAdapter());
      AppLogger.d(_tag, 'Registered TransactionStatusAdapter');
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SuggestionModelAdapter());
      AppLogger.d(_tag, 'Registered SuggestionModelAdapter');
    }

    await Hive.openBox<UserModel>(userBoxName);
    await Hive.openBox<TransactionModel>(transactionBoxName);
    await Hive.openBox<SuggestionModel>(suggestionBoxName);
    AppLogger.i(_tag, 'Hive boxes opened successfully');
  }

  // ── User ──────────────────────────────────────────────────────────────────

  static Box<UserModel> getUserBox() => Hive.box<UserModel>(userBoxName);

  static Future<void> saveUser(UserModel user) async {
    AppLogger.i(_tag, 'Saving user: ${user.username}');
    await getUserBox().put('currentUser', user);
    AppLogger.d(_tag, 'User saved successfully');
  }

  static UserModel? getCurrentUser() {
    final user = getUserBox().get('currentUser');
    if (user == null) {
      AppLogger.w(_tag, 'getCurrentUser: no user found in box');
    }
    return user;
  }

  static Future<void> clearUser() async {
    AppLogger.i(_tag, 'Clearing current user session');
    await getUserBox().delete('currentUser');
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  static Box<TransactionModel> getTransactionBox() =>
      Hive.box<TransactionModel>(transactionBoxName);

  static Future<void> addTransaction(TransactionModel transaction) async {
    AppLogger.i(_tag, 'Adding transaction: ${transaction.description} — ${transaction.currency}${transaction.amount}');
    await getTransactionBox().add(transaction);
    AppLogger.d(_tag, 'Transaction added with id: ${transaction.id}');
  }

  static List<TransactionModel> getAllTransactions() {
    final txs = getTransactionBox().values.toList();
    AppLogger.d(_tag, 'getAllTransactions: returned ${txs.length} records');
    return txs;
  }

  static TransactionModel? getTransactionById(String id) {
    try {
      final tx = getTransactionBox().values.firstWhere((t) => t.id == id);
      AppLogger.d(_tag, 'getTransactionById($id): found');
      return tx;
    } catch (_) {
      AppLogger.w(_tag, 'getTransactionById($id): not found');
      return null;
    }
  }

  static Future<void> updateTransactionById(String id, TransactionModel updated) async {
    AppLogger.i(_tag, 'Updating transaction id: $id');
    final box = getTransactionBox();
    dynamic key;
    for (final k in box.keys) {
      if (box.get(k)?.id == id) {
        key = k;
        break;
      }
    }
    if (key != null) {
      await box.put(key, updated);
      AppLogger.d(_tag, 'Transaction updated successfully');
    } else {
      AppLogger.e(_tag, 'updateTransactionById: id $id not found');
    }
  }

  static Future<void> deleteTransactionById(String id) async {
    AppLogger.i(_tag, 'Deleting transaction id: $id');
    final box = getTransactionBox();
    dynamic key;
    for (final k in box.keys) {
      if (box.get(k)?.id == id) {
        key = k;
        break;
      }
    }
    if (key != null) {
      await box.delete(key);
      AppLogger.d(_tag, 'Transaction deleted successfully');
    } else {
      AppLogger.e(_tag, 'deleteTransactionById: id $id not found');
    }
  }

  // Kept for backwards-compat with existing index-based callers
  static Future<void> deleteTransaction(int index) async {
    AppLogger.i(_tag, 'Deleting transaction at index: $index');
    await getTransactionBox().deleteAt(index);
  }

  static Future<void> updateTransaction(int index, TransactionModel transaction) async {
    AppLogger.i(_tag, 'Updating transaction at index: $index');
    await getTransactionBox().putAt(index, transaction);
  }

  // ── Query helpers ─────────────────────────────────────────────────────────

  static List<TransactionModel> getTransactionsByType(TransactionType type) {
    final result = getTransactionBox().values.where((t) => t.type == type).toList();
    AppLogger.d(_tag, 'getTransactionsByType($type): ${result.length} results');
    return result;
  }

  static List<TransactionModel> getTransactionsForMonth(int year, int month) {
    final result = getTransactionBox().values.where((t) {
      return t.transactionDate.year == year && t.transactionDate.month == month;
    }).toList();
    AppLogger.d(_tag, 'getTransactionsForMonth($year-$month): ${result.length} results');
    return result;
  }

  /// Returns every transaction that has not yet been uploaded to the cloud.
  static List<TransactionModel> getUnsyncedTransactions() {
    final result = getTransactionBox().values.where((t) => !t.isSynced).toList();
    AppLogger.d(_tag, 'getUnsyncedTransactions: ${result.length} unsynced');
    return result;
  }

  /// Marks a transaction as synced (isSynced = true) by id.
  static Future<void> markAsSynced(String id) async {
    AppLogger.d(_tag, 'markAsSynced: $id');
    final tx = getTransactionById(id);
    if (tx != null) {
      await updateTransactionById(id, tx.copyWith(isSynced: true));
    } else {
      AppLogger.w(_tag, 'markAsSynced: id $id not found');
    }
  }

  // ── Suggestions ───────────────────────────────────────────────────────────

  static Box<SuggestionModel> getSuggestionBox() =>
      Hive.box<SuggestionModel>(suggestionBoxName);

  static Future<void> saveSuggestion(SuggestionModel suggestion) async {
    AppLogger.i(_tag, 'Saving suggestion: ${suggestion.id} source=${suggestion.source}');
    await getSuggestionBox().put(suggestion.id, suggestion);
  }

  static List<SuggestionModel> getPendingSuggestions() {
    final result = getSuggestionBox()
        .values
        .where((s) => s.status == 'PENDING')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    AppLogger.d(_tag, 'getPendingSuggestions: ${result.length} pending');
    return result;
  }

  static Future<void> removeSuggestion(String id) async {
    AppLogger.i(_tag, 'Removing suggestion: $id');
    await getSuggestionBox().delete(id);
  }

  static Future<void> clearSuggestions() async {
    AppLogger.i(_tag, 'Clearing all suggestions');
    await getSuggestionBox().clear();
  }

  // ── Category totals ────────────────────────────────────────────────────────

  static Map<String, double> getCategoryTotals({TransactionType? type}) {
    final Map<String, double> totals = {};
    for (final tx in getTransactionBox().values) {
      if (type != null && tx.type != type) continue;
      final cat = tx.category ?? 'Other';
      totals[cat] = (totals[cat] ?? 0) + tx.amount;
    }
    AppLogger.d(_tag, 'getCategoryTotals: ${totals.length} categories');
    return totals;
  }
}
