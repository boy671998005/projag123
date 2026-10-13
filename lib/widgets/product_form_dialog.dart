import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';

class ProductFormDialog extends StatefulWidget {
  final ProductModel? product;
  final List<ProductModel> existingProducts;
  final List<String> categories;
  final Function(ProductModel) onSave;
  final Function(String)? onDelete;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.existingProducts,
    required this.categories,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _barcodeController;
  late TextEditingController _nameController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;

  String? _selectedCategory;
  String? _base64Image;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController(text: widget.product?.barcode ?? '');
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _costPriceController = TextEditingController(text: widget.product?.costPrice.toString() ?? '');
    _sellingPriceController = TextEditingController(text: widget.product?.sellingPrice.toString() ?? '');
    _quantityController = TextEditingController(text: widget.product?.quantity.toString() ?? '');
    _unitController = TextEditingController(text: widget.product?.unit ?? 'ชิ้น');

    _selectedCategory = widget.product?.categoryName ??
        (widget.categories.isNotEmpty ? widget.categories.first : 'ทั่วไป');
    _base64Image = widget.product?.imageUrl;
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  // เลือกรูปภาพจากอัลบั้ม พร้อมย่อขนาดสำหรับ Firestore (ทางเลือก B)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 70,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final barcode = _barcodeController.text.trim();
      final name = _nameController.text.trim();
      final costPrice = double.parse(_costPriceController.text.trim());
      final sellingPrice = double.parse(_sellingPriceController.text.trim());
      final quantity = int.parse(_quantityController.text.trim());
      final unit = _unitController.text.trim();

      // ตรวจสอบบาร์โค้ดซ้ำ (กรณีเพิ่มสินค้าใหม่)
      if (!_isEditing) {
        bool isDuplicate = widget.existingProducts.any((p) => p.barcode == barcode);
        if (isDuplicate) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บาร์โค้ดนี้มีอยู่ในระบบแล้ว'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }

      final newOrUpdatedProduct = ProductModel(
        productId: widget.product?.productId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        barcode: barcode,
        name: name,
        categoryName: _selectedCategory ?? 'ทั่วไป',
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        quantity: quantity,
        soldQuantity: widget.product?.soldQuantity ?? 0,
        minAlertQuantity: widget.product?.minAlertQuantity ?? 10,
        unit: unit,
        imageUrl: _base64Image,
      );

      widget.onSave(newOrUpdatedProduct);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _isEditing ? 'แก้ไขข้อมูลสินค้า' : 'เพิ่มสินค้าใหม่',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (_isEditing && widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'ลบสินค้า',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (confirmCtx) => AlertDialog(
                    title: const Text('ยืนยันการลบสินค้า'),
                    content: Text('คุณต้องการลบ "${widget.product!.name}" ออกจากระบบใช่หรือไม่?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(confirmCtx),
                        child: const Text('ยกเลิก'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () {
                          widget.onDelete!(widget.product!.productId);
                          Navigator.pop(confirmCtx);
                          Navigator.pop(context);
                        },
                        child: const Text('ลบ', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // กรอบพรีวิวรูปภาพ
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: _base64Image != null && _base64Image!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          base64Decode(_base64Image!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              // ปุ่มแนบรูป
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  side: const BorderSide(color: Colors.blueAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('แนบรูป'),
                onPressed: _pickImage,
              ),
              const SizedBox(height: 16),

              // ช่องกรอกบาร์โค้ด
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'บาร์โค้ด / รหัสสินค้า',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'กรุณากรอกบาร์โค้ด' : null,
              ),
              const SizedBox(height: 12),

              // ช่องกรอกชื่อสินค้า
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อสินค้า',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'กรุณากรอกชื่อสินค้า' : null,
              ),
              const SizedBox(height: 12),

              // ตัวเลือกหมวดหมู่
              DropdownButtonFormField<String>(
                initialValue: widget.categories.contains(_selectedCategory) ? _selectedCategory : null,
                decoration: const InputDecoration(
                  labelText: 'หมวดหมู่สินค้า',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: widget.categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                validator: (val) => val == null ? 'กรุณาเลือกหมวดหมู่' : null,
              ),
              const SizedBox(height: 12),

              // ราคาทุน และ ราคาขาย
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'ราคาทุน (บาท)',
                        border: OutlineInputBorder(),
                        prefixText: '฿ ',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'กรอกราคาทุน';
                        if (double.tryParse(val) == null) return 'ตัวเลขไม่ถูกต้อง';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'ราคาขาย (บาท)',
                        border: OutlineInputBorder(),
                        prefixText: '฿ ',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'กรอกราคาขาย';
                        if (double.tryParse(val) == null) return 'ตัวเลขไม่ถูกต้อง';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // จำนวนคงเหลือ และ หน่วยนับ
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'จำนวนคงเหลือ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'กรอกจำนวน';
                        if (int.tryParse(val) == null) return 'ตัวเลขไม่ถูกต้อง';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'หน่วยนับ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'กรอกหน่วยนับ' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _submitForm,
          child: Text(
            _isEditing ? 'บันทึกข้อมูล' : 'เพิ่มสินค้า',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}