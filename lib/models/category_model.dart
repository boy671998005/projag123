class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl; // เก็บรูปภาพเป็น Base64 String

  CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  // แปลงจาก Object เป็น Map เพื่อบันทึกลง Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
    };
  }

  // แปลงจาก Map ของ Firestore กลับมาเป็น Object
  factory CategoryModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return CategoryModel(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }
}