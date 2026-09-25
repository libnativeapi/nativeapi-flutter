// The layout engine on display: four boxes in a stage whose layout, alignment,
// spacing and padding the buttons change, with the frames the layout pass
// computed read back underneath.

import 'dart:math' as math;

import 'package:nativeapi/nativeapi.dart';

import 'event_log.dart';
import 'theme.dart';
import 'ui.dart';

final class _Box {
  _Box(this.name, this.flex, this.shade);

  final String name;
  final double flex;

  /// Alpha of the accent colour, so the boxes tell apart.
  final int shade;
  late final View view;
  late final Label caption;
}

final class PlaygroundSection {
  PlaygroundSection() {
    _stage = container(
      'playground.stage',
      layout: _layout,
      spacing: _spacing,
      padding: all(_padding),
      size: const Size(width: 0, height: 150),
      background: const Color(r: 128, g: 128, b: 128, a: 30),
    );
    for (final box in _boxes) {
      box.caption = label(
        'playground.${box.name}.caption',
        '${box.name}\nflex ${box.flex.toInt()}',
        color: white,
        fontSize: 11,
        align: TextAlignment.center,
      );
      box.view = container(
        'playground.${box.name}',
        padding: all(4),
        // The size a box asks for: kept on the main axis when flex is 0, and
        // used on the cross axis unless the alignment is stretch.
        size: const Size(width: 64, height: 40),
        children: [box.caption],
      )..flex = box.flex;
      box.view.tooltip = 'Box ${box.name}, flex ${box.flex.toInt()}';
      _stage.addSubview(box.view);
    }

    _layoutButton = button('playground.layout', '', () {
      _layout = _layout == ViewLayout.row ? ViewLayout.column : ViewLayout.row;
      _apply('layout → ${_layout.name}');
    });
    _alignButton = button('playground.align', '', () {
      _alignment = ViewAlignment
          .values[(_alignment.index + 1) % ViewAlignment.values.length];
      _apply('alignment → ${_alignment.name}');
    });
    _spacingButton = button('playground.spacing', '', () {
      _spacing = (_spacing + 8) % 32;
      _apply('spacing → ${_spacing.toInt()}');
    });
    _paddingButton = button('playground.padding', '', () {
      _padding = (_padding + 8) % 32;
      _apply('padding → ${_padding.toInt()}');
    });
    _hideButton = button('playground.hideB', '', () {
      final b = _boxes[1].view;
      b.isVisible = !b.isVisible;
      _apply('box B ${b.isVisible ? 'shown' : 'hidden'}');
    }, tooltip: 'A hidden view takes no space in a row or column');
    final shuffle = button('playground.shuffle', 'Shuffle', _shuffle);

    _frames = label('playground.frames', '', color: muted, fontSize: 11);

    view = section(
      'playground',
      'Layout playground',
      column(
        'playground.body',
        spacing: 8,
        children: [
          row(
            'playground.controls',
            spacing: 6,
            children: [
              _layoutButton,
              _alignButton,
              spacer('playground.controls.fill'),
              _hideButton,
              shuffle,
            ],
          ),
          row(
            'playground.metrics',
            spacing: 6,
            children: [_spacingButton, _paddingButton],
          ),
          _stage,
          _frames,
        ],
      ),
    );
    theme.bind((accent) {
      for (final box in _boxes) {
        box.view.backgroundColor = wash(accent.color, box.shade);
      }
    });
    _apply(null);
  }

  late final View view;
  late final View _stage;
  late final Button _layoutButton;
  late final Button _alignButton;
  late final Button _spacingButton;
  late final Button _paddingButton;
  late final Button _hideButton;
  late final Label _frames;

  final _boxes = [
    _Box('A', 0, 255),
    _Box('B', 1, 200),
    _Box('C', 2, 150),
    _Box('D', 0, 110),
  ];
  final _random = math.Random(7);
  var _layout = ViewLayout.row;
  var _alignment = ViewAlignment.stretch;
  double _spacing = 8;
  double _padding = 8;

  void _shuffle() {
    _boxes.shuffle(_random);
    // clearSubviews() detaches; adding them back in the new order is all a
    // reorder takes.
    _stage.clearSubviews();
    for (final box in _boxes) {
      _stage.addSubview(box.view);
    }
    _apply('order → ${_boxes.map((box) => box.name).join()}');
  }

  void _apply(String? change) {
    _stage
      ..layout = _layout
      ..spacing = _spacing
      ..padding = all(_padding);
    for (final box in _boxes) {
      box.view.alignment = _alignment;
    }
    _layoutButton.text = _layout == ViewLayout.row ? 'Row' : 'Column';
    _alignButton.text = 'Align: ${_alignment.name}';
    _spacingButton.text = 'Gap ${_spacing.toInt()}';
    _paddingButton.text = 'Pad ${_padding.toInt()}';
    _hideButton.text = _boxes[1].view.isVisible ? 'Hide B' : 'Show B';
    if (change != null) eventLog.note('playground', change);
    refreshFrames();
  }

  /// Reads back what the last layout pass did. Called again when the window
  /// is resized, since the flexible boxes follow its width.
  void refreshFrames() {
    String describe(_Box box) {
      if (!box.view.isVisible) return '${box.name} hidden';
      final f = box.view.frame;
      return '${box.name} ${f.x.round()},${f.y.round()} '
          '${f.width.round()}×${f.height.round()}';
    }

    _frames.text = _boxes.map(describe).join('   ');
  }
}
