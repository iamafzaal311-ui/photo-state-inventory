// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SaleItemModelAdapter extends TypeAdapter<SaleItemModel> {
  @override
  final int typeId = 2;

  @override
  SaleItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleItemModel(
      productId: fields[0] as String,
      productName: fields[1] as String,
      quantity: fields[2] as double,
      unitPrice: fields[3] as double,
      unit: fields[4] as String,
      customDetails: (fields[5] as Map?)?.cast<String, String>() ?? {},
    );
  }

  @override
  void write(BinaryWriter writer, SaleItemModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unitPrice)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.customDetails);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SaleModelAdapter extends TypeAdapter<SaleModel> {
  @override
  final int typeId = 3;

  @override
  SaleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleModel(
      id: fields[0] as String,
      items: (fields[1] as List).cast<SaleItemModel>(),
      totalAmount: fields[2] as double,
      discount: fields[3] as double,
      amountPaid: fields[4] as double,
      saleDate: fields[5] as DateTime,
      soldBy: fields[6] as String,
      paymentMethod: fields[7] as String,
      notes: fields[8] as String,
      orderNumber: fields[9] as String? ?? '',
      orderStatus: fields[10] as String? ?? 'Completed',
      estimatedDelivery: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SaleModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.items)
      ..writeByte(2)
      ..write(obj.totalAmount)
      ..writeByte(3)
      ..write(obj.discount)
      ..writeByte(4)
      ..write(obj.amountPaid)
      ..writeByte(5)
      ..write(obj.saleDate)
      ..writeByte(6)
      ..write(obj.soldBy)
      ..writeByte(7)
      ..write(obj.paymentMethod)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.orderNumber)
      ..writeByte(10)
      ..write(obj.orderStatus)
      ..writeByte(11)
      ..write(obj.estimatedDelivery);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
