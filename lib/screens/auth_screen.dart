import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/employee_model.dart';
import 'main_layout_screen.dart';

const _navy = Color(0xFF2B3050);
const _pinkA = Color(0xFFC9667A);
const _pinkB = Color(0xFFDB8E99);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLogin = true;
  bool _rememberMe = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    UserCredential? createdCredential;

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      final email = _emailController.text.trim();
      late final EmployeeModel employee;

      if (_isLogin) {
        final credential = await auth.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text,
        );
        final user = credential.user;
        if (user == null) {
          throw StateError('Firebase Authentication returned no user.');
        }

        final profile = await firestore.collection('users').doc(user.uid).get();
        if (!profile.exists) {
          await auth.signOut();
          _showMessage('ไม่พบข้อมูลโปรไฟล์ในระบบ กรุณาติดต่อผู้ดูแลระบบ');
          return;
        }

        try {
          employee = _employeeFromProfile(user.uid, profile.data()!);
        } on StateError {
          await auth.signOut();
          rethrow;
        }
        if (!employee.isActive) {
          await auth.signOut();
          _showMessage('บัญชีนี้ถูกปิดใช้งาน กรุณาติดต่อผู้ดูแลระบบ');
          return;
        }
      } else {
        final credential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: _passwordController.text,
        );
        createdCredential = credential;
        final user = credential.user;
        if (user == null) {
          throw StateError('Firebase Authentication returned no user.');
        }

        final name = _nameController.text.trim();
        await user.updateDisplayName(name);
        await firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'role': EmployeeRole.staff.name,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        employee = EmployeeModel(
          id: user.uid,
          name: name,
          email: email,
          role: EmployeeRole.staff,
          isActive: true,
        );
      }

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MainLayoutScreen(employee: employee),
        ),
      );
    } on FirebaseAuthException catch (error) {
      final cleanupMessage = await _deleteIncompleteAccount(createdCredential);
      if (!mounted) return;
      _showMessage(cleanupMessage ?? _authErrorMessage(error));
    } on FirebaseException catch (error) {
      final cleanupMessage = await _deleteIncompleteAccount(createdCredential);
      if (!mounted) return;
      _showMessage(cleanupMessage ?? _firebaseErrorMessage(error));
    } on StateError catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<String?> _deleteIncompleteAccount(UserCredential? credential) async {
    final user = credential?.user;
    if (user == null) return null;

    try {
      await user.delete();
      return null;
    } on FirebaseAuthException catch (error) {
      return 'สร้างบัญชีไม่สมบูรณ์และลบบัญชีที่สร้างไว้ไม่สำเร็จ '
          '(${error.code}) กรุณาติดต่อผู้ดูแลระบบ';
    }
  }

  EmployeeModel _employeeFromProfile(String uid, Map<String, dynamic> data) {
    final name = data['name'];
    final email = data['email'];
    final role = data['role'];
    if (name is! String ||
        name.trim().isEmpty ||
        email is! String ||
        role is! String ||
        !EmployeeRole.values.any((value) => value.name == role)) {
      throw StateError('ข้อมูลโปรไฟล์ไม่ถูกต้อง กรุณาติดต่อผู้ดูแลระบบ');
    }
    return EmployeeModel(
      id: uid,
      name: name,
      email: email,
      role: EmployeeRole.values.byName(role),
      isActive: data['isActive'] == true,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      case 'email-already-in-use':
        return 'อีเมลนี้มีบัญชีอยู่แล้ว';
      case 'weak-password':
        return 'รหัสผ่านไม่ปลอดภัยพอ กรุณาใช้รหัสผ่านอย่างน้อย 6 ตัวอักษร';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'too-many-requests':
        return 'พยายามเข้าสู่ระบบหลายครั้งเกินไป กรุณารอสักครู่แล้วลองใหม่';
      case 'network-request-failed':
        return 'เชื่อมต่อเครือข่ายไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต';
      default:
        return 'ดำเนินการกับบัญชีไม่สำเร็จ (${error.code})';
    }
  }

  String _firebaseErrorMessage(FirebaseException error) {
    if (error.plugin == 'cloud_firestore') {
      return 'อ่านหรือบันทึกโปรไฟล์ไม่สำเร็จ (${error.code}) '
          'กรุณาตรวจสอบการตั้งค่า Firestore';
    }
    return 'เชื่อมต่อ Firebase ไม่สำเร็จ (${error.code})';
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณากรอกชื่อ-นามสกุล';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'กรุณากรอกอีเมล';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'กรุณากรอกอีเมลให้ถูกต้อง';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
    if (!_isLogin && value.length < 6) {
      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
    if (value != _passwordController.text) return 'รหัสผ่านไม่ตรงกัน';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4FC3E0), Color(0xFF8E6CC8), Color(0xFFE91E8C)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 800;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: isDesktop
                        ? _DesktopCard(
                            isLogin: _isLogin,
                            isSubmitting: _isSubmitting,
                            rememberMe: _rememberMe,
                            nameController: _nameController,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            confirmPasswordController:
                                _confirmPasswordController,
                            onRememberChanged: (value) => setState(
                              () => _rememberMe = value,
                            ),
                            onToggle: _toggleMode,
                            onSubmit: _submit,
                            validateName: _validateName,
                            validateEmail: _validateEmail,
                            validatePassword: _validatePassword,
                            validateConfirmPassword:
                                _validateConfirmPassword,
                          )
                        : _MobileCard(
                            isLogin: _isLogin,
                            isSubmitting: _isSubmitting,
                            rememberMe: _rememberMe,
                            nameController: _nameController,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            confirmPasswordController:
                                _confirmPasswordController,
                            onRememberChanged: (value) => setState(
                              () => _rememberMe = value,
                            ),
                            onToggle: _toggleMode,
                            onSubmit: _submit,
                            validateName: _validateName,
                            validateEmail: _validateEmail,
                            validatePassword: _validatePassword,
                            validateConfirmPassword:
                                _validateConfirmPassword,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  final bool isLogin;
  final bool isSubmitting;
  final bool rememberMe;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onToggle;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> validateName;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final FormFieldValidator<String> validateConfirmPassword;

  const _AuthForm({
    required this.isLogin,
    required this.isSubmitting,
    required this.rememberMe,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onRememberChanged,
    required this.onToggle,
    required this.onSubmit,
    required this.validateName,
    required this.validateEmail,
    required this.validatePassword,
    required this.validateConfirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    const smallStyle = TextStyle(fontSize: 11, color: _navy);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isLogin ? 'ยินดีต้อนรับเข้าสู่ระบบสต็อกสินค้า' : 'สมัครสมาชิก',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _navy,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isLogin ? 'เข้าสู่ระบบเพื่อดำเนินการต่อ' : 'สมัครสมาชิกฟรี!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: _navy),
        ),
        const SizedBox(height: 8),
        const _Dots(),
        const SizedBox(height: 18),
        if (!isLogin)
          _PillField(
            controller: nameController,
            hint: 'ชื่อ-นามสกุล',
            validator: validateName,
          ),
        _PillField(
          controller: emailController,
          hint: 'อีเมล',
          keyboardType: TextInputType.emailAddress,
          validator: validateEmail,
        ),
        _PillField(
          controller: passwordController,
          hint: 'รหัสผ่าน',
          obscure: true,
          validator: validatePassword,
        ),
        if (!isLogin)
          _PillField(
            controller: confirmPasswordController,
            hint: 'ยืนยันรหัสผ่าน',
            obscure: true,
            validator: validateConfirmPassword,
          ),
        if (isLogin)
          Row(
            children: [
              SizedBox(
                height: 28,
                width: 28,
                child: Checkbox(
                  value: rememberMe,
                  activeColor: _navy,
                  onChanged: (value) => onRememberChanged(value ?? false),
                ),
              ),
              const SizedBox(width: 4),
              const Text('จดจำฉันไว้', style: smallStyle),
              const Spacer(),
              TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณาติดต่อผู้ดูแลระบบเพื่อรีเซ็ตรหัสผ่าน'),
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: _navy,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('ลืมรหัสผ่าน?', style: smallStyle),
              ),
            ],
          ),
        const SizedBox(height: 14),
        _GradientButton(
          label: isSubmitting
              ? 'กำลังดำเนินการ...'
              : isLogin
                  ? 'เข้าสู่ระบบ'
                  : 'เริ่มต้นใช้งาน',
          onTap: isSubmitting ? () {} : onSubmit,
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLogin ? 'ยังไม่มีบัญชี?  ' : 'เป็นสมาชิกอยู่แล้ว?  ',
              style: smallStyle,
            ),
            GestureDetector(
              onTap: onToggle,
              child: Text(
                isLogin ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ',
                style: smallStyle.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DesktopCard extends StatelessWidget {
  final bool isLogin;
  final bool isSubmitting;
  final bool rememberMe;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onToggle;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> validateName;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final FormFieldValidator<String> validateConfirmPassword;

  const _DesktopCard({
    required this.isLogin,
    required this.isSubmitting,
    required this.rememberMe,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onRememberChanged,
    required this.onToggle,
    required this.onSubmit,
    required this.validateName,
    required this.validateEmail,
    required this.validatePassword,
    required this.validateConfirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    const cardHeight = 560.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 940),
      child: SizedBox(
        height: cardHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final navyWidth = constraints.maxWidth * 0.44;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 20),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: navyWidth,
                      child: ClipPath(
                        clipper: _RightPointClipper(),
                        child: Container(
                          color: _navy,
                          padding: const EdgeInsets.fromLTRB(36, 20, 56, 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: _StockLogo(
                                  imageHeight: 150,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'ระบบของเราจัดทำขึ้นมาเพื่อให้ทุกท่าน '
                                'สามารถจัดการสต็อกสินค้าได้สะดวกและเกิดประโยชน์สูงสุด',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _pinkA,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'ดูเพิ่มเติม',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: navyWidth + 50,
                      right: 50,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: SingleChildScrollView(
                          child: _AuthForm(
                            isLogin: isLogin,
                            isSubmitting: isSubmitting,
                            rememberMe: rememberMe,
                            nameController: nameController,
                            emailController: emailController,
                            passwordController: passwordController,
                            confirmPasswordController:
                                confirmPasswordController,
                            onRememberChanged: onRememberChanged,
                            onToggle: onToggle,
                            onSubmit: onSubmit,
                            validateName: validateName,
                            validateEmail: validateEmail,
                            validatePassword: validatePassword,
                            validateConfirmPassword: validateConfirmPassword,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: navyWidth - 28,
                      top: cardHeight / 2 - 28,
                      child: _RoundButton(
                        icon: Icons.chevron_left,
                        onTap: onToggle,
                      ),
                    ),
                    const Positioned(
                      right: 10,
                      top: 10,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: _navy,
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MobileCard extends StatelessWidget {
  final bool isLogin;
  final bool isSubmitting;
  final bool rememberMe;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onToggle;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> validateName;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final FormFieldValidator<String> validateConfirmPassword;

  const _MobileCard({
    required this.isLogin,
    required this.isSubmitting,
    required this.rememberMe,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onRememberChanged,
    required this.onToggle,
    required this.onSubmit,
    required this.validateName,
    required this.validateEmail,
    required this.validatePassword,
    required this.validateConfirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    final headerHeight = isLogin ? 210.0 : 190.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipPath(
                    clipper: _DownPointClipper(),
                    child: Container(
                      height: headerHeight,
                      width: double.infinity,
                      color: _navy,
                      alignment: const Alignment(0, -0.55),
                      child: _StockLogo(
                        imageHeight: isLogin ? 100 : 85,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
                    child: _AuthForm(
                      isLogin: isLogin,
                      isSubmitting: isSubmitting,
                      rememberMe: rememberMe,
                      nameController: nameController,
                      emailController: emailController,
                      passwordController: passwordController,
                      confirmPasswordController: confirmPasswordController,
                      onRememberChanged: onRememberChanged,
                      onToggle: onToggle,
                      onSubmit: onSubmit,
                      validateName: validateName,
                      validateEmail: validateEmail,
                      validatePassword: validatePassword,
                      validateConfirmPassword: validateConfirmPassword,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: headerHeight - 28,
                left: 0,
                right: 0,
                child: Center(
                  child: _RoundButton(
                    icon: Icons.keyboard_arrow_down,
                    onTap: onToggle,
                  ),
                ),
              ),
              const Positioned(
                right: 10,
                top: 10,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.close, size: 12, color: _navy),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockLogo extends StatelessWidget {
  final double imageHeight;
  final double fontSize;

  const _StockLogo({required this.imageHeight, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.warehouse_outlined,
          color: Colors.white,
          size: imageHeight,
        ),
        const SizedBox(height: 8),
        Text(
          'ระบบสต็อกสินค้า',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PillField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final FormFieldValidator<String> validator;

  const _PillField({
    required this.controller,
    required this.hint,
    required this.validator,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: _navy),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: _navy, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: _pinkA, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.red, width: 1.6),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_pinkA, _pinkB]),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < 3; index++)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == 0 ? _navy : Colors.black26,
            ),
          ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(colors: [_pinkA, _pinkB]),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RightPointClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width - 32, 0)
    ..lineTo(size.width, size.height / 2)
    ..lineTo(size.width - 32, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DownPointClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height - 32)
    ..lineTo(size.width / 2, size.height)
    ..lineTo(0, size.height - 32)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
