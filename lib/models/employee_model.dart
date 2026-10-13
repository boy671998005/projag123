enum EmployeeRole {
  admin,
  staff,
}

class EmployeeModel {
  final String id;
  final String name;
  final String email;
  final EmployeeRole role;
  bool isActive;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'email': email,
      'role': role == EmployeeRole.admin ? 'admin' : 'staff',
      'isActive': isActive,
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final roleStr = (map['role'] ?? '').toString().toLowerCase();
    final role = roleStr == 'admin' ? EmployeeRole.admin : EmployeeRole.staff;

    bool active = true;
    if (map['isActive'] != null) {
      if (map['isActive'] is bool) {
        active = map['isActive'] as bool;
      } else if (map['isActive'] is String) {
        active = map['isActive'].toString().toLowerCase() == 'true';
      }
    }

    return EmployeeModel(
      id: docId ?? map['uid']?.toString() ?? map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'ไม่ระบุชื่อ',
      email: map['email']?.toString() ?? '',
      role: role,
      isActive: active,
    );
  }
}