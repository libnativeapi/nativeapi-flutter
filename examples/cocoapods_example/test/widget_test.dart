import 'package:flutter_test/flutter_test.dart';

import 'package:cocoapods_example/main.dart';

void main() {
  testWidgets('renders nativeapi smoke test page', (WidgetTester tester) async {
    await tester.pumpWidget(const CocoapodsExampleApp());

    expect(find.text('CocoaPods nativeapi smoke test'), findsWidgets);
    expect(find.text('Run checks'), findsOneWidget);
  });
}
