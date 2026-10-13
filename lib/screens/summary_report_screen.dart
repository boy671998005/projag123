import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';

class SummaryReportScreen extends StatefulWidget {
  final List<ProductModel> products;
  final List<TransactionModel> transactions;

  const SummaryReportScreen({
    super.key,
    required this.products,
    required this.transactions,
  });

  @override
  State<SummaryReportScreen> createState() => _SummaryReportScreenState();
}

class _SummaryReportScreenState extends State<SummaryReportScreen> {
  DateTime _startDate = DateTime(2026, 10, 1);
  DateTime _endDate = DateTime(2026, 10, 14);
  TransactionType _currentTab = TransactionType.export;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month, now.day);
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;

    // คำนวณสรุปสต็อกคงเหลือ
    final double totalCost = widget.products.fold(
      0.0,
      (sum, p) => sum + (p.costPrice * p.quantity),
    );
    final double totalSelling = widget.products.fold(
      0.0,
      (sum, p) => sum + (p.sellingPrice * p.quantity),
    );
    final int totalStockQty = widget.products.fold(
      0,
      (sum, p) => sum + p.quantity,
    );

    // กรองรายการธุรกรรมตามช่วงวันที่และประเภท (รับเข้า/ส่งออก)
    final filteredTx = widget.transactions.where((t) {
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
      final inRange = !tDate.isBefore(start) && !tDate.isAfter(end);
      return inRange && t.type == _currentTab;
    }).toList();

    // คำนวณผลรวม
    final int totalTxQty = filteredTx.fold(0, (sum, t) => sum + t.quantity);
    final double totalRevenue = filteredTx.fold(
      0.0,
      (sum, t) => sum + (t.sellingPrice * t.quantity),
    );
    final double totalProfit = filteredTx.fold(
      0.0,
      (sum, t) => sum + ((t.sellingPrice - t.costPrice) * t.quantity),
    );
    final double totalImportCost = filteredTx.fold(
      0.0,
      (sum, t) => sum + (t.costPrice * t.quantity),
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัวและปุ่มเลือกช่วงวันที่
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'สรุปรายงานภาพรวมสต็อก',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_today, size: 16, color: Colors.blueAccent),
                  label: Text(
                    '${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // การ์ดสรุป 3 ใบด้านบน
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  return Column(
                    children: [
                      _buildSummaryCard(
                        icon: Icons.account_balance_wallet_outlined,
                        iconBg: const Color(0xFFE0F2FE),
                        iconColor: const Color(0xFF0284C7),
                        title: 'มูลค่าสต็อกรวม (ราคาทุน)',
                        value: '฿${totalCost.toStringAsFixed(2)}',
                        valueColor: const Color(0xFF0284C7),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryCard(
                        icon: Icons.storefront_outlined,
                        iconBg: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        title: 'มูลค่าสินค้าพร้อมขาย (ราคาขาย)',
                        value: '฿${totalSelling.toStringAsFixed(2)}',
                        valueColor: const Color(0xFF16A34A),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryCard(
                        icon: Icons.inventory_2_outlined,
                        iconBg: const Color(0xFFFFEDD5),
                        iconColor: const Color(0xFFEA580C),
                        title: 'จำนวนสินค้าคงเหลือรวม',
                        value: '$totalStockQty ชิ้น',
                        valueColor: const Color(0xFFEA580C),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        icon: Icons.account_balance_wallet_outlined,
                        iconBg: const Color(0xFFE0F2FE),
                        iconColor: const Color(0xFF0284C7),
                        title: 'มูลค่าสต็อกรวม (ราคาทุน)',
                        value: '฿${totalCost.toStringAsFixed(2)}',
                        valueColor: const Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        icon: Icons.storefront_outlined,
                        iconBg: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        title: 'มูลค่าสินค้าพร้อมขาย (ราคาขาย)',
                        value: '฿${totalSelling.toStringAsFixed(2)}',
                        valueColor: const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        icon: Icons.inventory_2_outlined,
                        iconBg: const Color(0xFFFFEDD5),
                        iconColor: const Color(0xFFEA580C),
                        title: 'จำนวนสินค้าคงเหลือรวม',
                        value: '$totalStockQty ชิ้น',
                        valueColor: const Color(0xFFEA580C),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // กล่องแสดงรายการธุรกรรม
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'สรุปรายการสินค้าที่${_currentTab == TransactionType.export ? 'ส่งออก' : 'รับเข้า'} (${_formatDate(_startDate)} - ${_formatDate(_endDate)})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _currentTab == TransactionType.export
                                    ? Colors.blueAccent
                                    : Colors.grey[200],
                                foregroundColor: _currentTab == TransactionType.export
                                    ? Colors.white
                                    : Colors.black87,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.local_shipping_outlined, size: 16),
                              label: const Text('ส่งออก'),
                              onPressed: () => setState(() => _currentTab = TransactionType.export),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _currentTab == TransactionType.import
                                    ? Colors.teal
                                    : Colors.grey[200],
                                foregroundColor: _currentTab == TransactionType.import
                                    ? Colors.white
                                    : Colors.black87,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.move_to_inbox_outlined, size: 16),
                              label: const Text('รับเข้า'),
                              onPressed: () => setState(() => _currentTab = TransactionType.import),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_currentTab == TransactionType.export ? 'ส่งออกรวม' : 'รับเข้ารวม'}: $totalTxQty ชิ้น',
                        style: TextStyle(
                          color: _currentTab == TransactionType.export ? Colors.blueAccent : Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Divider(height: 24),

                    if (filteredTx.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'ไม่มีรายการในช่วงเวลาที่เลือก',
                            style: TextStyle(color: Colors.black45, fontSize: 15),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredTx.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final tx = filteredTx[idx];
                          final bool isExport = tx.type == TransactionType.export;
                          final double itemRevenue = tx.sellingPrice * tx.quantity;
                          final double itemProfit = (tx.sellingPrice - tx.costPrice) * tx.quantity;
                          final double itemCost = tx.costPrice * tx.quantity;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // ตัวเลขลำดับ
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isExport ? const Color(0xFFE0E7FF) : const Color(0xFFCCFBF1),
                                  child: Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      color: isExport ? const Color(0xFF4338CA) : const Color(0xFF0F766E),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // รายละเอียดสินค้า วันที่ และชื่อผู้ทำรายการ
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Text(
                                            'วันที่: ${_formatDate(tx.date)}',
                                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                                          ),
                                          // ป้ายแสดงชื่อผู้รับเข้า หรือ ผู้ส่งออก
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isExport ? Colors.indigo.shade50 : Colors.teal.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: isExport ? Colors.indigo.shade200 : Colors.teal.shade200,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  size: 12,
                                                  color: isExport ? Colors.indigo.shade700 : Colors.teal.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${isExport ? "ผู้ส่งออก" : "ผู้รับเข้า"}: ${tx.userName}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isExport ? Colors.indigo.shade800 : Colors.teal.shade800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            'ทุน: ฿${tx.costPrice.toStringAsFixed(2)} | ขาย: ฿${tx.sellingPrice.toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // สรุปยอดด้านขวา
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isExport ? "ส่งออก" : "รับเข้า"}: ${tx.quantity} ชิ้น',
                                      style: TextStyle(
                                        color: isExport ? Colors.redAccent : Colors.teal,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (isExport)
                                      Text(
                                        'ยอดขาย: ฿${itemRevenue.toStringAsFixed(2)} (กำไร: +฿${itemProfit.toStringAsFixed(2)})',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      )
                                    else
                                      Text(
                                        'ราคาทุนรวม: ฿${itemCost.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.teal.shade800,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),

                    // แถบสรุปผลลัพธ์รวมด้านล่าง
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _currentTab == TransactionType.export
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _currentTab == TransactionType.export
                              ? const Color(0xFFBBF7D0)
                              : const Color(0xFF99F6E4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currentTab == TransactionType.export
                                ? 'รวมผลตอบแทนจากการส่งออกทั้งหมด:'
                                : 'รวมต้นทุนการรับเข้าสินค้าทั้งหมด:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            _currentTab == TransactionType.export
                                ? 'ยอดขาย ฿${totalRevenue.toStringAsFixed(2)}  |  กำไรสุทธิ +฿${totalProfit.toStringAsFixed(2)}'
                                : 'ต้นทุนรวม ฿${totalImportCost.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: _currentTab == TransactionType.export
                                  ? Colors.green.shade800
                                  : Colors.teal.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}