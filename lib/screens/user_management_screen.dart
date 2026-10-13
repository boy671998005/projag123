import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../services/firestore_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _confirmDeleteUser(BuildContext context, EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยืนยันการลบผู้ใช้งาน', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'คุณต้องการลบ "${employee.name}" (${employee.email}) ออกจากระบบใช่หรือไม่?\n\nข้อมูลผู้ใช้นี้จะถูกลบออกจาก Firestore ทันที',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestoreService.deleteEmployee(employee.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ลบผู้ใช้ ${employee.name} เรียบร้อยแล้ว')),
                );
              }
            },
            child: const Text('ยืนยันการลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEmployeeFormDialog({EmployeeModel? employeeToEdit}) {
    final bool isEditing = employeeToEdit != null;
    final nameController = TextEditingController(text: isEditing ? employeeToEdit.name : '');
    final emailController = TextEditingController(text: isEditing ? employeeToEdit.email : '');
    EmployeeRole selectedRole = isEditing ? employeeToEdit.role : EmployeeRole.staff;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'แก้ไขข้อมูลผู้ใช้งาน' : 'เพิ่มผู้ใช้งานใหม่',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อ-นามสกุล',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'อีเมล',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EmployeeRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'สิทธิ์การใช้งาน (Role)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: EmployeeRole.admin, child: Text('ADMIN (ผู้ดูแลระบบ)')),
                    DropdownMenuItem(value: EmployeeRole.staff, child: Text('STAFF (พนักงานทั่วไป)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
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
              onPressed: () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim();

                if (name.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
                  );
                  return;
                }

                final newEmployee = EmployeeModel(
                  id: isEditing ? employeeToEdit.id : DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  email: email,
                  role: selectedRole,
                  isActive: isEditing ? employeeToEdit.isActive : true,
                );

                await _firestoreService.saveEmployee(newEmployee);
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;

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
                'จัดการผู้ใช้งานและสิทธิ์การเข้าถึง',
                style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
                label: const Text('เพิ่มพนักงานใหม่', style: TextStyle(color: Colors.white)),
                onPressed: () => _showEmployeeFormDialog(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: StreamBuilder<List<EmployeeModel>>(
                stream: _firestoreService.getEmployeesStream(),
                builder: (context, snapshot) {
                  // 1. ถ้ามี Error จาก Firestore ให้แสดงแจ้งเตือนตรงๆ ทันที
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                            const SizedBox(height: 12),
                            const Text(
                              'เกิดข้อผิดพลาดในการดึงข้อมูลจาก Firestore',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              '${snapshot.error}',
                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // 2. อยู่ระหว่างโหลด
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // 3. ตรวจสอบรายการข้อมูล
                  final employees = snapshot.data ?? [];
                  if (employees.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text(
                            'ยังไม่มีข้อมูลผู้ใช้งานในระบบ Firestore',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: employees.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final employee = employees[idx];
                      final bool isAdmin = employee.role == EmployeeRole.admin;
                      final String firstChar = employee.name.isNotEmpty ? employee.name[0] : '?';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: isAdmin ? Colors.deepPurple : Colors.blueAccent,
                          child: Text(
                            firstChar,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        title: Text(
                          employee.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          'อีเมล: ${employee.email}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isAdmin ? Colors.deepPurple : Colors.blueAccent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                employee.role.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Switch(
                              value: employee.isActive,
                              activeColor: Colors.blueAccent,
                              onChanged: (val) async {
                                await _firestoreService.updateEmployeeStatus(employee.id, val);
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'ลบผู้ใช้',
                              onPressed: () => _confirmDeleteUser(context, employee),
                            ),
                          ],
                        ),
                      );
                    },
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