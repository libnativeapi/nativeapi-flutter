import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'palette.dart';

/// A small widgets-only slider with pointer, keyboard and semantic actions.
class ValueSlider extends StatefulWidget {
  const ValueSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.display,
    required this.onChanged,
    this.formatValue,
  });
  final String label, display;
  final double value, min, max, step;
  final ValueChanged<double> onChanged;
  final String Function(double)? formatValue;

  @override
  State<ValueSlider> createState() => _ValueSliderState();
}

class _ValueSliderState extends State<ValueSlider> {
  final _focus = FocusNode();
  bool _focused = false;
  String _describe(double value) {
    final bounded = value.clamp(widget.min, widget.max).toDouble();
    return widget.formatValue?.call(bounded) ?? bounded.toString();
  }

  void _set(double value) => widget.onChanged(
    (widget.min + ((value - widget.min) / widget.step).round() * widget.step)
        .clamp(widget.min, widget.max)
        .toDouble(),
  );
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Semantics(
      label: widget.label,
      value: widget.display,
      increasedValue: _describe(widget.value + widget.step),
      decreasedValue: _describe(widget.value - widget.step),
      slider: true,
      onIncrease: () => _set(widget.value + widget.step),
      onDecrease: () => _set(widget.value - widget.step),
      child: Focus(
        focusNode: _focus,
        onFocusChange: (value) => setState(() => _focused = value),
        onKeyEvent: (_, event) {
          if (event is KeyUpEvent) return KeyEventResult.ignored;
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowLeft ||
              key == LogicalKeyboardKey.arrowDown) {
            _set(widget.value - widget.step);
          } else if (key == LogicalKeyboardKey.arrowRight ||
              key == LogicalKeyboardKey.arrowUp) {
            _set(widget.value + widget.step);
          } else if (key == LogicalKeyboardKey.home) {
            _set(widget.min);
          } else if (key == LogicalKeyboardKey.end) {
            _set(widget.max);
          } else {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.handled;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth - 14;
            void update(Offset position) {
              _focus.requestFocus();
              if (width > 0) {
                _set(
                  widget.min +
                      ((position.dx - 7) / width).clamp(0, 1) *
                          (widget.max - widget.min),
                );
              }
            }

            final fraction =
                ((widget.value - widget.min) / (widget.max - widget.min)).clamp(
                  0.0,
                  1.0,
                );
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (event) => update(event.localPosition),
                onHorizontalDragStart: (event) => update(event.localPosition),
                onHorizontalDragUpdate: (event) => update(event.localPosition),
                child: SizedBox(
                  height: 28,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Positioned(
                        left: 7,
                        right: 7,
                        child: Container(height: 3, color: p.border),
                      ),
                      Positioned(
                        left: 7,
                        child: Container(
                          width: width.clamp(0, double.infinity) * fraction,
                          height: 3,
                          color: p.accent,
                        ),
                      ),
                      Positioned(
                        left: width.clamp(0, double.infinity) * fraction,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: p.background,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: p.accent,
                              width: _focused ? 3 : 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
