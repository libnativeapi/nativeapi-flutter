import 'dart:io' show Platform;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'tab_layout.dart';
import 'tab_page.dart';
import 'tabs_controller.dart';

/// Provides the [TabsController] to every window.
class TabsScope extends InheritedNotifier<TabsController> {
  const TabsScope({
    super.key,
    required TabsController controller,
    required super.child,
  }) : super(notifier: controller);

  static TabsController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabsScope>()!.notifier!;

  static TabsController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TabsScope>()!.notifier!;
}

/// The content of one browser window: its tab strip and its tabs' pages.
class BrowserWindowPage extends StatelessWidget {
  const BrowserWindowPage({super.key, required this.window});

  final BrowserWindow window;

  @override
  Widget build(BuildContext context) {
    TabsScope.of(context);
    final tabs = window.tabs;
    final active = tabs.indexOf(window.activeTab);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabStrip(window: window),
          Expanded(
            // Every tab stays built, so background tabs keep running too.
            child: IndexedStack(
              index: active < 0 ? 0 : active,
              children: [
                for (final tab in tabs)
                  KeyedSubtree(
                    key: tab.pageKey,
                    child: TabPage(tab: tab),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TabStrip extends StatelessWidget {
  const TabStrip({super.key, required this.window});

  final BrowserWindow window;

  @override
  Widget build(BuildContext context) {
    final controller = TabsScope.of(context);
    final layout = controller.layout;
    final colors = Theme.of(context).colorScheme;
    final tabs = window.tabs;

    return Container(
      key: window.stripKey,
      height: TabLayout.height,
      color: colors.surfaceContainerHighest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final extent = layout.tabExtent(constraints.maxWidth, tabs.length);
          final dragged = tabs.where(controller.isDragging).toList();
          final ordered = [
            ...tabs.where((tab) => !controller.isDragging(tab)),
            ...dragged, // Paint the dragged tab on top.
          ];
          return Stack(
            children: [
              // Empty strip: moves the window, like a title bar.
              Positioned.fill(
                child: NativeDragDetector(
                  onDragStart: (pointerInView) =>
                      controller.beginWindowDrag(window, pointerInView),
                  child: const SizedBox.expand(),
                ),
              ),
              for (final tab in ordered)
                AnimatedPositioned(
                  key: ValueKey(tab.id),
                  duration: controller.draggedLeft(window, tab) != null
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  left:
                      controller.draggedLeft(window, tab) ??
                      layout.tabLeft(tabs.indexOf(tab), extent),
                  top: TabLayout.tabTop,
                  bottom: 0,
                  width: extent,
                  child: TabChip(
                    window: window,
                    tab: tab,
                    active: tab == window.activeTab,
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 160),
                left: layout.tabLeft(tabs.length, extent) + 4,
                top: TabLayout.tabTop,
                bottom: 4,
                width: TabLayout.newTabButtonWidth - 8,
                child: IconButton(
                  tooltip: 'New tab',
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: const Icon(Icons.add),
                  onPressed: () => controller.addTab(window),
                ),
              ),
              if (!Platform.isMacOS)
                Positioned(
                  right: 4,
                  top: 4,
                  bottom: 4,
                  width: 40,
                  child: IconButton(
                    tooltip: 'Close window',
                    iconSize: 18,
                    icon: const Icon(Icons.close),
                    onPressed: () => controller.closeWindow(window),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class TabChip extends StatelessWidget {
  const TabChip({
    super.key,
    required this.window,
    required this.tab,
    required this.active,
  });

  final BrowserWindow window;
  final BrowserTab tab;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final controller = TabsScope.read(context);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final lifted = controller.isDragging(tab);

    return Listener(
      onPointerDown: (_) => controller.activate(window, tab),
      child: NativeDragDetector(
        onDragStart: (pointerInView) {
          final box = context.findRenderObject()! as RenderBox;
          return controller.beginTabDrag(
            window,
            tab,
            box.globalToLocal(pointerInView),
            pointerInView,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.only(left: 10, right: 2),
          decoration: BoxDecoration(
            color: active ? colors.surface : colors.surfaceContainerHigh,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: lifted
                ? [const BoxShadow(blurRadius: 6, color: Colors.black26)]
                : null,
          ),
          child: Row(
            children: [
              Icon(Icons.circle, size: 10, color: tab.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tab.title,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: text.bodySmall?.copyWith(
                    fontWeight: active ? FontWeight.w600 : null,
                  ),
                ),
              ),
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  tooltip: 'Close tab',
                  padding: EdgeInsets.zero,
                  iconSize: 14,
                  icon: const Icon(Icons.close),
                  onPressed: () => controller.closeTab(window, tab),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Starts a native drag once the pointer moves, and then ends the pointer on
/// the Flutter side: the native session owns the rest of the gesture, and the
/// widget that saw the press may move to another window, which never sees
/// the release.
class NativeDragDetector extends StatefulWidget {
  const NativeDragDetector({
    super.key,
    required this.onDragStart,
    required this.child,
  });

  /// Called with the pointer position relative to the view. Returns whether a
  /// native drag started.
  final bool Function(Offset pointerInView) onDragStart;
  final Widget child;

  @override
  State<NativeDragDetector> createState() => _NativeDragDetectorState();
}

class _NativeDragDetectorState extends State<NativeDragDetector> {
  int? _pointer;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) => _pointer = event.pointer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (details) {
          final pointer = _pointer;
          if (widget.onDragStart(details.globalPosition) && pointer != null) {
            GestureBinding.instance.cancelPointer(pointer);
          }
        },
        child: widget.child,
      ),
    );
  }
}
