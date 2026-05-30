import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Window Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        cardTheme: const CardThemeData(elevation: 2, margin: EdgeInsets.all(8)),
      ),
      debugShowCheckedModeBanner: false,
      home: const WindowManagerPage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Event log entry
// ---------------------------------------------------------------------------
class _LogEntry {
  final DateTime timestamp = DateTime.now();
  final String message;
  final Color color;

  _LogEntry(this.message, {this.color = Colors.black87});

  String get formattedTime {
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$m:$s.$ms';
  }
}

// ---------------------------------------------------------------------------
// Main page
// ---------------------------------------------------------------------------
class WindowManagerPage extends StatefulWidget {
  const WindowManagerPage({super.key});

  @override
  State<WindowManagerPage> createState() => _WindowManagerPageState();
}

class _WindowManagerPageState extends State<WindowManagerPage>
    with SingleTickerProviderStateMixin {
  // --- data ---
  List<Window> _windows = [];
  List<Display> _displays = [];
  Window? _selectedWindow;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _updateTimer;
  final List<int> _windowListenerIds = [];

  // --- event log ---
  final List<_LogEntry> _eventLog = [];
  static const int _maxLogEntries = 200;

  // --- tab ---
  late final TabController _tabController;

  // --- action feedback ---
  String? _actionFeedback;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDisplays();
    _loadWindows();
    _startTracking();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _feedbackTimer?.cancel();
    _tabController.dispose();
    final windowManager = WindowManager.instance;
    for (final id in _windowListenerIds) {
      windowManager.removeListener(id);
    }
    _windowListenerIds.clear();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Feedback
  // -----------------------------------------------------------------------
  void _showFeedback(String message, {Color color = Colors.green}) {
    _feedbackTimer?.cancel();
    if (mounted) {
      setState(() {
        _actionFeedback = message;
        _feedbackColor = color;
      });
    }
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _actionFeedback = null);
    });
  }

  Color _feedbackColor = Colors.green;

  void _addLog(String message, {Color color = Colors.black87}) {
    setState(() {
      _eventLog.insert(0, _LogEntry(message, color: color));
      if (_eventLog.length > _maxLogEntries) {
        _eventLog.removeLast();
      }
    });
  }

  // -----------------------------------------------------------------------
  // Tracking
  // -----------------------------------------------------------------------
  void _startTracking() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) _updateWindows();
    });

    final wm = WindowManager.instance;
    _windowListenerIds.addAll([
      wm.addCallbackListener<WindowCreatedEvent>((e) {
        _addLog('Window #${e.windowId} created', color: Colors.green);
        _updateWindows();
      }),
      wm.addCallbackListener<WindowClosedEvent>((e) {
        _addLog('Window #${e.windowId} closed', color: Colors.red);
        _updateWindows();
      }),
      wm.addCallbackListener<WindowFocusedEvent>((e) {
        _addLog('Window #${e.windowId} focused', color: Colors.indigo);
        _updateWindows();
        _refreshSelected(e.windowId);
      }),
      wm.addCallbackListener<WindowBlurredEvent>((e) {
        _addLog('Window #${e.windowId} blurred', color: Colors.grey);
        _refreshSelected(e.windowId);
      }),
      wm.addCallbackListener<WindowMinimizedEvent>((e) {
        _addLog('Window #${e.windowId} minimized', color: Colors.orange);
        _updateWindows();
        _refreshSelected(e.windowId);
      }),
      wm.addCallbackListener<WindowMaximizedEvent>((e) {
        _addLog('Window #${e.windowId} maximized', color: Colors.purple);
        _updateWindows();
        _refreshSelected(e.windowId);
      }),
      wm.addCallbackListener<WindowRestoredEvent>((e) {
        _addLog('Window #${e.windowId} restored', color: Colors.teal);
        _updateWindows();
        _refreshSelected(e.windowId);
      }),
      wm.addCallbackListener<WindowMovedEvent>((e) {
        _addLog(
          'Window #${e.windowId} moved → (${e.position.dx.toInt()}, ${e.position.dy.toInt()})',
          color: Colors.blue,
        );
        if (_selectedWindow?.id == e.windowId) _refreshSelected(e.windowId);
      }),
      wm.addCallbackListener<WindowResizedEvent>((e) {
        _addLog(
          'Window #${e.windowId} resized → ${e.size.width.toInt()}×${e.size.height.toInt()}',
          color: Colors.blue,
        );
        if (_selectedWindow?.id == e.windowId) _refreshSelected(e.windowId);
      }),
    ]);
  }

  void _updateWindows() {
    try {
      final windows = WindowManager.instance.getAll();
      if (!mounted) return;
      setState(() {
        _windows = windows;
        if (_selectedWindow != null) {
          final updated = windows.where((w) => w.id == _selectedWindow!.id);
          _selectedWindow = updated.isNotEmpty ? updated.first : null;
        }
      });
    } catch (_) {}
  }

  void _refreshSelected(int windowId) {
    if (_selectedWindow?.id == windowId) {
      try {
        final w = WindowManager.instance.getById(windowId);
        if (mounted) setState(() => _selectedWindow = w);
      } catch (_) {}
    }
  }

  // -----------------------------------------------------------------------
  // Loading
  // -----------------------------------------------------------------------
  Future<void> _loadDisplays() async {
    try {
      final displays = DisplayManager.instance.getAll();
      if (mounted) setState(() => _displays = displays);
    } catch (_) {}
  }

  Future<void> _loadWindows() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final windows = WindowManager.instance.getAll();
      if (mounted) {
        setState(() {
          _windows = windows;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load windows: $e';
        });
      }
    }
  }

  // -----------------------------------------------------------------------
  // Selection
  // -----------------------------------------------------------------------
  void _selectWindow(Window w) {
    setState(() => _selectedWindow = w);
    _tabController.animateTo(1); // switch to Actions tab
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.window),
            const SizedBox(width: 8),
            const Text('Window Manager'),
            if (_windows.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_windows.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'minimize_all':
                  for (final w in _windows) {
                    try {
                      w.minimize();
                    } catch (_) {}
                  }
                  _addLog('Action: minimize all windows',
                      color: Colors.orange);
                  _showFeedback('Minimized all windows');
                case 'restore_all':
                  for (final w in _windows) {
                    try {
                      w.restore();
                    } catch (_) {}
                  }
                  _addLog('Action: restore all windows',
                      color: Colors.teal);
                  _showFeedback('Restored all windows');
                case 'show_all':
                  for (final w in _windows) {
                    try {
                      w.show();
                    } catch (_) {}
                  }
                  _addLog('Action: show all windows',
                      color: Colors.green);
                  _showFeedback('Showed all windows');
                case 'hide_all':
                  for (final w in _windows) {
                    try {
                      w.hide();
                    } catch (_) {}
                  }
                  _addLog('Action: hide all windows',
                      color: Colors.grey);
                  _showFeedback('Hidden all windows');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'minimize_all',
                child: ListTile(
                  leading: Icon(Icons.minimize),
                  title: Text('Minimize All'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'restore_all',
                child: ListTile(
                  leading: Icon(Icons.settings_backup_restore),
                  title: Text('Restore All'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'show_all',
                child: ListTile(
                  leading: Icon(Icons.visibility),
                  title: Text('Show All'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'hide_all',
                child: ListTile(
                  leading: Icon(Icons.visibility_off),
                  title: Text('Hide All'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWindows,
            tooltip: 'Refresh Windows',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Canvas', icon: Icon(Icons.grid_on, size: 18)),
            Tab(text: 'Actions', icon: Icon(Icons.tune, size: 18)),
            Tab(text: 'Events', icon: Icon(Icons.list_alt, size: 18)),
          ],
        ),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading windows...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error, color: theme.colorScheme.error, size: 48),
                const SizedBox(height: 16),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadWindows,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_windows.isEmpty) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.window_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No windows found',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Open or create a window\nto begin exploring the API.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Feedback bar
        if (_actionFeedback != null)
          MaterialBanner(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: _feedbackColor.withValues(alpha: 0.12),
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: _feedbackColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _actionFeedback!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _feedbackColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => setState(() => _actionFeedback = null),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        // Main content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // --- Tab 0: Canvas ---
              _buildCanvasTab(theme),
              // --- Tab 1: Actions ---
              _buildActionsTab(theme),
              // --- Tab 2: Events ---
              _buildEventsTab(theme),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // TAB 0 – Canvas
  // =====================================================================
  Widget _buildCanvasTab(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: WindowCanvas(
                  windows: _windows,
                  displays: _displays,
                  selectedWindow: _selectedWindow,
                  onWindowTap: _selectWindow,
                ),
              ),
              if (_selectedWindow != null)
                Expanded(
                  flex: 2,
                  child: _buildQuickInfo(_selectedWindow!, theme),
                ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: WindowCanvas(
                windows: _windows,
                displays: _displays,
                selectedWindow: _selectedWindow,
                onWindowTap: _selectWindow,
              ),
            ),
            if (_selectedWindow != null)
              Expanded(
                flex: 2,
                child: _buildQuickInfo(_selectedWindow!, theme),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuickInfo(Window window, ThemeData theme) {
    final bounds = window.bounds;
    final contentBounds = window.contentBounds;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Window identity card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.window, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        window.title.isNotEmpty ? window.title : 'Untitled',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _chip('ID: ${window.id}', theme.colorScheme.primary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Geometry
        _infoCard('Geometry', [
          _infoRow(Icons.aspect_ratio, 'Size',
              '${bounds.width.toInt()} × ${bounds.height.toInt()}'),
          _infoRow(Icons.place, 'Position',
              '(${bounds.left.toInt()}, ${bounds.top.toInt()})'),
          _infoRow(Icons.crop_free, 'Content',
              '${contentBounds.width.toInt()} × ${contentBounds.height.toInt()}'),
        ], theme),
        const SizedBox(height: 8),
        // State badges
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _stateChip('Visible', window.isVisible, Colors.green),
                _stateChip('Focused', window.isFocused, Colors.indigo),
                _stateChip('Maximized', window.isMaximized, Colors.purple),
                _stateChip('Minimized', window.isMinimized, Colors.orange),
                _stateChip('Fullscreen', window.isFullscreen, Colors.red),
                _stateChip('Always on Top', window.isAlwaysOnTop, Colors.teal),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Quick actions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quick Actions',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _quickActionBtn(
                        'Maximize',
                        Icons.open_in_full,
                        window.isMaximized,
                        () {
                          window.maximize();
                          _addLog('Action: maximize #${window.id}',
                              color: Colors.purple);
                        },
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _quickActionBtn(
                        'Minimize',
                        Icons.minimize,
                        window.isMinimized,
                        () {
                          window.minimize();
                          _addLog('Action: minimize #${window.id}',
                              color: Colors.orange);
                        },
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _quickActionBtn(
                        'Restore',
                        Icons.settings_backup_restore,
                        false,
                        () {
                          window.restore();
                          _addLog('Action: restore #${window.id}',
                              color: Colors.teal);
                        },
                        Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _quickActionBtn(
                        'Hide',
                        Icons.hide_source,
                        !window.isVisible,
                        () {
                          window.hide();
                          _addLog('Action: hide #${window.id}',
                              color: Colors.orange);
                        },
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _tabController.animateTo(1),
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text('More Actions'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String title, List<Widget> rows, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: SelectableText(value,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _stateChip(String label, bool active, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? color.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: active ? color : Colors.grey,
        ),
      ),
    );
  }

  Widget _quickActionBtn(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onPressed,
    Color color,
  ) {
    return SizedBox(
      height: 40,
      child: isActive
          ? FilledButton.tonalIcon(
              onPressed: onPressed,
              icon: Icon(icon, size: 16),
              label: Text(label, style: const TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.2),
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 16),
              label: Text(label, style: const TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
    );
  }

  // =====================================================================
  // TAB 1 – Actions
  // =====================================================================
  Widget _buildActionsTab(ThemeData theme) {
    final window = _selectedWindow;
    if (window == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Select a window on the Canvas tab',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Window header
          _sectionHeader('Selected: ${window.title}', Icons.window, theme),
          const SizedBox(height: 4),
          _chip('ID: ${window.id}', theme.colorScheme.primary),
          const SizedBox(height: 16),

          // --- Visibility ---
          _group('Visibility', Icons.visibility, [
            _actionBtn('Show', Icons.visibility, () {
              window.show();
              _showFeedback('Window shown');
              _addLog('Action: show #${window.id}', color: Colors.green);
            }),
            _actionBtn('Show Inactive', Icons.visibility_off, () {
              window.showInactive();
              _showFeedback('Window shown (inactive)');
            }),
            _actionBtn('Hide', Icons.hide_source, () {
              window.hide();
              _showFeedback('Window hidden');
              _addLog('Action: hide #${window.id}', color: Colors.orange);
            }),
          ]),

          // --- State ---
          _group('Window State', Icons.fullscreen, [
            _actionBtn('Maximize', Icons.open_in_full, () {
              window.maximize();
              _showFeedback('Window maximized');
            }),
            _actionBtn('Unmaximize', Icons.close_fullscreen, () {
              window.unmaximize();
              _showFeedback('Window unmaximized');
            }),
            _actionBtn('Minimize', Icons.minimize, () {
              window.minimize();
              _showFeedback('Window minimized');
            }),
            _actionBtn('Restore', Icons.settings_backup_restore, () {
              window.restore();
              _showFeedback('Window restored');
            }),
            _actionBtn(
              window.isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
              Icons.fullscreen,
              () {
                window.isFullscreen = !window.isFullscreen;
                _showFeedback(
                  window.isFullscreen ? 'Fullscreen on' : 'Fullscreen off',
                );
              },
              color: window.isFullscreen ? Colors.red : null,
            ),
          ]),

          // --- Focus ---
          _group('Focus', Icons.center_focus_strong, [
            _actionBtn('Focus', Icons.center_focus_strong, () {
              window.focus();
              _showFeedback('Window focused');
            }),
            _actionBtn('Blur', Icons.blur_on, () {
              window.blur();
              _showFeedback('Window blurred');
            }),
          ]),

          // --- Position & Size ---
          _group('Position & Size', Icons.place, [
            _actionBtn('Center', Icons.center_focus_strong, () {
              window.center();
              _showFeedback('Window centered');
            }),
            _actionBtn('800 × 600', Icons.aspect_ratio, () {
              window.setSize(800, 600);
              _showFeedback('Size set to 800 × 600');
            }),
            _actionBtn('1024 × 768', Icons.aspect_ratio, () {
              window.setSize(1024, 768);
              _showFeedback('Size set to 1024 × 768');
            }),
            _actionBtn('Set Content 760×540', Icons.crop_free, () {
              window.setContentSize(760, 540);
              _showFeedback('Content size set to 760 × 540');
            }),
            _actionBtn('Position (100, 100)', Icons.pin_drop, () {
              window.setPosition(100, 100);
              _showFeedback('Position set to (100, 100)');
            }),
            _actionBtn('Position (400, 300)', Icons.pin_drop, () {
              window.setPosition(400, 300);
              _showFeedback('Position set to (400, 300)');
            }),
          ]),

          // --- Size Constraints ---
          _group('Size Constraints', Icons.straighten, [
            _actionBtn('Set Min 400×300', Icons.arrow_circle_down, () {
              window.setMinimumSize(400, 300);
              _showFeedback('Minimum size set to 400 × 300');
            }),
            _actionBtn('Set Max 1200×900', Icons.arrow_circle_up, () {
              window.setMaximumSize(1200, 900);
              _showFeedback('Maximum size set to 1200 × 900');
            }),
            _actionBtn('Reset Constraints', Icons.remove_circle_outline, () {
              window.setMinimumSize(0, 0);
              window.setMaximumSize(0, 0);
              _showFeedback('Size constraints reset');
            }),
          ]),

          // --- Appearance ---
          _group('Appearance', Icons.palette, [
            _actionBtn(
              window.titleBarStyle == TitleBarStyle.hidden
                  ? 'Show Title Bar'
                  : 'Hide Title Bar',
              Icons.title,
              () {
                window.titleBarStyle = window.titleBarStyle == TitleBarStyle.hidden
                    ? TitleBarStyle.normal
                    : TitleBarStyle.hidden;
                _showFeedback(
                  'Title bar ${window.titleBarStyle == TitleBarStyle.hidden ? 'hidden' : 'shown'}',
                );
              },
            ),
            _actionBtn(
              window.hasShadow ? 'Remove Shadow' : 'Add Shadow',
              Icons.blur_on,
              () {
                window.hasShadow = !window.hasShadow;
                _showFeedback(
                  'Shadow ${window.hasShadow ? 'enabled' : 'disabled'}',
                );
              },
            ),
            _toggleBtn(
              'Always on Top',
              window.isAlwaysOnTop,
              (v) {
                window.isAlwaysOnTop = v;
                _showFeedback('Always on top: ${v ? 'ON' : 'OFF'}');
              },
            ),
            // Opacity slider
            _labeledSlider(
              'Opacity',
              window.opacity,
              0.1,
              1.0,
              (v) {
                window.opacity = v;
                _showFeedback('Opacity: ${v.toStringAsFixed(2)}');
              },
            ),
          ]),

          // --- Visual Effects ---
          _group('Visual Effects', Icons.blur_on, [
            ...VisualEffect.values.map((effect) {
              final label = effect.name[0].toUpperCase() + effect.name.substring(1);
              return _actionBtn(
                label,
                effect == VisualEffect.none
                    ? Icons.block
                    : effect == VisualEffect.blur
                    ? Icons.blur_on
                    : effect == VisualEffect.acrylic
                    ? Icons.water_drop
                    : Icons.dark_mode,
                () {
                  window.visualEffect = effect;
                  _showFeedback('Visual effect: $label');
                },
                color: window.visualEffect == effect
                    ? theme.colorScheme.primary
                    : null,
                isActive: window.visualEffect == effect,
              );
            }),
          ]),

          // --- Background Color ---
          _group('Background Color', Icons.color_lens, [
            _colorBtn('White', Colors.white, window, () {
              window.backgroundColor = Colors.white;
              _showFeedback('Background: White');
            }),
            _colorBtn('Light Grey', Colors.grey[200]!, window, () {
              window.backgroundColor = Colors.grey[200]!;
              _showFeedback('Background: Light Grey');
            }),
            _colorBtn('Dark', Colors.grey[900]!, window, () {
              window.backgroundColor = Colors.grey[900]!;
              _showFeedback('Background: Dark');
            }),
            _colorBtn('Blue', Colors.blue[200]!, window, () {
              window.backgroundColor = Colors.blue[200]!;
              _showFeedback('Background: Blue');
            }),
            _colorBtn('Transparent', Colors.transparent, window, () {
              window.backgroundColor = const Color(0x00000000);
              _showFeedback('Background: Transparent');
            }),
          ]),

          // --- Advanced ---
          _group('Advanced', Icons.settings, [
            _toggleBtn(
              'Resizable',
              window.isResizable,
              (v) => window.isResizable = v,
            ),
            _toggleBtn(
              'Movable',
              window.isMovable,
              (v) => window.isMovable = v,
            ),
            _toggleBtn(
              'Minimizable',
              window.isMinimizable,
              (v) => window.isMinimizable = v,
            ),
            _toggleBtn(
              'Maximizable',
              window.isMaximizable,
              (v) => window.isMaximizable = v,
            ),
            _toggleBtn(
              'Fullscreenable',
              window.isFullscreenable,
              (v) => window.isFullscreenable = v,
            ),
            _toggleBtn(
              'Closable',
              window.isClosable,
              (v) => window.isClosable = v,
            ),
          ]),

          // --- Platform Specific ---
          _group('Platform Specific', Icons.desktop_windows, [
            _toggleBtn(
              'Control Buttons Visible',
              window.windowControlButtonsVisible,
              (v) => window.windowControlButtonsVisible = v,
            ),
            _toggleBtn(
              'Visible on All Workspaces',
              window.isVisibleOnAllWorkspaces,
              (v) => window.isVisibleOnAllWorkspaces = v,
            ),
            _toggleBtn(
              'Ignore Mouse Events',
              window.ignoreMouseEvents,
              (v) => window.ignoreMouseEvents = v,
            ),
            _toggleBtn(
              'Focusable',
              window.isFocusable,
              (v) => window.isFocusable = v,
            ),
          ]),

          // --- Interactions ---
          _group('Interactions', Icons.gesture, [
            _actionBtn('Start Dragging', Icons.open_with, () {
              window.startDragging();
              _showFeedback('Drag started (move the mouse)');
            }),
            _actionBtn('Start Resizing', Icons.zoom_out_map, () {
              window.startResizing();
              _showFeedback('Resize started (move the mouse)');
            }),
          ]),

          // --- Title ---
          _group('Title', Icons.text_fields, [
            _actionBtn('Set "Hello Window"', Icons.edit, () {
              window.title = 'Hello Window';
              _showFeedback('Title set to "Hello Window"');
            }),
            _actionBtn('Set "My App"', Icons.edit, () {
              window.title = 'My App';
              _showFeedback('Title set to "My App"');
            }),
            _actionBtn('Set "nativeapi"', Icons.edit, () {
              window.title = 'nativeapi';
              _showFeedback('Title set to "nativeapi"');
            }),
          ]),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // =====================================================================
  // TAB 2 – Events
  // =====================================================================
  Widget _buildEventsTab(ThemeData theme) {
    if (_eventLog.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No events yet.\nInteract with windows to see events appear.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Clear button
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              Icon(Icons.list, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Event Log (${_eventLog.length})',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _eventLog.clear()),
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: _eventLog.length,
            itemBuilder: (_, i) {
              final entry = _eventLog[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        entry.formattedTime,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4, right: 8),
                      decoration: BoxDecoration(
                        color: entry.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: entry.color,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // UI helpers
  // =====================================================================
  Widget _sectionHeader(String text, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _group(String title, IconData icon, List<Widget> children) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (children.length <= 4)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: children,
                )
              else
                ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    Color? color,
    bool isActive = false,
  }) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SizedBox(
        width: double.infinity,
        child: isActive
            ? FilledButton.tonalIcon(
                onPressed: onPressed,
                icon: Icon(icon, size: 16),
                label: Text(label, style: const TextStyle(fontSize: 13)),
                style: FilledButton.styleFrom(
                  backgroundColor: c.withValues(alpha: 0.2),
                  foregroundColor: c,
                ),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 16),
                label: Text(label, style: const TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c,
                  side: BorderSide(color: c.withValues(alpha: 0.4)),
                ),
              ),
      ),
    );
  }

  Widget _toggleBtn(
    String label,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              onChanged(v);
              _showFeedback('$label: ${v ? 'ON' : 'OFF'}');
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _labeledSlider(
    String label,
    double value,
    double min,
    double max,
    void Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: 18,
              label: value.toStringAsFixed(2),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(2),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorBtn(
    String label,
    Color color,
    Window window,
    VoidCallback onPressed,
  ) {
    final isSelected = window.backgroundColor.toARGB32() == color.toARGB32();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SizedBox(
        width: double.infinity,
        child: isSelected
            ? FilledButton.tonalIcon(
                onPressed: onPressed,
                icon: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                ),
                label: Text(label, style: const TextStyle(fontSize: 13)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                ),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                ),
                label: Text(label, style: const TextStyle(fontSize: 13)),
              ),
      ),
    );
  }
}

// =========================================================================
// Canvas Widget
// =========================================================================
class WindowCanvas extends StatefulWidget {
  final List<Window> windows;
  final List<Display> displays;
  final Window? selectedWindow;
  final Function(Window) onWindowTap;

  const WindowCanvas({
    super.key,
    required this.windows,
    required this.displays,
    required this.selectedWindow,
    required this.onWindowTap,
  });

  @override
  State<WindowCanvas> createState() => _WindowCanvasState();
}

class _WindowCanvasState extends State<WindowCanvas> {
  final TransformationController _transformationController =
      TransformationController();
  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final s = _transformationController.value.getMaxScaleOnAxis();
    if (s != _baseScale) setState(() => _baseScale = s);
  }

  void _zoomIn() {
    final s = (_transformationController.value.getMaxScaleOnAxis() * 1.3)
        .clamp(0.5, 5.0);
    _transformationController.value = Matrix4.diagonal3Values(s, s, 1);
  }

  void _zoomOut() {
    final s = (_transformationController.value.getMaxScaleOnAxis() / 1.3)
        .clamp(0.5, 5.0);
    _transformationController.value = Matrix4.diagonal3Values(s, s, 1);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.windows.isEmpty && widget.displays.isEmpty) {
      return const Center(child: Text('No windows or displays available'));
    }

    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.brightness == Brightness.dark
                  ? Colors.grey[850]!
                  : Colors.grey[100]!,
              theme.brightness == Brightness.dark
                  ? Colors.grey[900]!
                  : Colors.grey[200]!,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Main canvas with zoom support
            Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) => InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 5.0,
                  boundaryMargin: const EdgeInsets.all(20),
                  child: _buildWindowLayout(constraints),
                ),
              ),
            ),
            // Zoom controls
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: (theme.brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.white)
                      ?.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _zoomIn,
                      tooltip: 'Zoom In',
                      iconSize: 20,
                    ),
                    const Divider(height: 1),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _zoomOut,
                      tooltip: 'Zoom Out',
                      iconSize: 20,
                    ),
                    const Divider(height: 1),
                    IconButton(
                      icon: const Icon(Icons.fit_screen),
                      onPressed: _resetZoom,
                      tooltip: 'Fit to Screen',
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            ),
            // Scale indicator
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(_baseScale * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowLayout(BoxConstraints constraints) {
    final bounds = _calculateBounds();
    if (bounds.isEmpty) {
      return const Center(child: Text('No displays or windows available'));
    }

    final scaleX = constraints.maxWidth / bounds.width;
    final scaleY = constraints.maxHeight / bounds.height;
    final scale = (scaleX < scaleY ? scaleX : scaleY) * 0.9;

    return SizedBox(
      width: bounds.width * scale,
      height: bounds.height * scale,
      child: Stack(
        children: [
          if (widget.displays.isNotEmpty)
            ...widget.displays
                .map((d) => _buildDisplay(d, bounds, scale)),
          ...widget.windows
              .map((w) => _buildWindow(w, bounds, scale)),
        ],
      ),
    );
  }

  Rect _calculateBounds() {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final display in widget.displays) {
      final pos = display.position;
      final size = display.size;
      minX = minX < pos.dx ? minX : pos.dx;
      minY = minY < pos.dy ? minY : pos.dy;
      maxX = maxX > pos.dx + size.width ? maxX : pos.dx + size.width;
      maxY = maxY > pos.dy + size.height ? maxY : pos.dy + size.height;
    }

    for (final window in widget.windows) {
      try {
        final b = window.bounds;
        minX = minX < b.left ? minX : b.left;
        minY = minY < b.top ? minY : b.top;
        maxX = maxX > b.right ? maxX : b.right;
        maxY = maxY > b.bottom ? maxY : b.bottom;
      } catch (_) {
        continue;
      }
    }

    if (minX == double.infinity) return Rect.zero;
    const pad = 50.0;
    return Rect.fromLTWH(
        minX - pad, minY - pad, maxX - minX + pad * 2, maxY - minY + pad * 2);
  }

  Widget _buildDisplay(Display display, Rect bounds, double scale) {
    final pos = display.position;
    final size = display.size;
    final work = display.workArea;

    final left = (pos.dx - bounds.left) * scale;
    final top = (pos.dy - bounds.top) * scale;
    final w = size.width * scale;
    final h = size.height * scale;

    final waLeft = (work.left - pos.dx) * scale;
    final waTop = (work.top - pos.dy) * scale;
    final waW = work.width * scale;
    final waH = work.height * scale;

    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          children: [
            // Display bezel
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF555555), Color(0xFF333333)],
                ),
                border: Border.all(color: Colors.grey[600]!, width: 1.5),
              ),
            ),
            // Work area
            Positioned(
              left: waLeft,
              top: waTop,
              child: Container(
                width: waW,
                height: waH,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.grey[200]!, Colors.grey[300]!],
                  ),
                  border: Border.all(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
            ),
            // Display label
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  display.name,
                  style: TextStyle(
                    fontSize: (8 * scale).clamp(6.0, 10.0),
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindow(Window window, Rect bounds, double scale) {
    try {
      final wb = window.bounds;
      final cb = window.contentBounds;

      final left = (wb.left - bounds.left) * scale;
      final top = (wb.top - bounds.top) * scale;
      final w = wb.width * scale;
      final h = wb.height * scale;

      final cLeft = (cb.left - wb.left) * scale;
      final cTop = (cb.top - wb.top) * scale;
      final cW = cb.width * scale;
      final cH = cb.height * scale;

      final selected = widget.selectedWindow?.id == window.id;
      final accent = selected ? Colors.indigo : Colors.deepOrange;

      if (left + w < 0 || top + h < 0 || left > bounds.width * scale ||
          top > bounds.height * scale) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: left,
        top: top,
        child: GestureDetector(
          onTap: () => widget.onWindowTap(window),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: w,
            height: h,
            decoration: BoxDecoration(
              border: Border.all(
                color: accent,
                width: selected ? 3 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: selected ? 0.35 : 0.15),
                  blurRadius: selected ? 10 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Window fill
                Container(
                  color: accent.withValues(alpha: 0.08),
                ),
                // Title bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: (28 * scale).clamp(12.0, 28.0),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.25),
                      border: Border(
                        bottom: BorderSide(color: accent, width: 1),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: (6 * scale).clamp(3.0, 6.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.window,
                          size: (10 * scale).clamp(7.0, 10.0),
                          color: accent,
                        ),
                        SizedBox(width: (4 * scale).clamp(2.0, 4.0)),
                        Expanded(
                          child: Text(
                            _windowLabel(window),
                            style: TextStyle(
                              fontSize: (9 * scale).clamp(6.0, 9.0),
                              color: accent,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content bounds
                Positioned(
                  left: cLeft,
                  top: cTop,
                  child: Container(
                    width: cW,
                    height: cH,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Container(
                      color: Colors.green.withValues(alpha: 0.04),
                      child: Center(
                        child: Text(
                          'Content',
                          style: TextStyle(
                            fontSize: (7 * scale).clamp(5.0, 9.0),
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Size label
                Positioned(
                  left: 4,
                  top: (28 * scale).clamp(12.0, 28.0) + 4,
                  child: _buildLabel(
                    '${wb.width.toInt()}×${wb.height.toInt()}',
                    '(${wb.left.toInt()}, ${wb.top.toInt()})',
                    accent,
                    scale,
                  ),
                ),
                // Content size label
                Positioned(
                  left: cLeft + 4,
                  top: cTop + 4,
                  child: _buildLabel(
                    '${cb.width.toInt()}×${cb.height.toInt()}',
                    '',
                    Colors.green,
                    scale,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  String _windowLabel(Window w) {
    final title = w.title;
    if (title.isNotEmpty) return title;
    return 'Window #${w.id}';
  }

  Widget _buildLabel(String line1, String line2, Color color, double scale) {
    final fontSize = (7 * scale).clamp(5.0, 10.0);
    return Container(
      padding: EdgeInsets.all((3 * scale).clamp(1.5, 4.0)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            line1,
            style: TextStyle(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (line2.isNotEmpty)
            Text(
              line2,
              style: TextStyle(
                fontSize: fontSize * 0.85,
                color: color.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }
}
