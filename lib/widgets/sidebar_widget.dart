import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../screens/auth_screen.dart';

class SidebarWidget extends StatelessWidget {
  final bool isExpanded;
  final bool isMobile;
  final EmployeeModel employee;
  final int selectedIndex;
  final Function(int) onMenuSelected;
  final VoidCallback? onToggle;

  const SidebarWidget({
    super.key,
    required this.isExpanded,
    required this.isMobile,
    required this.employee,
    required this.selectedIndex,
    required this.onMenuSelected,
    this.onToggle,
  });

  // ออกจากระบบ แล้วกลับไปหน้าล็อกอิน
  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // ถ้า signOut มีปัญหา ก็ยังพากลับหน้าล็อกอินตามปกติ
    }
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = isExpanded ? 240 : 70;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isMobile ? double.infinity : width,
      height: double.infinity,
      color: const Color(0xFF1E293B),
      child: Material(
        color: const Color(0xFF1E293B),
        child: Column(
          children: [
            // ปุ่มพับ/กาง Sidebar (เฉพาะ Desktop/Tablet)
            if (!isMobile)
              Container(
                alignment: Alignment.centerRight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: IconButton(
                  icon: Icon(
                    isExpanded ? Icons.chevron_left : Icons.chevron_right,
                    color: Colors.white70,
                  ),
                  onPressed: onToggle,
                ),
              ),

            // ส่วนแสดงโปรไฟล์ผู้ใช้งาน
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  if (isExpanded || isMobile) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'สิทธิ์: ${employee.role.name.toUpperCase()}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: Colors.white24),

            // เมนูหลัก
            Expanded(
              child: ListView(
                children: [
                  _buildMenuItem(
                    index: 0,
                    icon: Icons.inventory_2_outlined,
                    title: 'นับและจัดการสต็อก',
                  ),
                  _buildMenuItem(
                    index: 1,
                    icon: Icons.move_to_inbox_outlined,
                    title: 'รับเข้า',
                  ),
                  _buildMenuItem(
                    index: 2,
                    icon: Icons.local_shipping_outlined,
                    title: 'ส่งออก',
                  ),
                  _buildMenuItem(
                    index: 3,
                    icon: Icons.bar_chart_outlined,
                    title: 'สรุปรายงานสต็อก',
                  ),
                  _buildMenuItem(
                    index: 4,
                    icon: Icons.category_outlined,
                    title: 'จัดการหมวดหมู่สินค้า',
                  ),
                  // เห็นเฉพาะ Admin เท่านั้น
                  if (employee.role == EmployeeRole.admin)
                    _buildMenuItem(
                      index: 5,
                      icon: Icons.people_outline,
                      title: 'จัดการผู้ใช้งานและสิทธิ์',
                    ),
                ],
              ),
            ),

            const Divider(color: Colors.white24),
            // ปุ่มออกจากระบบ
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: (isExpanded || isMobile)
                  ? const Text(
                      'ออกจากระบบ',
                      style: TextStyle(color: Colors.redAccent, fontSize: 14),
                    )
                  : null,
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String title,
  }) {
    bool isSelected = selectedIndex == index;
    return ListTile(
      selected: isSelected,
      selectedTileColor: Colors.blueAccent.withValues(alpha: 0.2),
      leading: Icon(
        icon,
        color: isSelected ? Colors.blueAccent : Colors.white70,
      ),
      title: (isExpanded || isMobile)
          ? Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            )
          : null,
      onTap: () => onMenuSelected(index),
    );
  }
}