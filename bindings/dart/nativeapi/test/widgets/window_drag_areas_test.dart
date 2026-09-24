import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nativeapi/nativeapi.dart';

class _Window extends Window {
  _Window() : super.borrowed(0);

  int dragCount = 0;
  final edges = <ResizeEdge>[];
  bool maximized = false;

  @override
  void startDragging() => dragCount++;

  @override
  void startResizing(ResizeEdge edge) => edges.add(edge);

  @override
  bool get isMaximized => maximized;

  @override
  void maximize() => maximized = true;

  @override
  void unmaximize() => maximized = false;
}

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(child: child),
);

Future<void> _drag(WidgetTester tester, Offset position) async {
  final gesture = await tester.startGesture(
    position,
    kind: PointerDeviceKind.mouse,
  );
  await gesture.moveBy(const Offset(30, 30));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('move area drags and toggles maximization on double tap', (
    tester,
  ) async {
    final window = _Window();
    await tester.pumpWidget(
      _host(
        DragToMoveArea(
          window: window,
          child: const SizedBox(width: 200, height: 100),
        ),
      ),
    );
    final center = tester.getCenter(find.byType(DragToMoveArea));
    await _drag(tester, center);
    expect(window.dragCount, 1);
    for (final expected in [true, false]) {
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pumpAndSettle();
      expect(window.maximized, expected);
    }
  });

  testWidgets('all eight handles send the correct native resize edge', (
    tester,
  ) async {
    final window = _Window();
    await tester.pumpWidget(
      _host(
        DragToResizeArea(
          window: window,
          resizeEdgeMargin: const EdgeInsets.all(10),
          child: const SizedBox(width: 200, height: 100),
        ),
      ),
    );
    final origin = tester.getTopLeft(find.byType(DragToResizeArea));
    final points = <ResizeEdge, Offset>{
      ResizeEdge.topLeft: const Offset(14, 14),
      ResizeEdge.top: const Offset(100, 14),
      ResizeEdge.topRight: const Offset(186, 14),
      ResizeEdge.left: const Offset(14, 50),
      ResizeEdge.right: const Offset(186, 50),
      ResizeEdge.bottomLeft: const Offset(14, 86),
      ResizeEdge.bottom: const Offset(100, 86),
      ResizeEdge.bottomRight: const Offset(186, 86),
    };
    for (final entry in points.entries) {
      await _drag(tester, origin + entry.value);
      expect(window.edges.last, entry.key);
    }
    expect(window.edges, points.keys.toList());
    expect(tester.takeException(), isNull);
  });

  testWidgets('center, margin and disabled edges pass gestures to child', (
    tester,
  ) async {
    final window = _Window();
    var childDrags = 0;
    await tester.pumpWidget(
      _host(
        DragToResizeArea(
          window: window,
          enableResizeEdges: const [ResizeEdge.right],
          resizeEdgeMargin: const EdgeInsets.all(10),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) => childDrags++,
            child: const SizedBox(width: 200, height: 100),
          ),
        ),
      ),
    );
    final origin = tester.getTopLeft(find.byType(DragToResizeArea));
    for (final point in [
      const Offset(100, 50),
      const Offset(2, 50),
      const Offset(14, 50),
      const Offset(14, 14),
    ]) {
      await _drag(tester, origin + point);
    }
    expect(childDrags, 4);
    expect(window.edges, isEmpty);
    await _drag(tester, origin + const Offset(186, 50));
    expect(window.edges, [ResizeEdge.right]);
    expect(childDrags, 4);
  });

  testWidgets('small child and empty edge list lay out without overflow', (
    tester,
  ) async {
    for (final edges in [null, <ResizeEdge>[]]) {
      await tester.pumpWidget(
        _host(
          DragToResizeArea(
            window: _Window(),
            enableResizeEdges: edges,
            child: const SizedBox(width: 6, height: 4),
          ),
        ),
      );
      expect(tester.getSize(find.byType(DragToResizeArea)), const Size(6, 4));
      expect(tester.takeException(), isNull);
      if (edges != null) {
        expect(find.byType(MouseRegion), findsNothing);
      }
    }
  });
}
