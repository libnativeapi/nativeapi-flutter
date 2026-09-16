import 'package:browser_tabs_example/src/tab_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const layout = TabLayout(leadingInset: 78, trailingInset: 8);

  test('tabs share the strip, within their size limits', () {
    // 78 + 8 + 40 leaves 634 for tabs.
    expect(layout.tabExtent(760, 2), TabLayout.maxTabWidth);
    expect(layout.tabExtent(760, 4), closeTo(158.5, 1e-9));
    expect(layout.tabExtent(760, 20), TabLayout.minTabWidth);
  });

  test('a dragged tab takes the index it covers most', () {
    const extent = 100.0;
    expect(layout.indexForLeft(78, extent, 4), 0);
    expect(layout.indexForLeft(78 + 49, extent, 4), 0);
    expect(layout.indexForLeft(78 + 51, extent, 4), 1);
    expect(layout.indexForLeft(78 + 260, extent, 4), 3);
    expect(layout.indexForLeft(-500, extent, 4), 0);
    expect(layout.indexForLeft(5000, extent, 4), 3);
    expect(layout.indexForLeft(300, extent, 1), 0);
  });

  test('a dragged tab stays within the tabs', () {
    const extent = 100.0;
    expect(layout.clampLeft(0, extent, 3), 78);
    expect(layout.clampLeft(1000, extent, 3), 278);
    expect(layout.clampLeft(150, extent, 3), 150);
    expect(layout.clampLeft(150, extent, 1), 78);
  });
}
