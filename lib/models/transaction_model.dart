import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { import, export }

class TransactionModel {
  final String id;
  final String productId;
  final String productName;
  final String categoryName;
  final int quantity;
  final double costPrice;
  final double sellingPrice;
  final TransactionType type;
  final DateTime date;
  final String userName; // บันทึกชื่อผู้ทำรายการ

  TransactionModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.quantity,
    required this.costPrice,
    required this.sellingPrice,
    required this.type,
    required this.date,
    this.userName = 'ไม่ระบุ',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'categoryName': categoryName,
      'quantity': quantity,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'userName': userName,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    DateTime parsedDate;
    if (map['date'] is Timestamp) {
      parsedDate = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      parsedDate = DateTime.tryParse(map['date']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return TransactionModel(
      id: docId ?? map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      categoryName: map['categoryName'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] == 'export' ? TransactionType.export : TransactionType.import,
      date: parsedDate,
      userName: map['userName'] ?? 'ไม่ระบุ',
    );
  }
}