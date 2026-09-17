#!/usr/bin/env python3
"""Locates text in a running debug Flutter app through its VM service.

Parses `ext.flutter.debugDumpRenderTree`: every render object's offset in its
parent is summed up the tree, so each text gets a rect relative to the view
(window content) it is drawn in, in logical pixels.

As a module:

    from uiprobe import App
    views = App('/path/to/app.log').views()
    x, y = views[0].center('Save')

As a command (what scripts in other languages use):

    uiprobe.py <app-log>              # JSON: [{name, size, texts: [[text, [x, y, w, h]]]}]
    uiprobe.py <app-log> --texts      # one readable line per text
    uiprobe.py <app-log> --dump       # the raw render tree, to debug the parser

<app-log> is the file the app's stdout was redirected to; the VM service URL
is read from it. Prints {"error": ...} while the URL is not there yet.
"""

import json
import re
import sys
import urllib.request

NUM = r'(-?[\d.]+)'


class View:
    def __init__(self, index, name):
        self.index = index
        self.name = name
        self.size = None
        self.texts = []  # (text, (x, y, w, h))

    def has(self, text):
        return any(t == text for t, _ in self.texts)

    def find(self, text, prefix=False):
        for t, rect in self.texts:
            if t == text or (prefix and t.startswith(text)):
                return rect
        return None

    def center(self, text, prefix=False):
        rect = self.find(text, prefix)
        if rect is None:
            raise LookupError(f'"{text}" not found in view {self.index}')
        x, y, w, h = rect
        return x + w / 2, y + h / 2


class App:
    def __init__(self, log_path):
        self.log_path = log_path

    def vm_url(self):
        found = re.findall(r'(http://127\.0\.0\.1:\d+/[^/\s]+=/)', open(self.log_path).read())
        return found[-1] if found else None

    def _call(self, method, **query):
        qs = '&'.join(f'{k}={v}' for k, v in query.items())
        return json.load(urllib.request.urlopen(f'{self.vm_url()}{method}?{qs}', timeout=10))

    def views(self):
        isolates = self._call('getVM')['result']['isolates']
        iso = [i for i in isolates if i['name'] == 'main'][0]['id']
        dump = self._call('ext.flutter.debugDumpRenderTree', isolateId=iso)['result']['data']
        return parse(dump)


def parse(dump):
    views = []
    nodes = []
    stack = []
    for line in dump.splitlines():
        m = re.match(r'^(\w+#[0-9a-f]+)', line)
        if m:
            view = View(len(views), m.group(1))
            views.append(view)
            node = dict(parent=None, props=[], texts=[], view=view)
            nodes.append(node)
            stack = [(-1, node)]
            continue
        if not stack:
            continue
        m = re.search(r'[├└]─[^:]*: (\w+#[0-9a-f]{5})\b', line)
        if m:
            col = m.start()
            while stack[-1][0] >= col:
                stack.pop()
            node = dict(parent=stack[-1][1], props=[], texts=[], view=view)
            nodes.append(node)
            stack.append((col, node))
            continue
        node = stack[-1][1]
        t = re.search(r'║\s+"(.*)"\s*$', line)
        if t:
            node['texts'].append(t.group(1))
        elif '║' not in line and '╚' not in line:
            # Long properties wrap onto indented continuation lines.
            node['props'].append(re.sub(r'^[\s│╎]*', '', line))

    for node in nodes:
        props = ' '.join(node['props'])
        node['off'] = (0.0, 0.0)
        node['size'] = None
        c = re.search(rf'configuration: BoxConstraints\(w={NUM}, h={NUM}\)', props)
        if c and node['parent'] is None:
            node['view'].size = (float(c.group(1)), float(c.group(2)))
        pd = re.search(r'parentData: (.*?)(?: constraints:| size:| layer:|$)', props)
        if pd:
            o = re.search(rf'[oO]ffset=Offset\({NUM}, {NUM}\)', pd.group(1))
            lo = re.search(rf'layoutOffset={NUM}', pd.group(1))
            if o:
                node['off'] = (float(o.group(1)), float(o.group(2)))
            elif lo:
                node['off'] = (0.0, float(lo.group(1)))
        sz = re.search(rf'\bsize: Size\({NUM}, {NUM}\)', props)
        if sz:
            node['size'] = (float(sz.group(1)), float(sz.group(2)))

    for node in nodes:
        if not node['texts'] or not node['size']:
            continue
        x = y = 0.0
        n = node
        while n:
            x += n['off'][0]
            y += n['off'][1]
            n = n['parent']
        for text in node['texts']:
            node['view'].texts.append((text, (x, y, *node['size'])))
    return views


def main(argv):
    if len(argv) < 2 or argv[1] in ('-h', '--help'):
        print(__doc__)
        return 2
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')  # Windows consoles default to a legacy codepage
    app = App(argv[1])
    if not app.vm_url():
        print(json.dumps({'error': 'no vm service url in the log yet'}))
        return 0
    if '--dump' in argv:
        isolates = app._call('getVM')['result']['isolates']
        iso = [i for i in isolates if i['name'] == 'main'][0]['id']
        print(app._call('ext.flutter.debugDumpRenderTree', isolateId=iso)['result']['data'])
        return 0
    views = app.views()
    if '--texts' in argv:
        for v in views:
            print(f'view {v.index} {v.name} size={v.size}')
            for text, (x, y, w, h) in v.texts:
                print(f'  {x:7.1f} {y:7.1f} {w:6.1f}x{h:<6.1f} {text!r}')
        return 0
    print(json.dumps([{'name': v.name, 'size': v.size,
                       'texts': [[t, list(r)] for t, r in v.texts]} for v in views]))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
