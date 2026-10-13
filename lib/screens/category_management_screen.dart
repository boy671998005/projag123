import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category_model.dart';

class CategoryManagementScreen extends StatefulWidget {
  final List<CategoryModel> categories;
  final Function(CategoryModel) onAddCategory;
  final Function(CategoryModel) onUpdateCategory;
  final Function(String) onDeleteCategory;

  const CategoryManagementScreen({
    super.key,
    required this.categories,
    required this.onAddCategory,
    required this.onUpdateCategory,
    required this.onDeleteCategory,
  });

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  // Dialog สำหรับ เพิ่ม หรือ แก้ไข หมวดหมู่
  void _showCategoryDialog({CategoryModel? categoryToEdit}) {
    final bool isEditing = categoryToEdit != null;
    final TextEditingController nameController = TextEditingController(
      text: isEditing ? categoryToEdit.name : '',
    );
    String? categoryBase64Image = isEditing ? categoryToEdit.imageUrl : null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // ปรับย่อขนาดรูปภาพสำหรับบันทึกลง Firestore (ทางเลือก B)
            Future<void> pickImage() async {
              final ImagePicker picker = ImagePicker();
              final XFile? image = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 300,
                maxHeight: 300,
                imageQuality: 70,
              );

              if (image != null) {
                final bytes = await image.readAsBytes();
                setDialogState(() {
                  categoryBase64Image = base64Encode(bytes);
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? 'แก้ไขหมวดหมู่สินค้า' : 'เพิ่มหมวดหมู่สินค้าใหม่',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // กรอบพรีวิวรูปภาพหมวดหมู่
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: categoryBase64Image != null && categoryBase64Image!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                base64Decode(categoryBase64Image!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.category_outlined, size: 50, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    // ปุ่มแนบรูปภาพ
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                        side: const BorderSide(color: Colors.blueAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('แนบรูปภาพ'),
                      onPressed: pickImage,
                    ),
                    const SizedBox(height: 16),

                    // ช่องกรอกชื่อหมวดหมู่
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อหมวดหมู่สินค้า',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณากรอกชื่อหมวดหมู่')),
                      );
                      return;
                    }

                    if (isEditing) {
                      final updatedCat = CategoryModel(
                        id: categoryToEdit.id,
                        name: name,
                        imageUrl: categoryBase64Image,
                      );
                      widget.onUpdateCategory(updatedCat);
                    } else {
                      final newCat = CategoryModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        imageUrl: categoryBase64Image,
                      );
                      widget.onAddCategory(newCat);
                    }

                    Navigator.pop(ctx);
                  },
                  child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'จัดการหมวดหมู่สินค้า',
                style: TextStyle(fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('เพิ่มหมวดหมู่ใหม่', style: TextStyle(color: Colors.white)),
                onPressed: () => _showCategoryDialog(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: widget.categories.isEmpty
                  ? const Center(child: Text('ยังไม่มีหมวดหมู่สินค้า'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: widget.categories.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final cat = widget.categories[idx];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      base64Decode(cat.imageUrl!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.category, color: Colors.blueAccent, size: 28),
                          ),
                          title: Text(
                            cat.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.orangeAccent),
                                tooltip: 'แก้ไขชื่อและรูปภาพหมวดหมู่',
                                onPressed: () => _showCategoryDialog(categoryToEdit: cat),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: 'ลบหมวดหมู่',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (deleteCtx) => AlertDialog(
                                      title: const Text('ยืนยันการลบ'),
                                      content: Text('คุณต้องการลบหมวดหมู่ "${cat.name}" ใช่หรือไม่?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(deleteCtx),
                                          child: const Text('ยกเลิก'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                          onPressed: () {
                                            widget.onDeleteCategory(cat.id);
                                            Navigator.pop(deleteCtx);
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
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}