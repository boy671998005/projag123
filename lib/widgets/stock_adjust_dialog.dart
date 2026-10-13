import 'package:flutter/material.dart';
import '../models/product_model.dart';

class StockAdjustDialog extends StatefulWidget {
  final ProductModel product;
  final bool isAdd;
  final Function(int amount) onConfirm;

  const StockAdjustDialog({
    super.key,
    required this.product,
    required this.isAdd,
    required this.onConfirm,
  });

  @override
  State<StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends State<StockAdjustDialog> {
  final _amountController = TextEditingController(text: '1');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.isAdd ? "เพิ่ม" : "ลด"} สต็อก: ${widget.product.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'จำนวนชิ้น'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () {
            int amount = int.tryParse(_amountController.text) ?? 0;
            if (amount > 0) {
              widget.onConfirm(widget.isAdd ? amount : -amount);
            }
            Navigator.pop(context);
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}