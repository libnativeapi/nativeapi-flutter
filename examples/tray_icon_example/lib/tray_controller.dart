import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' hide Image;
import 'package:flutter/services.dart';
import 'package:nativeapi/nativeapi.dart';

import 'checklist.dart';
import 'context_menu.dart';
import 'icon_animations.dart';
import 'icon_animator.dart';

const String kAssetIcon = 'images/tray_icon.png';
const String kDefaultTooltip = 'nativeapi tray icon';

/// A 36 px diamond, embedded to show `Image.fromBase64` with a literal.
const String kDiamondPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAACQAAAAkCAYAAADhAJiYAAAAfklEQVR42u3YywrAIAxEUf//'
    'p9NNt4ViHj1QB2Yn4UrUJK519FPFbQqGgIoHUzCfQMVLUzAjULFpCqYFKoo8BrOzth2mHSoT'
    'uByqImAZVOXu0rE68p+KyQFxKSMPNXntyYeRLB1kcSXbD7JBI1tYssknxyByUCRHafKz4WhU'
    'F0LqioTWhQw+AAAAAElFTkSuQmCC';

/// Where a still icon comes from: a bundled file, a canvas drawing, or a
/// base64 literal.
enum StillIcon { asset, drawn, base64 }

enum Scene { download, recording, syncing }

/// One tray icon together with everything the example tracks about it.
class TrayEntry {
  TrayEntry(this.number, this.trayIcon);

  /// 1-based number shown in the UI ("#1"); not the native id.
  final int number;
  final TrayIcon trayIcon;
  late final TrayMenu menu;
  late final IconAnimator animator;

  int clicks = 0;
  int rightClicks = 0;
  int doubleClicks = 0;
  StillIcon? still = StillIcon.asset;
  Scene? scene;
}

/// Owns the tray icons and is the only place that calls the tray API.
class TrayController extends ChangeNotifier {
  TrayController() {
    if (Menu.isBackendSupported(MenuBackend.winUi3)) {
      _menuBackend = MenuBackend.winUi3;
    }
    supported = TrayManager.instance.isSupported();
    if (supported) {
      checklist.pass(Checklist.supported, 'true');
    } else {
      checklist.fail(Checklist.supported, 'false');
    }
    addIcon();
    _sceneTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _driveScenes(),
    );
  }

  final Checklist checklist = Checklist();
  final List<TrayEntry> entries = [];
  final List<String> log = [];

  late final bool supported;
  int managerCount = 0;

  /// Headline of the event footer: the last tray or menu event.
  String lastEvent = 'No events yet';

  TrayEntry? get selected => _selected;
  TrayEntry? _selected;

  MenuBackend get menuBackend => _menuBackend;
  MenuBackend _menuBackend = MenuBackend.native;

  int _nextNumber = 1;
  late final Timer _sceneTimer;

  // Bookkeeping for the "which trigger opened the menu" check.
  ContextMenuTrigger? _lastTrayEvent;
  DateTime _lastTrayEventAt = DateTime(0);
  DateTime _lastOpenCallAt = DateTime(0);
  Timer? _closeWatch;

  /// Windows tray icons have no title: core's SetTitle is a no-op there and
  /// GetTitle returns nothing, so the title is left out of the read-back check.
  static bool get titleSupported => !Platform.isWindows;

  /// Icon colour when the user picks "Auto". macOS ignores colour anyway (the
  /// image is used as a template); elsewhere the tray is usually dark.
  static Color get autoColor =>
      Platform.isMacOS ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------
  // Icons
  // ---------------------------------------------------------------------

  TrayEntry? addIcon() {
    final trayIcon = TrayIcon.create();
    if (trayIcon == null) {
      checklist.fail(Checklist.create, 'create returned null');
      _log('TrayIcon.create() returned null');
      return null;
    }
    final entry = TrayEntry(_nextNumber++, trayIcon);
    entry.animator = IconAnimator(
      onFrame: (image) => trayIcon.icon = image,
      onMilestone: (animator) => _onFrameMilestone(entry, animator),
    )..setColor(autoColor);
    entry.menu = TrayMenu(
      backend: _menuBackend,
      onOpened: () => _onMenuOpened(entry),
      onClosed: () => _onMenuClosed(entry),
      onSubmenuOpened: () {
        checklist.part(Checklist.menuItems, 'submenu', 3);
        _event('Submenu opened', entry);
      },
      onItem: (label) {
        checklist.part(Checklist.menuItems, 'item', 3);
        _event('Menu item "$label"', entry);
      },
      onCheckbox: (checked) {
        checklist.part(Checklist.menuItems, 'checkbox', 3);
        _event('Checkbox ${checked ? 'checked' : 'unchecked'}', entry);
      },
      onAnimation: (animation) {
        _event('Menu item "${animation?.label ?? 'Stop'}"', entry);
        checklist.part(Checklist.menuItems, 'item', 3);
        if (animation == null) {
          setStill(StillIcon.asset, entry);
        } else {
          play(animation, entry);
        }
      },
      onShowWindow: () {
        checklist.part(Checklist.menuItems, 'item', 3);
        _event('Menu item "Show window"', entry);
        final window = WindowManager.instance.getCurrent();
        window?.show();
        window?.focus();
      },
      onQuit: () {
        disposeIcons();
        exit(0);
      },
    );

    trayIcon.addListener((event) => _onTrayEvent(entry, event));
    trayIcon.setContextMenu(entry.menu.menu);
    trayIcon.setTooltip(kDefaultTooltip);
    trayIcon.setContextMenuTrigger(ContextMenuTrigger.rightClicked);
    trayIcon.setVisible(true);

    entries.add(entry);
    _selected = entry;
    setStill(StillIcon.asset, entry, true);

    _refreshManager();
    checklist.pass(Checklist.create, 'id ${trayIcon.getId()}');
    final known = TrayManager.instance.get(trayIcon.getId()) != null;
    if (known && managerCount == entries.length) {
      checklist.pass(Checklist.managed, '$managerCount in getAll');
    } else {
      checklist.fail(
        Checklist.managed,
        'get ${known ? 'ok' : 'null'}, getAll $managerCount/${entries.length}',
      );
    }
    _log('create #${entry.number} → id ${trayIcon.getId()}');
    notifyListeners();
    return entry;
  }

  void removeIcon(TrayEntry entry) {
    final index = entries.indexOf(entry);
    if (index < 0) return;
    entries.removeAt(index);
    entry.animator.dispose();
    entry.trayIcon.dispose();
    if (_selected == entry) {
      _selected = entries.isEmpty
          ? null
          : entries[index.clamp(0, entries.length - 1)];
    }
    _refreshManager();
    _log('dispose #${entry.number}');
    notifyListeners();
  }

  void select(TrayEntry entry) {
    _selected = entry;
    notifyListeners();
  }

  /// Re-reads everything that is shown from native getters.
  void refresh() {
    _refreshManager();
    final entry = _selected;
    if (entry != null) {
      final bounds = entry.trayIcon.getBounds();
      if (bounds.isEmpty) {
        checklist.fail(Checklist.bounds, 'empty');
      } else {
        checklist.pass(
          Checklist.bounds,
          '${bounds.width.round()}×${bounds.height.round()}',
        );
      }
    }
    notifyListeners();
  }

  void disposeIcons() {
    _sceneTimer.cancel();
    for (final entry in entries) {
      entry.animator.dispose();
      entry.trayIcon.dispose();
    }
    entries.clear();
  }

  @override
  void dispose() {
    disposeIcons();
    super.dispose();
  }

  void _refreshManager() {
    managerCount = TrayManager.instance.getAll().length;
  }

  // ---------------------------------------------------------------------
  // Icon image: animations and stills
  // ---------------------------------------------------------------------

  void play(IconAnimation animation, [TrayEntry? target, bool quiet = false]) {
    final entry = target ?? _selected;
    if (entry == null) return;
    if (!quiet) entry.scene = null;
    entry.still = null;
    entry.animator.play(animation);
    if (!quiet) {
      _log(
        'animate #${entry.number} ${animation.name} ${entry.animator.fps} fps',
      );
    }
    notifyListeners();
  }

  Future<void> setStill(
    StillIcon kind, [
    TrayEntry? target,
    bool quiet = false,
  ]) async {
    final entry = target ?? _selected;
    if (entry == null) return;
    if (!quiet) entry.scene = null;
    entry.animator.stop();
    entry.still = kind;
    notifyListeners();

    final Image? native;
    final Uint8List png;
    switch (kind) {
      case StillIcon.asset:
        native = ImageAsset.fromAsset(kAssetIcon);
        png = (await rootBundle.load(kAssetIcon)).buffer.asUint8List();
      case StillIcon.drawn:
        png = await _renderStar(entry);
        native = Image.fromBase64('data:image/png;base64,${base64Encode(png)}');
      case StillIcon.base64:
        png = base64Decode(kDiamondPngBase64);
        native = Image.fromBase64('data:image/png;base64,$kDiamondPngBase64');
    }
    if (entry.still != kind || !entries.contains(entry)) return;
    if (native == null) {
      _log('icon #${entry.number} ${kind.name}: image failed to load');
      return;
    }
    entry.trayIcon.icon = native;

    final codec = await ui.instantiateImageCodec(png);
    final preview = (await codec.getNextFrame()).image;
    if (entry.still != kind || !entries.contains(entry)) {
      preview.dispose();
      return;
    }
    entry.animator.showStill(preview);
    if (!quiet) _log('icon #${entry.number} ← ${kind.name}');
  }

  /// The star still: drawn on a canvas, encoded as PNG.
  Future<Uint8List> _renderStar(TrayEntry entry) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(entry.animator.scale.toDouble());
    paintStar(canvas, kIconPoints, entry.animator.color);
    final size = entry.animator.pixelSize;
    final image = await recorder.endRecording().toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  void setFps(int fps) {
    _selected?.animator.setFps(fps);
    _log('rate #${_selected?.number} ← $fps fps');
  }

  void setScale(int scale) {
    final entry = _selected;
    if (entry == null) return;
    entry.animator.setScale(scale);
    _log('resolution #${entry.number} ← ${entry.animator.pixelSize} px');
    final still = entry.still;
    if (still != null) setStill(still, entry, true);
  }

  void setColor(Color color) {
    final entry = _selected;
    if (entry == null) return;
    entry.animator.setColor(color);
    final still = entry.still;
    if (still != null) setStill(still, entry, true);
  }

  void _onFrameMilestone(TrayEntry entry, IconAnimator animator) {
    final detail =
        '${animator.measuredFps.toStringAsFixed(1)}/${animator.fps} fps, '
        '${animator.dropped} dropped';
    final onTarget = animator.measuredFps >= animator.fps * 0.9;
    if (onTarget && animator.dropped == 0) {
      checklist.pass(Checklist.frames, detail);
    } else if (checklist[Checklist.frames].status != CheckStatus.pass) {
      checklist.fail(Checklist.frames, detail);
    }
  }

  // ---------------------------------------------------------------------
  // Properties
  // ---------------------------------------------------------------------

  void setTitle(String? title, {bool fromScene = false}) {
    final entry = _selected;
    if (entry == null) return;
    if (!fromScene) entry.scene = null;
    _applyTitle(entry, title);
    _log('setTitle(${_quote(title)}) #${entry.number}');
    if (titleSupported) {
      _checkReadBack('title', title, entry.trayIcon.getTitle());
    }
    notifyListeners();
  }

  void _applyTitle(TrayEntry entry, String? title) {
    entry.trayIcon.setTitle(title);
  }

  void setTooltip(String? tooltip) {
    final entry = _selected;
    if (entry == null) return;
    entry.trayIcon.setTooltip(tooltip);
    _log('setTooltip(${_quote(tooltip)}) #${entry.number}');
    _checkReadBack('tooltip', tooltip, entry.trayIcon.getTooltip());
    notifyListeners();
  }

  void _checkReadBack(String what, String? written, String? read) {
    // A cleared value may read back as null or as an empty string — and proves
    // nothing, so only a real value counts towards the item.
    if ((written ?? '') == (read ?? '')) {
      if ((written ?? '').isNotEmpty) {
        checklist.part(Checklist.readBack, what, titleSupported ? 2 : 1);
      }
    } else {
      checklist.fail(
        Checklist.readBack,
        '$what: wrote ${_quote(written)}, read ${_quote(read)}',
      );
    }
  }

  void setVisible(bool visible) {
    final entry = _selected;
    if (entry == null) return;
    final result = entry.trayIcon.setVisible(visible);
    final read = entry.trayIcon.isVisible();
    _log('setVisible($visible) #${entry.number} → $result');
    if (read == visible) {
      checklist.part(Checklist.visible, '$visible', 2);
    } else {
      checklist.fail(Checklist.visible, 'set $visible, isVisible $read');
    }
    notifyListeners();
  }

  void setTrigger(ContextMenuTrigger trigger) {
    final entry = _selected;
    if (entry == null) return;
    entry.trayIcon.setContextMenuTrigger(trigger);
    _log('setContextMenuTrigger(${trigger.name}) #${entry.number}');
    notifyListeners();
  }

  void setMenuBackend(MenuBackend backend) {
    for (final entry in entries) {
      if (!entry.menu.menu.setBackend(backend)) {
        _log('setBackend(${backend.name}) #${entry.number} → false');
        return;
      }
    }
    _menuBackend = backend;
    _log('menu backend ← ${backend.name}');
    notifyListeners();
  }

  /// Opens the menu; with [closeAfter] also closes it again from code. A
  /// button cannot do that — the window gets no clicks while a menu is open.
  void openMenu({Duration? closeAfter}) {
    final entry = _selected;
    if (entry == null) return;
    if (closeAfter != null) {
      Timer(closeAfter, () => _closeMenu(entry));
    }
    _lastOpenCallAt = DateTime.now();
    final opened = entry.trayIcon.openContextMenu();
    _log('openContextMenu() #${entry.number} → $opened');
    if (opened) {
      checklist.pass(Checklist.openMenu);
    } else {
      checklist.fail(Checklist.openMenu, 'returned false');
    }
    notifyListeners();
  }

  void _closeMenu(TrayEntry entry) {
    if (!entries.contains(entry)) return;
    final wasOpen = entry.menu.isOpen;
    final closed = entry.trayIcon.closeContextMenu();
    _log('closeContextMenu() #${entry.number} → $closed');
    if (!wasOpen) {
      // Dismissed by hand before the timer fired: nothing to judge.
      notifyListeners();
      return;
    }
    if (!entry.menu.isOpen) {
      // The closed event arrived while closeContextMenu() was running.
      checklist.pass(Checklist.closeMenu, 'closed event received');
      notifyListeners();
      return;
    }
    _closeWatch?.cancel();
    _closeWatch = Timer(const Duration(milliseconds: 1500), () {
      if (entry.menu.isOpen) {
        checklist.fail(Checklist.closeMenu, 'no closed event');
      }
    });
    notifyListeners();
  }

  /// Moves the window next to the selected icon, the way a tray popup would:
  /// below it where the tray is at the top of the screen (macOS, GNOME), above
  /// it where the tray is at the bottom (Windows), centred on the icon and
  /// kept inside the display's work area.
  void moveWindowToIcon() {
    final entry = _selected;
    final window = WindowManager.instance.getCurrent();
    if (entry == null || window == null) return;
    final icon = entry.trayIcon.getBounds();
    if (icon.isEmpty) {
      _log('window to icon #${entry.number}: getBounds is empty');
      return;
    }
    final displays = DisplayManager.instance.getAll();
    final display = displays.firstWhere(
      (d) => (d.position & d.size).contains(icon.center),
      orElse: () => DisplayManager.instance.getPrimary() ?? displays.first,
    );
    final screen = display.position & display.size;
    final area = display.workArea;
    final size = window.size;
    const gap = 8.0;
    final below = icon.center.dy < screen.center.dy;
    final x = (icon.center.dx - size.width / 2).clamp(
      area.left + gap,
      area.right - size.width - gap,
    );
    final y = below
        ? (icon.bottom + gap).clamp(area.top + gap, area.bottom - size.height)
        : (icon.top - gap - size.height).clamp(
            area.top,
            area.bottom - size.height - gap,
          );
    window.position = Offset(x.toDouble(), y.toDouble());
    _log(
      'window to icon #${entry.number}: ${below ? 'below' : 'above'} '
      '${x.round()},${y.round()}',
    );
    notifyListeners();
  }

  void resetCounters() {
    final entry = _selected;
    if (entry == null) return;
    entry.clicks = entry.rightClicks = entry.doubleClicks = 0;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Scenes: one click, a complete picture for the camera
  // ---------------------------------------------------------------------

  void playScene(Scene scene) {
    final entry = _selected;
    if (entry == null) return;
    entry.scene = scene;
    switch (scene) {
      case Scene.download:
        play(IconAnimation.progress, entry, true);
        entry.trayIcon.setTooltip('Downloading nativeapi.zip');
      case Scene.recording:
        play(IconAnimation.blink, entry, true);
        entry.trayIcon.setTooltip('Recording — click to stop');
      case Scene.syncing:
        play(IconAnimation.spinner, entry, true);
        entry.trayIcon.setTitle('Syncing…');
        entry.trayIcon.setTooltip('Syncing 3 folders');
    }
    _log('scene #${entry.number} ← ${scene.name}');
    _driveScenes();
  }

  /// Back to the asset icon, no title, default tooltip.
  void resetScene() {
    final entry = _selected;
    if (entry == null) return;
    entry.scene = null;
    entry.trayIcon.setTitle(null);
    entry.trayIcon.setTooltip(kDefaultTooltip);
    setStill(StillIcon.asset, entry, true);
    _log('scene #${entry.number} ← default');
  }

  /// Three icons, three different animations, all running together.
  void playThreeAtOnce() {
    while (entries.length < 3) {
      if (addIcon() == null) return;
    }
    const animations = [
      IconAnimation.spinner,
      IconAnimation.wave,
      IconAnimation.clock,
    ];
    for (var i = 0; i < 3; i++) {
      entries[i].scene = null;
      play(animations[i], entries[i], true);
    }
    _selected = entries.first;
    _log('scene ← three icons');
    notifyListeners();
  }

  // Keeps scene titles in step with the animation they belong to.
  void _driveScenes() {
    var changed = false;
    for (final entry in entries) {
      final t = entry.animator.time.value;
      final String? title = switch (entry.scene) {
        Scene.download => '${(IconAnimation.progressAt(t) * 100).round()}%',
        Scene.recording =>
          '${(t ~/ 60).toString().padLeft(2, '0')}:'
              '${(t.floor() % 60).toString().padLeft(2, '0')}',
        _ => null,
      };
      if (title != null && entry.trayIcon.getTitle() != title) {
        _applyTitle(entry, title);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------

  void _onTrayEvent(TrayEntry entry, TrayIconEvent event) {
    if (event is TrayIconClickedEvent) {
      entry.clicks++;
      checklist.count(Checklist.clicked);
      _noteTrayEvent(ContextMenuTrigger.clicked);
      _event('Clicked', entry);
    } else if (event is TrayIconRightClickedEvent) {
      entry.rightClicks++;
      checklist.count(Checklist.rightClicked);
      _noteTrayEvent(ContextMenuTrigger.rightClicked);
      _event('Right clicked', entry);
    } else if (event is TrayIconDoubleClickedEvent) {
      entry.doubleClicks++;
      checklist.count(Checklist.doubleClicked);
      _noteTrayEvent(ContextMenuTrigger.doubleClicked);
      _event('Double clicked', entry);
    }
  }

  void _noteTrayEvent(ContextMenuTrigger trigger) {
    _lastTrayEvent = trigger;
    _lastTrayEventAt = DateTime.now();
  }

  void _onMenuOpened(TrayEntry entry) {
    _event('Menu opened', entry);
    // Credit the trigger that is configured, if its event just happened.
    final now = DateTime.now();
    bool recent(DateTime at) => now.difference(at).inMilliseconds < 1500;
    final trigger = entry.trayIcon.getContextMenuTrigger();
    if (trigger == ContextMenuTrigger.none) {
      if (recent(_lastOpenCallAt)) {
        checklist.part(Checklist.triggers, trigger.name, 4);
      }
    } else if (trigger == _lastTrayEvent && recent(_lastTrayEventAt)) {
      checklist.part(Checklist.triggers, trigger.name, 4);
    }
  }

  void _onMenuClosed(TrayEntry entry) {
    _event('Menu closed', entry);
    checklist.count(Checklist.menuOpenClose);
    if (_closeWatch?.isActive ?? false) {
      _closeWatch!.cancel();
      checklist.pass(Checklist.closeMenu, 'closed event received');
    }
  }

  void _event(String what, TrayEntry entry) {
    lastEvent = '$what · #${entry.number}';
    _log('${what.toLowerCase()} #${entry.number}');
  }

  void clearLog() {
    log.clear();
    lastEvent = 'No events yet';
    notifyListeners();
  }

  void _log(String message) {
    final time = DateTime.now().toString().substring(11, 19);
    log.insert(0, '$time $message');
    if (log.length > 200) log.removeLast();
    notifyListeners();
  }

  static String _quote(String? value) =>
      value == null ? 'null' : '"${value.replaceAll('\n', r'\n')}"';
}
