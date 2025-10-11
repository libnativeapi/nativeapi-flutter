import 'foundation/event.dart';

abstract class MenuEvent extends Event {}

abstract class MenuItemEvent extends MenuEvent {
  final int menuItemId;

  MenuItemEvent(this.menuItemId);
}

class MenuOpenedEvent extends MenuEvent {
  final int menuId;

  MenuOpenedEvent(this.menuId);
}

class MenuClosedEvent extends MenuEvent {
  final int menuId;

  MenuClosedEvent(this.menuId);
}

class MenuItemClickedEvent extends MenuItemEvent {
  MenuItemClickedEvent(super.menuItemId);
}

class MenuItemSubmenuOpenedEvent extends MenuItemEvent {
  MenuItemSubmenuOpenedEvent(super.menuItemId);
}

class MenuItemSubmenuClosedEvent extends MenuItemEvent {
  MenuItemSubmenuClosedEvent(super.menuItemId);
}
