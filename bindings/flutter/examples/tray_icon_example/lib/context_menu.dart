import 'package:nativeapi/nativeapi.dart';

import 'icon_animations.dart';

/// The context menu of one tray icon.
///
/// It is small on purpose but covers every item kind the checklist needs: a
/// normal item, a checkbox, a disabled item, a separator and a submenu — and
/// the submenu is useful too: it switches the icon's animation from the tray.
class TrayMenu {
  TrayMenu({
    required MenuBackend backend,
    required void Function() onOpened,
    required void Function() onClosed,
    required void Function() onSubmenuOpened,
    required void Function(String label) onItem,
    required void Function(bool checked) onCheckbox,
    required void Function(IconAnimation? animation) onAnimation,
    required void Function() onShowWindow,
    required void Function() onQuit,
  }) : menu = Menu.create()! {
    menu.setBackend(backend);
    menu.addListener((event) {
      if (event is MenuOpenedEvent) {
        isOpen = true;
        onOpened();
      } else if (event is MenuClosedEvent) {
        isOpen = false;
        onClosed();
      }
    });

    _add(menu, 'Show window', onShowWindow);
    _separator(menu);

    final animations = Menu.create()!;
    for (final animation in IconAnimation.values) {
      _add(animations, animation.label, () => onAnimation(animation));
    }
    _separator(animations);
    _add(animations, 'Stop', () => onAnimation(null));
    final animate = MenuItem.createWithLabelAndType(
      'Animate',
      MenuItemType.submenu,
    )!;
    animate.submenu = animations;
    animate.addListener((event) {
      if (event is MenuItemSubmenuOpenedEvent) onSubmenuOpened();
    });
    menu.addItem(animate);
    _keep.addAll([animations, animate]);

    final checkbox = MenuItem.createWithLabelAndType(
      'Notifications',
      MenuItemType.checkbox,
    )!;
    checkbox.state = MenuItemState.checked;
    checkbox.addListener((event) {
      if (event is! MenuItemClickedEvent) return;
      final checked = checkbox.state != MenuItemState.checked;
      checkbox.state = checked
          ? MenuItemState.checked
          : MenuItemState.unchecked;
      onCheckbox(checked);
    });
    menu.addItem(checkbox);
    _keep.add(checkbox);

    final disabled = MenuItem.createWithLabelAndType(
      'Check for updates',
      MenuItemType.normal,
    )!;
    disabled.isEnabled = false;
    menu.addItem(disabled);
    _keep.add(disabled);

    _add(menu, 'About', () => onItem('About'));
    _separator(menu);
    _add(menu, 'Quit', onQuit);
  }

  final Menu menu;

  /// Tracked from the opened/closed events.
  bool isOpen = false;

  // Keeps the Dart wrappers (and their listeners) alive with the menu.
  final List<Object> _keep = [];

  void _add(Menu parent, String label, void Function() onClicked) {
    final item = MenuItem.createWithLabelAndType(label, MenuItemType.normal)!;
    item.addListener((event) {
      if (event is MenuItemClickedEvent) onClicked();
    });
    parent.addItem(item);
    _keep.add(item);
  }

  void _separator(Menu parent) {
    final item = MenuItem.createWithLabelAndType('', MenuItemType.separator)!;
    parent.addItem(item);
    _keep.add(item);
  }
}
