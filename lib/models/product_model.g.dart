// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 1;

  @override
  ProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductModel(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      costPrice: fields[3] as double,
      sellingPrice: fields[4] as double,
      stockQuantity: fields[5] as double,
      unit: fields[6] as String,
      lowStockThreshold: fields[7] as double,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      description: fields[10] as String,
      sampleImages: (fields[11] as List).cast<String>(),
      customFields: (fields[12] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.costPrice)
      ..writeByte(4)
      ..write(obj.sellingPrice)
      ..writeByte(5)
      ..write(obj.stockQuantity)
      ..writeByte(6)
      ..write(obj.unit)
      ..writeByte(7)
      ..write(obj.lowStockThreshold)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.sampleImages)
      ..writeByte(12)
      ..write(obj.customFields);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
