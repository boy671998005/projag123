import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../widgets/product_form_dialog.dart';

class ImportManagementScreen extends StatefulWidget {
  final List<ProductModel> products;
  final List<String> categories;
  final EmployeeModel employee; // รับข้อมูลผู้ใช้ที่กำลังล็อกอิน
  final Function(ProductModel) onAddProduct;
  final Function(ProductModel) onUpdateProduct;
  final Function(TransactionModel) onAddTransaction;

  const ImportManagementScreen({
    super.key,
    required this.products,
    required this.categories,
    required this.employee,
    required this.onAddProduct,
    required this.onUpdateProduct,
    required this.onAddTransaction,
  });

  @override
  State<ImportManagementScreen> createState() => _ImportManagementScreenState();
}

class _ImportManagementScreenState extends State<ImportManagementScreen> {
  String? _selectedCategory;
  ProductModel? _selectedProduct;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _qtyController = TextEditingController(text: '1');

  final List<ImportCartItem> _importCart = [];

  void _addToCart() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกสินค้าที่จะรับเข้า')),
      );
      return;
    }

    int qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกจำนวนที่ถูกต้อง (มากกว่า 0)')),
      );
      return;
    }

    setState(() {
      int existingIndex = _importCart.indexWhere((item) => item.product.productId == _selectedProduct!.productId);
      if (existingIndex != -1) {
        _importCart[existingIndex].quantity += qty;
      } else {
        _importCart.add(ImportCartItem(product: _selectedProduct!, quantity: qty));
      }
      _qtyController.text = '1';
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (successCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(height: 12),
            Icon(Icons.check_circle_outline, color: Colors.teal, size: 70),
            SizedBox(height: 16),
            Text(
              'บันทึกเสร็จสิ้น',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'เติมสินค้าเข้าสู่สต็อกเรียบร้อยแล้ว',
              style: TextStyle(color: Colors.black54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(successCtx),
            child: const Text('ตกลง', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmImport() {
    if (_importCart.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการรับสินค้าเข้าสต็อก'),
        content: Text('วันที่ทำรายการ: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}\nจำนวน ${_importCart.length} รายการ ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              Navigator.pop(ctx);
              final int now = DateTime.now().millisecondsSinceEpoch;

              for (int i = 0; i < _importCart.length; i++) {
                final item = _importCart[i];
                item.product.quantity += item.quantity;
                widget.onUpdateProduct(item.product);

                // บันทึกชื่อผู้ใช้งานที่ทำการรับเข้าสินค้าลง Firestore
                widget.onAddTransaction(
                  TransactionModel(
                    id: '${now}_${item.product.productId}_$i',
                    productId: item.product.productId,
                    productName: item.product.name,
                    categoryName: item.product.categoryName,
                    quantity: item.quantity,
                    costPrice: item.product.costPrice,
                    sellingPrice: item.product.sellingPrice,
                    type: TransactionType.import,
                    date: _selectedDate,
                    userName: widget.employee.name,
                  ),
                );
              }

              setState(() {
                _importCart.clear();
                _selectedCategory = 'ทั้งหมด';
                _selectedProduct = null;
                _qtyController.text = '1';
              });

              Future.delayed(const Duration(milliseconds: 150), () {
                if (mounted) {
                  _showSuccessDialog();
                }
              });
            },
            child: const Text('ยืนยันรับเข้า', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addNewProduct() {
    showDialog(
      context: context,
      builder: (_) => ProductFormDialog(
        existingProducts: widget.products,
        categories: widget.categories,
        onSave: (newProduct) {
          widget.onAddProduct(newProduct);
          setState(() {
            _selectedCategory = newProduct.categoryName;
            _selectedProduct = newProduct;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;

    List<ProductModel> filteredProducts = widget.products.where((p) {
      if (_selectedCategory == null || _selectedCategory == 'ทั้งหมด') return true;
      return p.categoryName == _selectedCategory;
    }).toList();

    double cartTotalCost = _importCart.fold(0, (sum, item) => sum + (item.product.costPrice * item.quantity));

    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        isMobile ? 12 : 16,
        isMobile ? 12 : 24,
        isMobile ? 12 : 24,
      ),
      color: Colors.grey[100],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รายการรับเข้าสินค้า',
                  style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text('วันที่: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      icon: const Icon(Icons.add_box_outlined, color: Colors.white),
                      label: const Text('เพิ่มสินค้าใหม่', style: TextStyle(color: Colors.white)),
                      onPressed: _addNewProduct,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ทำรายการรับสินค้าเข้าสต็อก',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    const SizedBox(height: 16),
                    
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool stackVertically = constraints.maxWidth < 750;
                        return stackVertically
                            ? Column(
                                children: [
                                  _buildCategoryDropdown(),
                                  const SizedBox(height: 12),
                                  _buildProductDropdown(filteredProducts),
                                  const SizedBox(height: 12),
                                  _buildQuantityInput(),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: _buildAddButton(),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(flex: 2, child: _buildCategoryDropdown()),
                                  const SizedBox(width: 12),
                                  Expanded(flex: 3, child: _buildProductDropdown(filteredProducts)),
                                  const SizedBox(width: 12),
                                  Expanded(flex: 2, child: _buildQuantityInput()),
                                  const SizedBox(width: 12),
                                  _buildAddButton(),
                                ],
                              );
                      },
                    ),

                    if (_importCart.isNotEmpty) ...[
                      const Divider(height: 30),
                      const Text('รายการเตรียมรับเข้า (รอการบันทึก)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _importCart.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final item = _importCart[idx];
                          double itemTotalCost = item.product.costPrice * item.quantity;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('หมวด: ${item.product.categoryName} | ราคาทุน: ฿${item.product.costPrice.toStringAsFixed(2)} x ${item.quantity} ${item.product.unit}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('฿${itemTotalCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal)),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      _importCart.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('รวมรายการรับเข้า ${_importCart.length} รายการ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('ราคาทุนรวม ฿${cartTotalCost.toStringAsFixed(2)}', style: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                          label: const Text('ยืนยันการรับสินค้าเข้าสต็อก', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          onPressed: _confirmImport,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    List<String> categoryOptions = ['ทั้งหมด', ...widget.categories];
    String currentCategory = categoryOptions.contains(_selectedCategory) ? _selectedCategory! : 'ทั้งหมด';

    return DropdownButtonFormField<String>(
      value: currentCategory,
      decoration: const InputDecoration(
        labelText: 'เลือกหมวดหมู่',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: categoryOptions.map((cat) {
        return DropdownMenuItem<String>(value: cat, child: Text(cat));
      }).toList(),
      onChanged: (val) {
        setState(() {
          _selectedCategory = val;
          _selectedProduct = null;
        });
      },
    );
  }

  Widget _buildProductDropdown(List<ProductModel> filteredProducts) {
    ProductModel? currentProduct = filteredProducts.contains(_selectedProduct) ? _selectedProduct : null;

    return DropdownButtonFormField<ProductModel>(
      value: currentProduct,
      decoration: const InputDecoration(
        labelText: 'เลือกสินค้าที่จะรับเข้า',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.shopping_bag_outlined),
      ),
      items: filteredProducts.map((p) {
        return DropdownMenuItem<ProductModel>(
          value: p,
          child: Text('${p.name} (ปัจจุบันคงเหลือ: ${p.quantity} ${p.unit})'),
        );
      }).toList(),
      onChanged: (val) {
        setState(() => _selectedProduct = val);
      },
    );
  }

  Widget _buildQuantityInput() {
    return TextField(
      controller: _qtyController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'จำนวนรับเข้า',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.numbers),
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
      label: const Text('เพิ่มเข้ารายการ', style: TextStyle(color: Colors.white, fontSize: 15)),
      onPressed: _addToCart,
    );
  }
}

class ImportCartItem {
  final ProductModel product;
  int quantity;

  ImportCartItem({required this.product, required this.quantity});
}