class ProductModel {
  final String productId;
  final String barcode;
  final String name;
  final String categoryName;
  final double costPrice;
  final double sellingPrice;
  int quantity;
  int soldQuantity;
  final int minAlertQuantity;
  final String unit;
  String? imageUrl;

  ProductModel({
    required this.productId,
    required this.barcode,
    required this.name,
    required this.categoryName,
    required this.costPrice,
    required this.sellingPrice,
    required this.quantity,
    this.soldQuantity = 0,
    required this.minAlertQuantity,
    required this.unit,
    this.imageUrl,
  });

  // สินค้าหมดสต็อก (จำนวนเท่ากับหรือน้อยกว่า 0)
  bool get isOutOfStock => quantity <= 0;

  // สินค้าใกล้หมด (ต้องมากกว่า 0 และไม่เกินจำนวนเตือน)
  bool get isLowStock => quantity > 0 && quantity <= minAlertQuantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'barcode': barcode,
      'name': name,
      'categoryName': categoryName,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'soldQuantity': soldQuantity,
      'minAlertQuantity': minAlertQuantity,
      'unit': unit,
      'imageUrl': imageUrl,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return ProductModel(
      productId: docId ?? map['productId'] ?? '',
      barcode: map['barcode'] ?? '',
      name: map['name'] ?? '',
      categoryName: map['categoryName'] ?? 'ทั่วไป',
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      soldQuantity: (map['soldQuantity'] as num?)?.toInt() ?? 0,
      minAlertQuantity: (map['minAlertQuantity'] as num?)?.toInt() ?? 10,
      unit: map['unit'] ?? 'ชิ้น',
      imageUrl: map['imageUrl'],
    );
  }
}