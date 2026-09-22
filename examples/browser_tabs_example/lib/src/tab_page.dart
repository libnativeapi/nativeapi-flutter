import 'dart:async';

import 'package:flutter/material.dart';

import 'tabs_controller.dart';

/// A stand-in for a web page, with state that would be lost if it were
/// rebuilt: an edited address, a counter, a scroll position, and a timer that
/// keeps running.
class TabPage extends StatefulWidget {
  const TabPage({super.key, required this.tab});

  final BrowserTab tab;

  @override
  State<TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<TabPage> {
  static int _nextInstance = 1;

  final int _instance = _nextInstance++;
  late final TextEditingController _address = TextEditingController(
    text: 'https://example.com/tab-${widget.tab.id}',
  );
  final _scroll = ScrollController();
  final _openedAt = DateTime.now();
  late final Timer _timer;
  int _likes = 0;
  int _windowMoves = 0;
  int? _viewId;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewId = View.of(context).viewId;
    if (_viewId != null && viewId != _viewId) _windowMoves++;
    _viewId = viewId;
  }

  @override
  void dispose() {
    _timer.cancel();
    _address.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final seconds = DateTime.now().difference(_openedAt).inSeconds;

    return Material(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.arrow_back, size: 18),
                const SizedBox(width: 8),
                const Icon(Icons.refresh, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _address,
                    style: text.bodyMedium,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      prefixIcon: const Icon(Icons.lock_outline, size: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(24),
              itemCount: 30,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tab.title, style: text.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Page state #$_instance · open for ${seconds}s · '
                        'moved between windows $_windowMoves×',
                        style: text.bodySmall?.copyWith(color: colors.outline),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => setState(() => _likes++),
                            icon: const Icon(Icons.thumb_up_alt_outlined),
                            label: Text('Like ($_likes)'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Drag the tab to reorder, pull it down to tear '
                              'it off, drop it on another strip to merge.',
                              style: text.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                return Container(
                  height: 64,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: tab.color.withValues(alpha: 0.08 + (i % 3) * 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${tab.title} · paragraph $i'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
