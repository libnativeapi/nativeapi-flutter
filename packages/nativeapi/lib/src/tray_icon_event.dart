import 'foundation/event.dart';

abstract class TrayIconEvent extends Event {}

class TrayIconClickedEvent extends TrayIconEvent {}

class TrayIconRightClickedEvent extends TrayIconEvent {}

class TrayIconDoubleClickedEvent extends TrayIconEvent {}
