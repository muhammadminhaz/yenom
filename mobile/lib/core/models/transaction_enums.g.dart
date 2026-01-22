// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 2;

  @override
  TransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionType.INCOME;
      case 1:
        return TransactionType.EXPENSE;
      default:
        return TransactionType.INCOME;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    switch (obj) {
      case TransactionType.INCOME:
        writer.writeByte(0);
        break;
      case TransactionType.EXPENSE:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionStatusAdapter extends TypeAdapter<TransactionStatus> {
  @override
  final int typeId = 3;

  @override
  TransactionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionStatus.PENDING;
      case 1:
        return TransactionStatus.COMPLETED;
      case 2:
        return TransactionStatus.CANCELLED;
      default:
        return TransactionStatus.PENDING;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionStatus obj) {
    switch (obj) {
      case TransactionStatus.PENDING:
        writer.writeByte(0);
        break;
      case TransactionStatus.COMPLETED:
        writer.writeByte(1);
        break;
      case TransactionStatus.CANCELLED:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
