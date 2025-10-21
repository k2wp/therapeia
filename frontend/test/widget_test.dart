// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_frontend/main.dart';

void main() {
  testWidgets('renders login screen with identity fields', (tester) async {
    await tester.pumpWidget(MyApp());

    expect(find.text('ยินดีต้อนรับ'), findsOneWidget);
    expect(find.text('เลขบัตรประชาชน 13 หลัก (Citizen ID)'), findsOneWidget);
    expect(find.text('Hospital Number (HN)'), findsOneWidget);
    expect(find.text('รหัสผ่าน (Password)'), findsOneWidget);
  });
}
