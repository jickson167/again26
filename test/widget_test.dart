import 'package:flutter_test/flutter_test.dart';

import 'package:again26/main.dart';

void main() {
  testWidgets('홈 화면이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const Again26App());
    await tester.pumpAndSettle();

    expect(find.text('Supabase 설정 필요'), findsOneWidget);
  });
}
