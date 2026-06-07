// GENERATED CODE - DO NOT MODIFY BY HAND
// Manually written to match suggestion_model.dart (typeId: 4, fields 0-14)

part of 'suggestion_model.dart';

class SuggestionModelAdapter extends TypeAdapter<SuggestionModel> {
  @override
  final int typeId = 4;

  @override
  SuggestionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SuggestionModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      source: fields[2] as String,
      rawMessage: fields[3] as String,
      amount: fields[4] as double?,
      currency: fields[5] as String?,
      transactionDate: fields[6] as DateTime?,
      description: fields[7] as String?,
      category: fields[8] as String?,
      type: fields[9] as String?,
      isHaram: fields[10] == null ? false : fields[10] as bool,
      haramReason: fields[11] as String?,
      aiConfidence: fields[12] as double?,
      status: fields[13] == null ? 'PENDING' : fields[13] as String,
      createdAt: fields[14] == null ? DateTime.now() : fields[14] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SuggestionModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.source)
      ..writeByte(3)
      ..write(obj.rawMessage)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.transactionDate)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.type)
      ..writeByte(10)
      ..write(obj.isHaram)
      ..writeByte(11)
      ..write(obj.haramReason)
      ..writeByte(12)
      ..write(obj.aiConfidence)
      ..writeByte(13)
      ..write(obj.status)
      ..writeByte(14)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
