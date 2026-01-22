import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/transaction_enums.dart';

class DatabaseService {
  static const String userBoxName = 'userBox';
  static const String transactionBoxName = 'transactionBox';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TransactionModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TransactionTypeAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(TransactionStatusAdapter());

    // Open Boxes
    await Hive.openBox<UserModel>(userBoxName);
    await Hive.openBox<TransactionModel>(transactionBoxName);
  }

  // User Methods
  static Box<UserModel> getUserBox() => Hive.box<UserModel>(userBoxName);
  
  static Future<void> saveUser(UserModel user) async {
    await getUserBox().put('currentUser', user);
  }

  static UserModel? getCurrentUser() {
    return getUserBox().get('currentUser');
  }

  static Future<void> clearUser() async {
    await getUserBox().delete('currentUser');
  }

  // Transaction Methods
  static Box<TransactionModel> getTransactionBox() => Hive.box<TransactionModel>(transactionBoxName);

  static Future<void> addTransaction(TransactionModel transaction) async {
    await getTransactionBox().add(transaction);
  }

  static List<TransactionModel> getAllTransactions() {
    return getTransactionBox().values.toList();
  }

  static Future<void> deleteTransaction(int index) async {
    await getTransactionBox().deleteAt(index);
  }

  static Future<void> updateTransaction(int index, TransactionModel transaction) async {
    await getTransactionBox().putAt(index, transaction);
  }
}
