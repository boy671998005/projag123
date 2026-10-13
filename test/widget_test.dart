import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_2shop/main.dart';

void main() {
  testWidgets('shows login form and opens stock dashboard', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());

    expect(find.text('ยินดีต้อนรับเข้าสู่ระบบสต็อกสินค้า'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'admin@shop.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'demo-password');
    await tester.tap(find.text('เข้าสู่ระบบ'));
    await tester.pumpAndSettle();

    expect(find.text('นับและจัดการสต็อก'), findsOneWidget);
  });

  testWidgets('validates empty login fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('เข้าสู่ระบบ').first);
    await tester.pump();

    expect(find.text('กรุณากรอกอีเมล'), findsOneWidget);
    expect(find.text('กรุณากรอกรหัสผ่าน'), findsOneWidget);
  });
}
