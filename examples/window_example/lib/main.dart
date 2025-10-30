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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        cardTheme: const CardThemeData(elevation: 2, margin: EdgeInsets.all(8)),
      ),
      home: const WindowManagerPage(),
    );
  }
}

class WindowManagerPage extends StatefulWidget {
  const WindowManagerPage({super.key});

  @override
  State<WindowManagerPage> createState() => _WindowManagerPageState();
}

class _WindowManagerPageState extends State<WindowManagerPage> {
  List<Window> _windows = [];
  List<Display> _displays = [];
  Window? _selectedWindow;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _updateTimer;
  List<int> _windowListenerIds = [];

  @override
  void initState() {
    super.initState();
    _loadDisplays();
    _loadWindows();
    _startTracking();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    final windowManager = WindowManager.instance;
    for (final listenerId in _windowListenerIds) {
      windowManager.removeListener(listenerId);
    }
    _windowListenerIds.clear();
    super.dispose();
  }

  void _startTracking() {
    // Update windows periodically
    _updateTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (mounted) {
        _updateWindows();
      }
    });

    // Listen to window events
    final windowManager = WindowManager.instance;
    _windowListenerIds.add(
      windowManager.addCallbackListener<WindowCreatedEvent>((event) {
        if (mounted) {
          _updateWindows();
        }
      }),
    );
    _windowListenerIds.add(
      windowManager.addCallbackListener<WindowClosedEvent>((event) {
        if (mounted) {
          _updateWindows();
        }
      }),
    );
    _windowListenerIds.add(
      windowManager.addCallbackListener<WindowMovedEvent>((event) {
        if (mounted) {
          _updateWindows();
          if (_selectedWindow?.id == event.windowId) {
            _updateSelectedWindow();
          }
        }
      }),
    );
    _windowListenerIds.add(
      windowManager.addCallbackListener<WindowResizedEvent>((event) {
        if (mounted) {
          _updateWindows();
          if (_selectedWindow?.id == event.windowId) {
            _updateSelectedWindow();
          }
        }
      }),
    );
  }

  void _updateWindows() {
    try {
      final windowManager = WindowManager.instance;
      final windows = windowManager.getAll();

      if (mounted) {
        setState(() {
          _windows = windows;
          // Update selected window reference if it still exists
          if (_selectedWindow != null) {
            final updatedWindow =
                windows.firstWhere((w) => w.id == _selectedWindow!.id, orElse: () => _selectedWindow!);
            _selectedWindow = updatedWindow;
          }
        });
      }
    } catch (e) {
      // Windows might have been destroyed, ignore errors
    }
  }

  void _updateSelectedWindow() {
    if (_selectedWindow != null) {
      try {
        final windowManager = WindowManager.instance;
        final updatedWindow = windowManager.getById(_selectedWindow!.id);
        if (mounted && updatedWindow != null) {
          setState(() {
            _selectedWindow = updatedWindow;
          });
        }
      } catch (e) {
        // Window might have been destroyed
      }
    }
  }

  Future<void> _loadDisplays() async {
    try {
      final displayManager = DisplayManager.instance;
      final displays = displayManager.getAll();

      setState(() {
        _displays = displays;
      });
    } catch (e) {
      // Ignore display loading errors
    }
  }

  Future<void> _loadWindows() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final windowManager = WindowManager.instance;
      final windows = windowManager.getAll();

      setState(() {
        _windows = windows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load windows: $e';
      });
    }
  }

  void _createTestWindow() {
    try {
      final windowManager = WindowManager.instance;
      final window = windowManager.create(
        title: 'Test Window ${_windows.length + 1}',
        width: 600 + (_windows.length * 50),
        height: 400 + (_windows.length * 50),
        centered: true,
      );

      if (window != null) {
        window.show();
        _updateWindows();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create window: $e';
      });
    }
  }

  void _selectWindow(Window window) {
    setState(() {
      _selectedWindow = window;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.window),
            const SizedBox(width: 8),
            const Text('Window Example'),
            if (_windows.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_windows.length} window${_windows.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createTestWindow,
            tooltip: 'Create Test Window',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWindows,
            tooltip: 'Refresh Windows',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
            Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadWindows,
                  child: const Text('Retry'),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.window_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No windows found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Click the + button to create a test window',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _createTestWindow,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Test Window'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;

        if (isWideScreen) {
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: WindowCanvas(
                  windows: _windows,
                  displays: _displays,
                  selectedWindow: _selectedWindow,
                  onWindowTap: _selectWindow,
                ),
              ),
              if (_selectedWindow != null)
                Expanded(
                  flex: 1,
                  child: WindowDetails(window: _selectedWindow!),
                ),
            ],
          );
        } else {
          return Column(
            children: [
              Expanded(
                flex: 2,
                child: WindowCanvas(
                  windows: _windows,
                  displays: _displays,
                  selectedWindow: _selectedWindow,
                  onWindowTap: _selectWindow,
                ),
              ),
              if (_selectedWindow != null)
                Expanded(
                  flex: 1,
                  child: WindowDetails(window: _selectedWindow!),
                ),
            ],
          );
        }
      },
    );
  }
}

class WindowCanvas extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (windows.isEmpty && displays.isEmpty) {
      return const Center(child: Text('No windows or displays available'));
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[50]!, Colors.grey[100]!],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) => _buildWindowLayout(constraints),
        ),
      ),
    );
  }

  Widget _buildWindowLayout(BoxConstraints constraints) {
    // Calculate the bounding box based on displays (if available) or windows
    final bounds = _calculateBounds();

    if (bounds.isEmpty) {
      return const Center(child: Text('No displays or windows available'));
    }

    // Calculate scale to fit all content in the canvas
    final scaleX = constraints.maxWidth / bounds.width;
    final scaleY = constraints.maxHeight / bounds.height;
    final scale = (scaleX < scaleY ? scaleX : scaleY) * 0.85;

    return Center(
      child: SizedBox(
        width: bounds.width * scale,
        height: bounds.height * scale,
        child: Stack(
          children: [
            // Draw displays first as background
            if (displays.isNotEmpty)
              ...displays.map((display) => _buildDisplay(display, bounds, scale)).toList(),
            // Draw windows on top
            ...windows.map((window) => _buildWindow(window, bounds, scale)).toList(),
          ],
        ),
      ),
    );
  }

  Rect _calculateBounds() {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    // First, include all displays if available
    if (displays.isNotEmpty) {
      for (final display in displays) {
        final position = display.position;
        final size = display.size;
        minX = minX < position.dx ? minX : position.dx;
        minY = minY < position.dy ? minY : position.dy;
        maxX = maxX > (position.dx + size.width)
            ? maxX
            : (position.dx + size.width);
        maxY = maxY > (position.dy + size.height)
            ? maxY
            : (position.dy + size.height);
      }
    }

    // Then, include all windows
    for (final window in windows) {
      try {
        final windowBounds = window.bounds;
        minX = minX < windowBounds.left ? minX : windowBounds.left;
        minY = minY < windowBounds.top ? minY : windowBounds.top;
        maxX = maxX > windowBounds.right ? maxX : windowBounds.right;
        maxY = maxY > windowBounds.bottom ? maxY : windowBounds.bottom;
      } catch (e) {
        // Window might have been destroyed, skip it
        continue;
      }
    }

    if (minX == double.infinity) {
      return Rect.zero;
    }

    // Add padding around the bounds
    const padding = 50.0;
    return Rect.fromLTWH(
      minX - padding,
      minY - padding,
      maxX - minX + padding * 2,
      maxY - minY + padding * 2,
    );
  }

  Widget _buildDisplay(Display display, Rect bounds, double scale) {
    final position = display.position;
    final size = display.size;
    final workArea = display.workArea;

    // Calculate display position and size relative to the bounding box
    final displayLeft = (position.dx - bounds.left) * scale;
    final displayTop = (position.dy - bounds.top) * scale;
    final displayWidth = size.width * scale;
    final displayHeight = size.height * scale;

    // Calculate work area position relative to the display
    final workAreaLeft = (workArea.left - position.dx) * scale;
    final workAreaTop = (workArea.top - position.dy) * scale;
    final workAreaWidth = workArea.width * scale;
    final workAreaHeight = workArea.height * scale;

    return Positioned(
      left: displayLeft,
      top: displayTop,
      child: Container(
        width: displayWidth,
        height: displayHeight,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          border: Border.all(color: Colors.grey[400]!, width: 1),
        ),
        child: Stack(
          children: [
            // Display bezel
            Container(
              width: displayWidth,
              height: displayHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[700]!, Colors.grey[800]!],
                ),
              ),
            ),
            // Screen area (work area)
            Positioned(
              left: workAreaLeft,
              top: workAreaTop,
              child: Container(
                width: workAreaWidth,
                height: workAreaHeight,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
              ),
            ),
            // Display label
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
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
      final windowBounds = window.bounds;
      final contentBounds = window.contentBounds;

      final windowLeft = (windowBounds.left - bounds.left) * scale;
      final windowTop = (windowBounds.top - bounds.top) * scale;
      final windowWidth = windowBounds.width * scale;
      final windowHeight = windowBounds.height * scale;

      // Calculate content area position relative to window bounds
      final contentLeft = (contentBounds.left - windowBounds.left) * scale;
      final contentTop = (contentBounds.top - windowBounds.top) * scale;
      final contentWidth = contentBounds.width * scale;
      final contentHeight = contentBounds.height * scale;

      final isSelected = selectedWindow?.id == window.id;

      // Only draw if window is visible within bounds
      if (windowLeft + windowWidth < 0 ||
          windowTop + windowHeight < 0 ||
          windowLeft > bounds.width * scale ||
          windowTop > bounds.height * scale) {
        return const SizedBox.shrink();
      }

      return Positioned(
        left: windowLeft,
        top: windowTop,
        child: GestureDetector(
          onTap: () => onWindowTap(window),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: windowWidth,
            height: windowHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.orange,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? Colors.blue : Colors.orange)
                      .withOpacity(0.3),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Window background (semi-transparent)
                Container(
                  color: (isSelected ? Colors.blue : Colors.orange)
                      .withOpacity(0.1),
                ),
                // Window title bar
                Container(
                  height: (30 * scale).clamp(12.0, 30.0),
                  decoration: BoxDecoration(
                    color: (isSelected ? Colors.blue : Colors.orange)
                        .withOpacity(0.3),
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? Colors.blue : Colors.orange,
                        width: 1,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: (8 * scale).clamp(4.0, 8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.window,
                        size: (12 * scale).clamp(8.0, 12.0),
                        color: isSelected ? Colors.blue[900] : Colors.orange[900],
                      ),
                      SizedBox(width: (4 * scale).clamp(2.0, 4.0)),
                      Expanded(
                        child: Text(
                          window.title.isNotEmpty ? window.title : 'Window',
                          style: TextStyle(
                            fontSize: (10 * scale).clamp(6.0, 10.0),
                            color: isSelected ? Colors.blue[900] : Colors.orange[900],
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content area border
                Positioned(
                  left: contentLeft,
                  top: contentTop,
                  child: Container(
                    width: contentWidth,
                    height: contentHeight,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Container(
                      color: Colors.green.withOpacity(0.05),
                      child: Center(
                        child: Text(
                          'Content',
                          style: TextStyle(
                            fontSize: (8 * scale).clamp(6.0, 10.0),
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Labels for window bounds
                Positioned(
                  left: 4,
                  top: (30 * scale).clamp(12.0, 30.0) + 4,
                  child: _buildLabel(
                    'Window: ${windowBounds.width.toInt()}×${windowBounds.height.toInt()}',
                    'Pos: (${windowBounds.left.toInt()}, ${windowBounds.top.toInt()})',
                    isSelected ? Colors.blue : Colors.orange,
                    scale,
                  ),
                ),
                // Labels for content bounds
                Positioned(
                  left: contentLeft + 4,
                  top: contentTop + 4,
                  child: _buildLabel(
                    'Content: ${contentBounds.width.toInt()}×${contentBounds.height.toInt()}',
                    'Pos: (${contentBounds.left.toInt()}, ${contentBounds.top.toInt()})',
                    Colors.green,
                    scale,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      // Window might have been destroyed, return empty widget
      return const SizedBox.shrink();
    }
  }

  Widget _buildLabel(String line1, String line2, Color color, double scale) {
    final fontSize = (8 * scale).clamp(6.0, 10.0);
    return Container(
      padding: EdgeInsets.all((4 * scale).clamp(2.0, 4.0)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(4),
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
          Text(
            line2,
            style: TextStyle(
              fontSize: fontSize * 0.85,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class WindowDetails extends StatelessWidget {
  final Window window;

  const WindowDetails({super.key, required this.window});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              ..._buildDetailSections(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[100]!, Colors.blue[200]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.window,
              size: 28,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  window.title.isNotEmpty ? window.title : 'Window',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ID: ${window.id}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetailSections() {
    final bounds = window.bounds;
    final contentBounds = window.contentBounds;
    final size = window.size;
    final contentSize = window.contentSize;
    final position = window.position;

    return [
      _buildSection('Window Geometry', [
        _DetailItem(Icons.aspect_ratio, 'Window Size', _formatSize(size)),
        _DetailItem(Icons.place, 'Window Position', _formatPosition(position)),
        _DetailItem(Icons.fullscreen, 'Window Bounds', _formatBounds(bounds)),
      ]),
      _buildSection('Content Geometry', [
        _DetailItem(Icons.crop_free, 'Content Size', _formatSize(contentSize)),
        _DetailItem(Icons.crop, 'Content Bounds', _formatBounds(contentBounds)),
        _DetailItem(
          Icons.border_inner,
          'Content Offset',
          _formatOffset(bounds, contentBounds),
        ),
      ]),
      _buildSection('Window Properties', [
        _DetailItem(Icons.visibility, 'Visible', window.isVisible ? 'Yes' : 'No'),
        _DetailItem(Icons.center_focus_strong, 'Focused', window.isFocused ? 'Yes' : 'No'),
        _DetailItem(
          Icons.open_in_full,
          'Maximized',
          window.isMaximized ? 'Yes' : 'No',
        ),
        _DetailItem(
          Icons.minimize,
          'Minimized',
          window.isMinimized ? 'Yes' : 'No',
        ),
        _DetailItem(
          Icons.fullscreen,
          'Fullscreen',
          window.isFullscreen ? 'Yes' : 'No',
        ),
      ]),
      _buildSection('Window Capabilities', [
        _DetailItem(Icons.open_with, 'Resizable', window.isResizable ? 'Yes' : 'No'),
        _DetailItem(Icons.drag_handle, 'Movable', window.isMovable ? 'Yes' : 'No'),
        _DetailItem(
          Icons.unfold_less,
          'Minimizable',
          window.isMinimizable ? 'Yes' : 'No',
        ),
        _DetailItem(
          Icons.unfold_more,
          'Maximizable',
          window.isMaximizable ? 'Yes' : 'No',
        ),
        _DetailItem(
          Icons.crop_free,
          'Fullscreenable',
          window.isFullscreenable ? 'Yes' : 'No',
        ),
        _DetailItem(Icons.close, 'Closable', window.isClosable ? 'Yes' : 'No'),
      ]),
    ];
  }

  Widget _buildSection(String title, List<_DetailItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _buildDetailRow(item),
                  if (index < items.length - 1) const Divider(height: 16),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDetailRow(_DetailItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(item.icon, size: 16, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 140,
          child: Text(
            item.label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SelectableText(
            item.value,
            style: TextStyle(color: Colors.grey[700], fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  String _formatPosition(Offset position) {
    return '(${position.dx.toInt()}, ${position.dy.toInt()})';
  }

  String _formatSize(Size size) {
    return '${size.width.toInt()} × ${size.height.toInt()} px';
  }

  String _formatBounds(Rect bounds) {
    return '(${bounds.left.toInt()}, ${bounds.top.toInt()}) '
        '${bounds.width.toInt()}×${bounds.height.toInt()}';
  }

  String _formatOffset(Rect windowBounds, Rect contentBounds) {
    final offsetX = contentBounds.left - windowBounds.left;
    final offsetY = contentBounds.top - windowBounds.top;
    return '(${offsetX.toInt()}, ${offsetY.toInt()})';
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem(this.icon, this.label, this.value);
}
