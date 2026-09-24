// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;
import 'package:flutter_test/flutter_test.dart';

// The example keeps a panel's state across windows by building it under the
// same GlobalKey in whichever window it is in. This checks that premise with
// the same shape of tree, without native windows: one MaterialApp per view,
// the panel moving between them.

class _FakeView extends TestFlutterView {
  _FakeView(FlutterView view, {required this.viewId})
    : super(
        view: view,
        platformDispatcher: view.platformDispatcher as TestPlatformDispatcher,
        display: view.display as TestDisplay,
      );

  @override
  final int viewId;

  @override
  void render(Scene scene, {Size? size}) {}

  @override
  void updateSemantics(SemanticsUpdate update) {}
}

class _Panel extends StatefulWidget {
  const _Panel();

  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> with SingleTickerProviderStateMixin {
  final text = TextEditingController(text: 'hello');
  final scroll = ScrollController();
  late final AnimationController animation;
  int counter = 0;
  void increment(int by) => setState(() => counter += by);
  final viewIds = <int>[];

  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    viewIds.add(View.of(context).viewId);
  }

  @override
  void dispose() {
    text.dispose();
    scroll.dispose();
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          TextField(controller: text),
          Text('count $counter'),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              itemCount: 100,
              itemExtent: 40,
              itemBuilder: (context, i) => Text('row $i'),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  // No native windows here. With the windowing flag on, the test binding would
  // otherwise create the platform's windowing owner, which on Windows binds to
  // engine symbols the test host does not have and fails before the test loads.
  isWindowingEnabled = false;

  testWidgets('a GlobalKey subtree keeps its state when moved between views', (
    tester,
  ) async {
    final panelKey = GlobalKey();
    final mainView = _FakeView(tester.view, viewId: 1);
    final floatingView = _FakeView(tester.view, viewId: 2);

    Widget windows({required bool floating}) {
      final panel = KeyedSubtree(key: panelKey, child: const _Panel());
      return ViewCollection(
        views: [
          View(
            view: mainView,
            child: MaterialApp(
              home: Row(
                children: [
                  const Expanded(child: Placeholder()),
                  SizedBox(
                    width: 300,
                    child: floating ? const SizedBox() : panel,
                  ),
                ],
              ),
            ),
          ),
          if (floating)
            View(
              view: floatingView,
              child: MaterialApp(home: panel),
            ),
        ],
      );
    }

    await tester.pumpWidget(windows(floating: false), wrapWithView: false);
    _PanelState panelState() =>
        tester.state<_PanelState>(find.byType(_Panel, skipOffstage: false));
    final state = panelState();
    state.text.text = 'edited';
    state.increment(7);
    state.scroll.jumpTo(400);
    await tester.pump(const Duration(seconds: 2));
    final progress = state.animation.value;
    expect(progress, greaterThan(0));

    // Tear off.
    await tester.pumpWidget(windows(floating: true), wrapWithView: false);
    expect(panelState(), same(state));
    expect(View.of(panelKey.currentContext!).viewId, 2);
    expect(state.text.text, 'edited');
    expect(state.scroll.offset, 400);
    expect(find.text('count 7'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(state.animation.value, greaterThan(progress));
    expect(state.animation.isAnimating, isTrue);

    // Dock back.
    await tester.pumpWidget(windows(floating: false), wrapWithView: false);
    expect(panelState(), same(state));
    expect(View.of(panelKey.currentContext!).viewId, 1);
    expect(state.text.text, 'edited');
    expect(state.scroll.offset, 400);
    expect(state.viewIds, [1, 2, 1]);
  });
}
