import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../widgets/product_form_dialog.dart';

class StockManagementScreen extends StatefulWidget {
  final List<ProductModel> products;
  final List<String> categories;
  final Function(ProductModel) onAddProduct;
  final Function(ProductModel) onUpdateProduct;
  final Function(String) onDeleteProduct;

  const StockManagementScreen({
    super.key,
    required this.products,
    required this.categories,
    required this.onAddProduct,
    required this.onUpdateProduct,
    required this.onDeleteProduct,
  });

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  String _searchQuery = '';
  String _selectedCategoryFilter = 'ทั้งหมด';
  String _sortOption = 'qty_desc';

  // ป้ายแสดงสถานะสต็อก (หมดแล้ว / ใกล้หมด / ปกติ)
  Widget _buildStatusBadge(ProductModel product, {bool isMobile = false}) {
    final bool isOutOfStock = product.quantity <= 0;
    final bool isLowStock = product.quantity > 0 && product.quantity <= product.minAlertQuantity;

    Color bgColor;
    Color textColor;
    String label;

    if (isOutOfStock) {
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
      label = 'หมดแล้ว';
    } else if (isLowStock) {
      bgColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
      label = 'ใกล้หมด';
    } else {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
      label = 'ปกติ';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: isMobile ? 11 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showProductDetails(ProductModel product) {
    String statusText;
    Color statusColor;

    if (product.quantity <= 0) {
      statusText = 'หมดแล้ว';
      statusColor = Colors.red.shade800;
    } else if (product.quantity <= product.minAlertQuantity) {
      statusText = 'ใกล้หมด';
      statusColor = Colors.orange.shade800;
    } else {
      statusText = 'ปกติ';
      statusColor = Colors.green.shade800;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('รายละเอียดสินค้า'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            base64Decode(product.imageUrl!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.image_not_supported_outlined,
                          size: 70,
                          color: Colors.grey,
                        ),
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow('บาร์โค้ด / รหัสสินค้า:', product.barcode),
              _buildDetailRow('ชื่อสินค้า:', product.name, isBold: true),
              _buildDetailRow('หมวดหมู่:', product.categoryName),
              _buildDetailRow(
                'ราคาทุน:',
                '฿${product.costPrice.toStringAsFixed(2)}',
              ),
              _buildDetailRow(
                'ราคาขาย:',
                '฿${product.sellingPrice.toStringAsFixed(2)}',
                valueColor: Colors.blueAccent,
              ),
              _buildDetailRow(
                'จำนวนคงเหลือ:',
                '${product.quantity} ${product.unit}',
              ),
              _buildDetailRow(
                'สถานะสต็อก:',
                statusText,
                valueColor: statusColor,
                isBold: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    List<ProductModel> filteredProducts = widget.products.where((p) {
      bool matchesSearch =
          p.name.toLowerCase().contains(_searchQuery) ||
          p.barcode.toLowerCase().contains(_searchQuery);
      bool matchesCategory =
          _selectedCategoryFilter == 'ทั้งหมด' ||
          p.categoryName == _selectedCategoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();

    if (_sortOption == 'qty_desc') {
      filteredProducts.sort(
        (a, b) => b.quantity.compareTo(a.quantity),
      );
    } else if (_sortOption == 'qty_asc') {
      filteredProducts.sort(
        (a, b) => a.quantity.compareTo(b.quantity),
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'ระบบนับและจัดการสต็อก',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'เพิ่มสินค้าใหม่',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ProductFormDialog(
                        existingProducts: widget.products,
                        categories: widget.categories,
                        onSave: widget.onAddProduct,
                      ),
                    );
                  },
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'ระบบนับและจัดการสต็อกสินค้า',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'เพิ่มสินค้าใหม่',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ProductFormDialog(
                        existingProducts: widget.products,
                        categories: widget.categories,
                        onSave: widget.onAddProduct,
                      ),
                    );
                  },
                ),
              ],
            ),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              bool isCompact = constraints.maxWidth < 750;
              return isCompact
                  ? Column(
                      children: [
                        _buildSearchField(),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _buildCategoryFilterDropdown()),
                            const SizedBox(width: 10),
                            Expanded(child: _buildSortDropdown()),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 3, child: _buildSearchField()),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildCategoryFilterDropdown(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: _buildSortDropdown()),
                      ],
                    );
            },
          ),
          const SizedBox(height: 16),

          Expanded(
            child: isMobile
                ? _buildMobileListView(filteredProducts)
                : _buildDesktopTableView(filteredProducts),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'ค้นหาด้วย ชื่อสินค้า หรือ บาร์โค้ด...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
    );
  }

  Widget _buildCategoryFilterDropdown() {
    List<String> categoryOptions = ['ทั้งหมด', ...widget.categories];
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: categoryOptions.contains(_selectedCategoryFilter)
          ? _selectedCategoryFilter
          : 'ทั้งหมด',
      decoration: InputDecoration(
        labelText: 'หมวดหมู่',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.category_outlined),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      items: categoryOptions.map((cat) {
        return DropdownMenuItem(value: cat, child: Text(cat));
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedCategoryFilter = val);
      },
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _sortOption,
      decoration: InputDecoration(
        labelText: 'เรียงจำนวนสต็อก',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.filter_list),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'qty_desc', child: Text('มากไปน้อย')),
        DropdownMenuItem(value: 'qty_asc', child: Text('น้อยไปมาก')),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _sortOption = val);
      },
    );
  }

  Widget _buildMobileListView(List<ProductModel> products) {
    if (products.isEmpty) {
      return const Center(child: Text('ไม่พบรายการสินค้า'));
    }
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (ctx, idx) {
        final product = products[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(product.imageUrl!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusBadge(product, isMobile: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'หมวดหมู่: ${product.categoryName}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'คงเหลือ: ${product.quantity} ${product.unit}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.blueAccent,
                        size: 24,
                      ),
                      tooltip: 'ดูรายละเอียดสินค้า',
                      onPressed: () => _showProductDetails(product),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.orangeAccent,
                        size: 24,
                      ),
                      tooltip: 'แก้ไขสินค้าและจำนวน',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => ProductFormDialog(
                            product: product,
                            existingProducts: widget.products,
                            categories: widget.categories,
                            onSave: widget.onUpdateProduct,
                            onDelete: widget.onDeleteProduct,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTableView(List<ProductModel> products) {
    if (products.isEmpty) {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Text('ไม่พบรายการสินค้า'),
          ),
        ),
      );
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            dataRowHeight: 100,
            columns: const [
              DataColumn(label: Text('รูปสินค้า')),
              DataColumn(label: Text('หมวดหมู่')),
              DataColumn(label: Text('ชื่อสินค้า')),
              DataColumn(label: Text('จำนวนคงเหลือ')),
              DataColumn(label: Text('สถานะ')),
              DataColumn(label: Text('การจัดการ')),
            ],
            rows: products.map((product) {
              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      width: 85,
                      height: 85,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child:
                          product.imageUrl != null &&
                              product.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(product.imageUrl!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  DataCell(Text(product.categoryName)),
                  DataCell(
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${product.quantity} ${product.unit}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(_buildStatusBadge(product)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.blueAccent,
                            size: 24,
                          ),
                          tooltip: 'ดูรายละเอียดสินค้า',
                          onPressed: () => _showProductDetails(product),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.orangeAccent,
                            size: 24,
                          ),
                          tooltip: 'แก้ไขสินค้าและจำนวน',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => ProductFormDialog(
                                product: product,
                                existingProducts: widget.products,
                                categories: widget.categories,
                                onSave: widget.onUpdateProduct,
                                onDelete: widget.onDeleteProduct,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}