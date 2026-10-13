import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../models/employee_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection References
  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _db.collection('products');
  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _db.collection('categories');
  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _db.collection('transactions');
  // ชี้ไปยัง collection 'users' ให้ตรงกับ auth_screen.dart และ Firestore จริง
  CollectionReference<Map<String, dynamic>> get _employeesRef =>
      _db.collection('users');

  // ==========================================
  // หมวดหมู่ (Categories)
  // ==========================================
  Stream<List<CategoryModel>> getCategoriesStream() {
    return _categoriesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> saveCategory(CategoryModel category) async {
    await _categoriesRef.doc(category.id).set(category.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesRef.doc(categoryId).delete();
  }

  // ==========================================
  // สินค้า (Products)
  // ==========================================
  Stream<List<ProductModel>> getProductsStream() {
    return _productsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> saveProduct(ProductModel product) async {
    await _productsRef.doc(product.productId).set(product.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteProduct(String productId) async {
    await _productsRef.doc(productId).delete();
  }

  Future<void> adjustStock(String productId, int amount) async {
    await _productsRef.doc(productId).update({
      'quantity': FieldValue.increment(amount),
    });
  }

  // ==========================================
  // ประวัติรับเข้า-ส่งออก (Transactions)
  // ==========================================
  Stream<List<TransactionModel>> getTransactionsStream() {
    return _transactionsRef
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> saveTransaction(TransactionModel transaction) async {
    await _transactionsRef.doc(transaction.id).set(transaction.toMap(), SetOptions(merge: true));
  }

  // ==========================================
  // จัดการผู้ใช้งาน / พนักงาน (Users Collection)
  // ==========================================
  Stream<List<EmployeeModel>> getEmployeesStream() {
    return _employeesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return EmployeeModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> saveEmployee(EmployeeModel employee) async {
    await _employeesRef.doc(employee.id).set(employee.toMap(), SetOptions(merge: true));
  }

  Future<void> updateEmployeeStatus(String employeeId, bool isActive) async {
    await _employeesRef.doc(employeeId).update({'isActive': isActive});
  }

  Future<void> deleteEmployee(String employeeId) async {
    await _employeesRef.doc(employeeId).delete();
  }
}