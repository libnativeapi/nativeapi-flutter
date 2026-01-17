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
      title: 'Display Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        // cardTheme: const CardThemeData(elevation: 2, margin: EdgeInsets.all(8)),
      ),
      home: const DisplayManagerPage(),
    );
  }
}

class DisplayManagerPage extends StatefulWidget {
  const DisplayManagerPage({super.key});

  @override
  State<DisplayManagerPage> createState() => _DisplayManagerPageState();
}

class _DisplayManagerPageState extends State<DisplayManagerPage> {
  List<Display> _displays = [];
  Display? _selectedDisplay;
  bool _isLoading = true;
  String? _errorMessage;
  Window? _currentWindow;
  Offset _cursorPosition = Offset.zero;
  Timer? _updateTimer;
  List<int> _windowListenerIds = [];

  @override
  void initState() {
    super.initState();
    _loadDisplays();
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
    // Update cursor position and current window periodically
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        _updateCursorAndWindow();
      }
    });

    // Listen to window events to update current window
    final windowManager = WindowManager.instance;
    _windowListenerIds.add(
      windowManager.addCallbackListener<WindowFocusedEvent>((event) {
        if (mounted) {
          _updateCurrentWindow();
        }
      }),
    );
    _windowListenerIds.add(
      windowManager.addCallbackListener<WindowMovedEvent>((event) {
        if (mounted) {
          _updateCurrentWindow();
        }
      }),
    );
    _windowListenerIds.add(
      windowManager.addCallbackListener<WindowResizedEvent>((event) {
        if (mounted) {
          _updateCurrentWindow();
        }
      }),
    );
  }

  void _updateCursorAndWindow() {
    final displayManager = DisplayManager.instance;
    final cursorPos = displayManager.getCursorPosition();

    final windowManager = WindowManager.instance;
    final currentWindow = windowManager.getCurrent();

    if (mounted) {
      setState(() {
        _cursorPosition = cursorPos;
        _currentWindow = currentWindow;
      });
    }
  }

  void _updateCurrentWindow() {
    final windowManager = WindowManager.instance;
    final currentWindow = windowManager.getCurrent();

    if (mounted) {
      setState(() {
        _currentWindow = currentWindow;
      });
    }
  }

  Future<void> _loadDisplays() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final displayManager = DisplayManager.instance;
      final displays = displayManager.getAll();

      setState(() {
        _displays = displays;
        _isLoading = false;
        // Auto-select primary display if available
        if (_selectedDisplay == null && displays.isNotEmpty) {
          _selectedDisplay = displays.firstWhere(
            (d) => d.isPrimary,
            orElse: () => displays.first,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load displays: $e';
      });
    }
  }

  void _selectDisplay(Display display) {
    setState(() {
      _selectedDisplay = display;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.monitor),
            const SizedBox(width: 8),
            const Text('Display Example'),
            if (_displays.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_displays.length} display${_displays.length != 1 ? 's' : ''}',
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadDisplays,
            tooltip: 'Refresh Displays',
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
            Text('Loading displays...'),
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
                  onPressed: _loadDisplays,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_displays.isEmpty) {
      return const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.monitor_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No displays found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Please check your system configuration',
                  style: TextStyle(color: Colors.grey),
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
                child: DisplayCanvas(
                  displays: _displays,
                  selectedDisplay: _selectedDisplay,
                  onDisplayTap: _selectDisplay,
                  currentWindow: _currentWindow,
                  cursorPosition: _cursorPosition,
                ),
              ),
              if (_selectedDisplay != null)
                Expanded(
                  flex: 1,
                  child: DisplayDetails(display: _selectedDisplay!),
                ),
            ],
          );
        } else {
          return Column(
            children: [
              Expanded(
                flex: 2,
                child: DisplayCanvas(
                  displays: _displays,
                  selectedDisplay: _selectedDisplay,
                  onDisplayTap: _selectDisplay,
                  currentWindow: _currentWindow,
                  cursorPosition: _cursorPosition,
                ),
              ),
              if (_selectedDisplay != null)
                Expanded(
                  flex: 1,
                  child: DisplayDetails(display: _selectedDisplay!),
                ),
            ],
          );
        }
      },
    );
  }
}

class DisplayCanvas extends StatelessWidget {
  final List<Display> displays;
  final Display? selectedDisplay;
  final Function(Display) onDisplayTap;
  final Window? currentWindow;
  final Offset cursorPosition;

  const DisplayCanvas({
    super.key,
    required this.displays,
    required this.selectedDisplay,
    required this.onDisplayTap,
    this.currentWindow,
    this.cursorPosition = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (displays.isEmpty) {
      return const Center(child: Text('No displays available'));
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
          builder: (context, constraints) => _buildDisplayLayout(constraints),
        ),
      ),
    );
  }

  Widget _buildDisplayLayout(BoxConstraints constraints) {
    // Calculate the bounding box of all displays
    final bounds = _calculateDisplayBounds();

    // Calculate scale to fit all displays in the canvas
    final scaleX = constraints.maxWidth / bounds.width;
    final scaleY = constraints.maxHeight / bounds.height;
    final scale = (scaleX < scaleY ? scaleX : scaleY) * 0.85;

    return Center(
      child: SizedBox(
        width: bounds.width * scale,
        height: bounds.height * scale,
        child: Stack(
          children: [
            ...displays
                .map((display) => _buildDisplay(display, bounds, scale))
                .toList(),
            if (currentWindow != null)
              _buildWindow(currentWindow!, bounds, scale),
            _buildCursor(bounds, scale),
          ],
        ),
      ),
    );
  }

  Rect _calculateDisplayBounds() {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

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

    return Rect.fromLTWH(minX, minY, maxX - minX, maxY - minY);
  }

  Widget _buildDisplay(Display display, Rect bounds, double scale) {
    final workArea = display.workArea;
    final position = display.position;
    final size = display.size;
    final isSelected = selectedDisplay?.id == display.id;
    final isPrimary = display.isPrimary;

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onDisplayTap(display),

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: displayWidth,
            height: displayHeight,
            decoration: BoxDecoration(
              color: _getDisplayBackgroundColor(isSelected, isPrimary),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected ? 0.3 : 0.1),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
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
                      colors: [Colors.grey[800]!, Colors.grey[900]!],
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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _getWorkAreaGradient(isSelected, isPrimary),
                      ),
                    ),
                    child: _buildDisplayContent(
                      display,
                      workAreaWidth,
                      workAreaHeight,
                      isSelected,
                    ),
                  ),
                ),
                // Selection overlay
                if (isSelected)
                  Container(
                    width: displayWidth,
                    height: displayHeight,
                    color: Colors.blue.withOpacity(0.1),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayContent(
    Display display,
    double width,
    double height,
    bool isSelected,
  ) {
    final iconSize = (height * 0.25).clamp(16.0, 32.0);
    final nameSize = (height * 0.08).clamp(10.0, 14.0);
    final infoSize = (height * 0.06).clamp(8.0, 12.0);

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            display.isPrimary ? Icons.desktop_mac : Icons.monitor,
            size: iconSize,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
          const SizedBox(height: 4),
          Text(
            display.name,
            style: TextStyle(
              fontSize: nameSize,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[800],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            '${display.size.width.toInt()}×${display.size.height.toInt()}',
            style: TextStyle(
              fontSize: infoSize,
              color: isSelected ? Colors.white70 : Colors.grey[600],
            ),
          ),
          if (display.isPrimary && height > 50)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                'PRIMARY',
                style: TextStyle(
                  fontSize: (infoSize * 0.8).clamp(6.0, 10.0),
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getDisplayBackgroundColor(bool isSelected, bool isPrimary) {
    if (isSelected) return Colors.blue[100]!;
    if (isPrimary) return Colors.green[50]!;
    return Colors.grey[200]!;
  }

  List<Color> _getWorkAreaGradient(bool isSelected, bool isPrimary) {
    if (isSelected) {
      return [Colors.blue[400]!, Colors.blue[600]!];
    }
    if (isPrimary) {
      return [Colors.green[300]!, Colors.green[500]!];
    }
    return [Colors.grey[300]!, Colors.grey[400]!];
  }

  Widget _buildWindow(Window window, Rect bounds, double scale) {
    try {
      final windowBounds = window.bounds;
      final windowLeft = (windowBounds.left - bounds.left) * scale;
      final windowTop = (windowBounds.top - bounds.top) * scale;
      final windowWidth = windowBounds.width * scale;
      final windowHeight = windowBounds.height * scale;

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
        child: Container(
          width: windowWidth,
          height: windowHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Window background (semi-transparent)
              Container(color: Colors.orange.withOpacity(0.1)),
              // Window title bar indicator
              Container(
                height: (20 * scale).clamp(8.0, 20.0),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.3),
                  border: const Border(
                    bottom: BorderSide(color: Colors.orange, width: 1),
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
                      color: Colors.orange[900],
                    ),
                    SizedBox(width: (4 * scale).clamp(2.0, 4.0)),
                    Expanded(
                      child: Text(
                        window.title.isNotEmpty ? window.title : 'Window',
                        style: TextStyle(
                          fontSize: (10 * scale).clamp(6.0, 10.0),
                          color: Colors.orange[900],
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Window might have been destroyed, return empty widget
      return const SizedBox.shrink();
    }
  }

  Widget _buildCursor(Rect bounds, double scale) {
    final cursorLeft = (cursorPosition.dx - bounds.left) * scale;
    final cursorTop = (cursorPosition.dy - bounds.top) * scale;

    // Only draw if cursor is within bounds
    if (cursorLeft < 0 ||
        cursorTop < 0 ||
        cursorLeft > bounds.width * scale ||
        cursorTop > bounds.height * scale) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: cursorLeft - 8,
      top: cursorTop - 8,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              blurRadius: 4,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.mouse, size: 8, color: Colors.white),
        ),
      ),
    );
  }
}

class DisplayDetails extends StatelessWidget {
  final Display display;

  const DisplayDetails({super.key, required this.display});

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
          colors: display.isPrimary
              ? [Colors.green[100]!, Colors.green[200]!]
              : [Colors.blue[100]!, Colors.blue[200]!],
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
              display.isPrimary ? Icons.desktop_mac : Icons.monitor,
              size: 28,
              color: display.isPrimary ? Colors.green[700] : Colors.blue[700],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  display.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (display.isPrimary) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PRIMARY',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
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
                        '${display.size.width.toInt()}×${display.size.height.toInt()}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetailSections() {
    return [
      _buildSection('Basic Information', [
        _DetailItem(Icons.badge, 'ID', display.id),
        _DetailItem(Icons.label, 'Name', display.name),
        _DetailItem(Icons.star, 'Primary', display.isPrimary ? 'Yes' : 'No'),
      ]),

      _buildSection('Hardware', [
        _DetailItem(
          Icons.aspect_ratio,
          'Scale Factor',
          '${display.scaleFactor}×',
        ),
        _DetailItem(Icons.refresh, 'Refresh Rate', '${display.refreshRate} Hz'),
        _DetailItem(Icons.palette, 'Bit Depth', '${display.bitDepth} bit'),
        _DetailItem(
          Icons.screen_rotation,
          'Orientation',
          _getOrientationName(),
        ),
      ]),

      _buildSection('Geometry', [
        _DetailItem(Icons.place, 'Position', _formatPosition()),
        _DetailItem(Icons.fullscreen, 'Full Size', _formatSize(display.size)),
        _DetailItem(
          Icons.crop_free,
          'Work Area Size',
          _formatSize(Size(display.workArea.width, display.workArea.height)),
        ),
        _DetailItem(
          Icons.crop,
          'Work Area Position',
          _formatWorkAreaPosition(),
        ),
        _DetailItem(
          Icons.border_outer,
          'System Margins',
          _calculateSystemMargins(),
        ),
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
          width: 120,
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

  String _getOrientationName() {
    return display.orientation.toString().split('.').last.toUpperCase();
  }

  String _formatPosition() {
    return '(${display.position.dx.toInt()}, ${display.position.dy.toInt()})';
  }

  String _formatSize(Size size) {
    return '${size.width.toInt()} × ${size.height.toInt()} px';
  }

  String _formatWorkAreaPosition() {
    final workArea = display.workArea;
    return '(${workArea.left.toInt()}, ${workArea.top.toInt()})';
  }

  String _calculateSystemMargins() {
    final size = display.size;
    final workArea = display.workArea;

    final topMargin = workArea.top;
    final bottomMargin = size.height - workArea.bottom;
    final leftMargin = workArea.left;
    final rightMargin = size.width - workArea.right;

    List<String> margins = [];
    if (topMargin > 0) margins.add('T:${topMargin.toInt()}');
    if (bottomMargin > 0) margins.add('B:${bottomMargin.toInt()}');
    if (leftMargin > 0) margins.add('L:${leftMargin.toInt()}');
    if (rightMargin > 0) margins.add('R:${rightMargin.toInt()}');

    return margins.isEmpty ? 'None' : margins.join(' ');
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem(this.icon, this.label, this.value);
}
