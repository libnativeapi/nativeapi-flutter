import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shaped_window_example/widgets/value_slider.dart';

void main() {
  testWidgets('widgets-only slider supports pointer and keyboard bounds', (
    tester,
  ) async {
    double value = 18;
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        builder: (_, _) => StatefulBuilder(
          builder: (context, setState) => Center(
            child: SizedBox(
              width: 220,
              child: ValueSlider(
                label: 'Blur radius',
                value: value,
                min: 0,
                max: 64,
                step: 1,
                display: '$value px',
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ValueSlider));
    await tester.pump();
    expect(value, 32);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 33);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(value, 64);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 64);
    await tester.drag(find.byType(ValueSlider), const Offset(-400, 0));
    await tester.pump();
    expect(value, 0);
  });
}
