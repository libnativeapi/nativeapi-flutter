import 'package:flutter/widgets.dart';
import 'package:nativeapi/nativeapi.dart' show WindowManager;

import 'tabs/animate_tab.dart';
import 'tabs/checklist_tab.dart';
import 'tabs/properties_tab.dart';
import 'tray_controller.dart';
import 'widgets/event_footer.dart';
import 'widgets/live_preview.dart';
import 'widgets/option_chip.dart';
import 'widgets/palette.dart';

// The example is built on package:flutter/widgets.dart alone — no component
// library — so everything on screen is a few dozen lines you can read here.
//
//   tray_controller.dart   every TrayIcon / TrayManager call, scenes, events
//   icon_animator.dart     canvas or widget → PNG → TrayIcon.icon, per frame
//   icon_animations.dart   what the frames look like
//   context_menu.dart      the tray menu
//   checklist.dart         the acceptance checklist

void main() {
  runApp(const TrayIconExampleApp());
}

class TrayIconExampleApp extends StatelessWidget {
  const TrayIconExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Tray icon example',
      color: Palette.light.accent,
      debugShowCheckedModeBanner: false,
      builder: (context, _) {
        final palette = Palette.of(context);
        return DefaultTextStyle(
          style: TextStyle(fontSize: 12, height: 1.3, color: palette.text),
          child: Overlay(
            initialEntries: [OverlayEntry(builder: (_) => const Shell())],
          ),
        );
      },
    );
  }
}

enum _Tab { animate, properties, checklist }

/// Icons strip, live preview, three tabs, event footer.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final TrayController _controller = TrayController();
  _Tab _tab = _Tab.animate;
  _TextEdit? _edit;

  @override
  void initState() {
    super.initState();
    // The layout is made for exactly this content size. The runners' default
    // size does not always give it (on Windows it includes the title bar), so
    // correct it — but only when it is off: where the view already is right
    // (macOS, Linux) the window is left alone.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      const wanted = Size(400, 640);
      final view = MediaQuery.sizeOf(context);
      if ((view.width - wanted.width).abs() > 0.5 ||
          (view.height - wanted.height).abs() > 0.5) {
        WindowManager.instance.getCurrent()?.contentSize = wanted;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _controller.checklist]),
      builder: (context, _) => ColoredBox(
        color: palette.background,
        child: Stack(
          children: [
            Column(
              children: [
                _iconsStrip(palette),
                LivePreview(controller: _controller),
                _tabBar(palette),
                Expanded(
                  child: switch (_tab) {
                    _Tab.animate => AnimateTab(controller: _controller),
                    _Tab.properties => PropertiesTab(
                      controller: _controller,
                      onEdit: (title, initial, onSubmit) => setState(
                        () => _edit = _TextEdit(title, initial, onSubmit),
                      ),
                    ),
                    _Tab.checklist => ChecklistTab(
                      checklist: _controller.checklist,
                    ),
                  },
                ),
                EventFooter(controller: _controller),
              ],
            ),
            if (_edit != null)
              _TextEditor(
                edit: _edit!,
                onDone: () => setState(() => _edit = null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconsStrip(Palette palette) {
    final selected = _controller.selected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Tray icons',
                  style: TextStyle(fontSize: 11, color: palette.muted),
                ),
                const SizedBox(width: 3),
                for (final entry in _controller.entries)
                  OptionChip(
                    label: '#${entry.number}',
                    selected: entry == selected,
                    onTap: () => _controller.select(entry),
                  ),
                OptionChip(label: 'Add icon', onTap: _controller.addIcon),
              ],
            ),
          ),
          OptionChip(
            label: selected == null ? 'Remove' : 'Remove #${selected.number}',
            onTap: selected == null
                ? null
                : () => _controller.removeIcon(selected),
          ),
        ],
      ),
    );
  }

  Widget _tabBar(Palette palette) {
    final checklist = _controller.checklist;
    final labels = {
      _Tab.animate: 'Animate',
      _Tab.properties: 'Properties',
      _Tab.checklist: 'Checklist ${checklist.passed}/${checklist.items.length}',
    };
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          for (final MapEntry(:key, :value) in labels.entries)
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _tab = key),
                  child: Container(
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 2,
                          color: key == _tab
                              ? palette.accent
                              : const Color(0x00000000),
                        ),
                      ),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: key == _tab
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: key == _tab
                            ? (checklist.failed > 0 && key == _Tab.checklist
                                  ? palette.danger
                                  : palette.text)
                            : (checklist.failed > 0 && key == _Tab.checklist
                                  ? palette.danger
                                  : palette.muted),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TextEdit {
  _TextEdit(this.title, this.initial, this.onSubmit);

  final String title;
  final String initial;
  final ValueChanged<String> onSubmit;
}

/// A one-field editor over the window, for values the preset chips don't
/// cover. Scripts never need it: every preset is a click.
class _TextEditor extends StatefulWidget {
  const _TextEditor({required this.edit, required this.onDone});

  final _TextEdit edit;
  final VoidCallback onDone;

  @override
  State<_TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<_TextEditor> {
  late final TextEditingController _text = TextEditingController(
    text: widget.edit.initial,
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _text.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _text.text.length,
    );
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    widget.edit.onSubmit(_text.text);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDone,
        child: ColoredBox(
          color: const Color(0x66000000),
          child: Center(
            child: GestureDetector(
              onTap: _focus.requestFocus,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.edit.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: palette.accent),
                      ),
                      child: EditableText(
                        controller: _text,
                        focusNode: _focus,
                        autofocus: true,
                        style: TextStyle(fontSize: 13, color: palette.text),
                        cursorColor: palette.accent,
                        backgroundCursorColor: palette.muted,
                        selectionColor: palette.accentSurface,
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OptionChip(label: 'Cancel', onTap: widget.onDone),
                        const SizedBox(width: 6),
                        OptionChip(
                          label: 'Apply',
                          selected: true,
                          onTap: _submit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
