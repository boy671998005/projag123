import 'dart:async';
import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/firestore_service.dart';
import '../widgets/sidebar_widget.dart';
import 'stock_management_screen.dart';
import 'category_management_screen.dart';
import 'import_management_screen.dart';
import 'export_management_screen.dart';
import 'summary_report_screen.dart';
import 'user_management_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  final EmployeeModel employee;

  const MainLayoutScreen({super.key, required this.employee});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isSidebarExpanded = true;
  int _selectedMenuIndex = 0;
  bool _isLoading = true;

  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  List<TransactionModel> _transactions = [];

  StreamSubscription? _categorySub;
  StreamSubscription? _productSub;
  StreamSubscription? _transactionSub;

  @override
  void initState() {
    super.initState();
    _subscribeToFirestore();
  }

  void _subscribeToFirestore() {
    _categorySub = _firestoreService.getCategoriesStream().listen((cats) {
      if (mounted) setState(() => _categories = cats);
    });

    _productSub = _firestoreService.getProductsStream().listen((prods) {
      if (mounted) setState(() => _products = prods);
    });

    _transactionSub = _firestoreService.getTransactionsStream().listen((txs) {
      if (mounted) {
        setState(() {
          _transactions = txs;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _categorySub?.cancel();
    _productSub?.cancel();
    _transactionSub?.cancel();
    super.dispose();
  }

  List<String> get _categoryNames {
    if (_categories.isEmpty) return ['ทั่วไป'];
    return _categories.map((c) => c.name).toList();
  }

  bool get _isAdmin => widget.employee.role == EmployeeRole.admin;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    Widget currentBody;

    if (_isLoading && _products.isEmpty && _categories.isEmpty) {
      currentBody = const Center(child: CircularProgressIndicator());
    } else {
      switch (_selectedMenuIndex) {
        case 0:
          currentBody = StockManagementScreen(
            products: _products,
            categories: _categoryNames,
            onAddProduct: (newP) async => await _firestoreService.saveProduct(newP),
            onUpdateProduct: (updatedP) async => await _firestoreService.saveProduct(updatedP),
            onDeleteProduct: (productId) async => await _firestoreService.deleteProduct(productId),
          );
          break;
        case 1:
          // ส่งต่อข้อมูล employee เข้าหน้า ImportManagementScreen
          currentBody = ImportManagementScreen(
            products: _products,
            categories: _categoryNames,
            employee: widget.employee,
            onAddProduct: (newP) async => await _firestoreService.saveProduct(newP),
            onUpdateProduct: (updatedP) async => await _firestoreService.saveProduct(updatedP),
            onAddTransaction: (t) async => await _firestoreService.saveTransaction(t),
          );
          break;
        case 2:
          currentBody = ExportManagementScreen(
            products: _products,
            categories: _categoryNames,
            employee: widget.employee,
            onUpdateProduct: (updatedP) async => await _firestoreService.saveProduct(updatedP),
            onAddTransaction: (t) async => await _firestoreService.saveTransaction(t),
          );
          break;
        case 3:
          currentBody = SummaryReportScreen(
            products: _products,
            transactions: _transactions,
          );
          break;
        case 4:
          currentBody = CategoryManagementScreen(
            categories: _categories,
            onAddCategory: (newCat) async => await _firestoreService.saveCategory(newCat),
            onUpdateCategory: (updatedCat) async => await _firestoreService.saveCategory(updatedCat),
            onDeleteCategory: (catId) async => await _firestoreService.deleteCategory(catId),
          );
          break;
        case 5:
          currentBody = _isAdmin
              ? const UserManagementScreen()
              : const Center(
                  child: Text(
                    'คุณไม่มีสิทธิ์เข้าถึงหน้านี้',
                    style: TextStyle(fontSize: 18),
                  ),
                );
          break;
        default:
          currentBody = Container();
      }
    }

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: const Text('ระบบจัดการสต็อกสินค้า'),
              backgroundColor: const Color(0xFF1E293B),
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: SidebarWidget(
                isExpanded: true,
                isMobile: true,
                employee: widget.employee,
                selectedIndex: _selectedMenuIndex,
                onMenuSelected: (index) {
                  setState(() => _selectedMenuIndex = index);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            SidebarWidget(
              isExpanded: _isSidebarExpanded,
              isMobile: false,
              employee: widget.employee,
              selectedIndex: _selectedMenuIndex,
              onMenuSelected: (index) => setState(() => _selectedMenuIndex = index),
              onToggle: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
            ),
          Expanded(child: currentBody),
        ],
      ),
    );
  }
}