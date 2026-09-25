// Browser tabs example — Chrome-style tabs across several windows, built on
// nativeapi's WindowDragSession and WindowManager.getWindowAtPoint. The deno
// desktop counterpart of flutter_browser_tabs_example.
//
// - Reorder: drag a tab along its strip.
// - Tear off: drag a tab more than 28 px above or below the strip; it becomes
//   a new window of the same size with the tab under the cursor. A window's
//   only tab takes the whole window along instead.
// - Merge: drag a torn-off tab over another window's strip; it joins that
//   strip at the cursor while you are still dragging.
// - Move a window: drag the empty part of a strip.
//
// Every step after the press is driven by the native session's cursor
// position: once a tab has been merged into another window, that window's
// page never saw the press. Each webview is its own page, so a tab's page
// state (address, likes, scroll position, running timer) lives here and
// follows the tab from window to window.
//
// Usage (after `npm install` at the repository root):
//   deno task dev

import {
  DisplayManager,
  type Point,
  type Rectangle,
  TitleBarStyle,
  Window,
  type WindowDragEvent,
  WindowDragSession,
  WindowManager,
} from "../../bindings/js/lib/index.ts";
import { nativeWindowOf, serve, serverUrl } from "./desktop.ts";

await serve("./ui/index.html", ["./ui/app.js", "./ui/style.css"]);

// ---------------------------------------------------------------------------
// Strip geometry, shared by the pages (which draw it from what `layoutOf`
// sends) and the drag state machine (which hit-tests it).
// ---------------------------------------------------------------------------

const MAC = Deno.build.os === "darwin";
const STRIP = {
  height: 40,
  tabTop: 6,
  newTabWidth: 40,
  minTab: 72,
  maxTab: 220,
  /** How far above or below the strip a dragged tab may go before it tears off. */
  detachMargin: 28,
  // On macOS the strip sits under a transparent title bar and leaves room for
  // the traffic lights; elsewhere the title bar is hidden and the strip
  // carries its own close button.
  leading: MAC ? 78 : 8,
  trailing: MAC ? 8 : 48,
};
const tabExtent = (width: number, count: number) =>
  count <= 0 ? STRIP.maxTab : Math.min(STRIP.maxTab, Math.max(STRIP.minTab, (width - STRIP.leading - STRIP.trailing - STRIP.newTabWidth) / count));
const tabLeft = (index: number, extent: number) => STRIP.leading + index * extent;
const indexForLeft = (left: number, extent: number, count: number) =>
  count <= 1 ? 0 : Math.min(count - 1, Math.max(0, Math.round((left - STRIP.leading) / extent)));
const clampLeft = (left: number, extent: number, count: number) =>
  Math.min(STRIP.leading + (count - 1) * extent, Math.max(STRIP.leading, left));

// ---------------------------------------------------------------------------
// Tabs and windows
// ---------------------------------------------------------------------------

const PALETTE = ["#3F51B5", "#009688", "#FF5722", "#E91E63", "#4CAF50", "#9C27B0", "#607D8B", "#FFC107"];

interface Tab {
  id: number;
  title: string;
  color: string;
  // The page's state, which would be lost if the page were rebuilt.
  address: string;
  likes: number;
  moves: number;
  scroll: number;
  openedAt: number;
}

interface BrowserWindow {
  key: number;
  browser: Deno.BrowserWindow;
  native: Window;
  tabs: Tab[];
  active: Tab;
}

type Drag = {
  tab: Tab | null;
  window: BrowserWindow;
  /** Where the tab was grabbed, relative to its top-left corner. */
  grab: Point;
  /** Screen position of the press. */
  press: Point;
  mode: "pending" | "inStrip" | "window" | "moveWindow" | "opening";
  /** Left edge of the dragged tab relative to the strip, while inStrip. */
  left: number;
};

const DEFAULT_SIZE = { width: 760, height: 520 };
const POP_OUT_DISTANCE = 8;

const windows: BrowserWindow[] = [];
const session = WindowDragSession.create()!;
let drag: Drag | null = null;
let nextTabId = 1;
let nextWindowKey = 1;

function createTab(): Tab {
  const id = nextTabId++;
  return {
    id,
    title: `Tab ${id}`,
    color: PALETTE[(id - 1) % PALETTE.length],
    address: `https://example.com/tab-${id}`,
    likes: 0,
    moves: 0,
    scroll: 0,
    openedAt: Date.now(),
  };
}

/** Offset of the content's top-left corner inside the window frame. */
function contentInset(native: Window): Point {
  const frame = native.bounds;
  const content = native.contentBounds;
  return { x: content.x - frame.x, y: content.y - frame.y };
}

/** A window's tab strip in screen coordinates: the top of its content. */
function stripRect(window: BrowserWindow): Rectangle {
  const content = window.native.contentBounds;
  return { x: content.x, y: content.y, width: content.width, height: STRIP.height };
}

const contains = (r: Rectangle, p: Point) => p.x >= r.x && p.y >= r.y && p.x < r.x + r.width && p.y < r.y + r.height;

async function openWindow(tabs: Tab[], size = DEFAULT_SIZE): Promise<BrowserWindow> {
  const key = nextWindowKey++;
  const browser = new Deno.BrowserWindow({ title: "Browser", ...size });
  browser.navigate(serverUrl(`/window/${key}`));
  const native = await nativeWindowOf(browser, "Browser");
  native.setMinimumSize({ width: 420, height: 280 });
  // The strip takes the title bar's place. On macOS the traffic lights stay
  // on a transparent bar; elsewhere the title bar goes, buttons and all.
  if (!native.setContentUnderTitleBar(true)) native.setTitleBarStyle(TitleBarStyle.Hidden);
  // Either way the frame is kept and the content grew into the title bar
  // area; give it back the requested size.
  native.setContentSize(size);
  const window: BrowserWindow = { key, browser, native, tabs, active: tabs[0] };
  windows.push(window);
  bindWindow(window);
  browser.addEventListener("close", () => closeWindow(window));
  browser.addEventListener("resize", () => push(window));
  return window;
}

function closeWindow(window: BrowserWindow) {
  const index = windows.indexOf(window);
  if (index < 0) return;
  windows.splice(index, 1);
  if (drag?.window === window) {
    drag = null;
    session.cancel();
  }
  window.browser.close();
  if (windows.length === 0) Deno.exit(0);
}

function removeTab(window: BrowserWindow, tab: Tab) {
  const index = window.tabs.indexOf(tab);
  if (index < 0) return;
  window.tabs.splice(index, 1);
  if (window.active === tab && window.tabs.length > 0) {
    window.active = window.tabs[Math.min(index, window.tabs.length - 1)];
  }
}

// ---------------------------------------------------------------------------
// Rendering: every window's page gets its strip layout and its active tab.
// ---------------------------------------------------------------------------

function layoutOf(window: BrowserWindow) {
  const width = window.native.contentBounds.width;
  const extent = tabExtent(width, window.tabs.length);
  return {
    closeButton: !MAC,
    leading: STRIP.leading,
    newTabLeft: tabLeft(window.tabs.length, extent),
    tabs: window.tabs.map((tab, index) => {
      const dragged = drag?.tab === tab && drag.window === window;
      return {
        id: tab.id,
        title: tab.title,
        color: tab.color,
        width: extent,
        left: dragged && drag!.mode === "inStrip" ? drag!.left : tabLeft(index, extent),
        active: tab === window.active,
        dragging: dragged,
      };
    }),
    page: window.active && {
      id: window.active.id,
      title: window.active.title,
      color: window.active.color,
      address: window.active.address,
      likes: window.active.likes,
      moves: window.active.moves,
      scroll: window.active.scroll,
      openedAt: window.active.openedAt,
    },
  };
}

function push(window: BrowserWindow) {
  window.browser.executeJs(`window.__apply?.(${JSON.stringify(layoutOf(window))})`).catch(() => {});
}
const pushAll = () => windows.forEach(push);

// ---------------------------------------------------------------------------
// The drag state machine, driven by the session's cursor position
// ---------------------------------------------------------------------------

session.addListener((event) => void onDrag(event));

async function onDrag(event: WindowDragEvent) {
  const current = drag;
  if (!current) return;
  if (event.type !== "moved") {
    drag = null;
    if (current.mode === "window") current.window.native.focus();
    pushAll();
    return;
  }
  const cursor = event.cursorPosition;
  switch (current.mode) {
    case "moveWindow":
    case "opening":
      return;
    case "pending":
      if (Math.hypot(cursor.x - current.press.x, cursor.y - current.press.y) < POP_OUT_DISTANCE) return;
      current.mode = "inStrip";
      await moveInStrip(current, cursor);
      return;
    case "inStrip":
      await moveInStrip(current, cursor);
      return;
    case "window": {
      const target = windowWithStripAt(cursor, current.window);
      if (target) mergeInto(current, target, cursor);
      return;
    }
  }
}

async function moveInStrip(current: Drag, cursor: Point) {
  const strip = stripRect(current.window);
  if (cursor.y < strip.y - STRIP.detachMargin || cursor.y > strip.y + strip.height + STRIP.detachMargin) {
    await tearOff(current);
    return;
  }
  placeInStrip(current, current.window, strip, cursor);
  push(current.window);
}

/** Puts the dragged tab under the cursor and moves it to the index it covers. */
function placeInStrip(current: Drag, window: BrowserWindow, strip: Rectangle, cursor: Point) {
  const tab = current.tab!;
  const count = window.tabs.length;
  const extent = tabExtent(strip.width, count);
  current.left = clampLeft(cursor.x - strip.x - current.grab.x, extent, count);
  const index = indexForLeft(current.left, extent, count);
  const at = window.tabs.indexOf(tab);
  if (index !== at) {
    window.tabs.splice(at, 1);
    window.tabs.splice(index, 0, tab);
  }
}

/** The frame point that keeps the grabbed point of a window's first tab under the cursor. */
function anchorFor(native: Window, current: Drag): Point {
  const inset = contentInset(native);
  return { x: inset.x + STRIP.leading + current.grab.x, y: inset.y + STRIP.tabTop + current.grab.y };
}

async function tearOff(current: Drag) {
  const source = current.window;
  const tab = current.tab!;
  if (source.tabs.length === 1) {
    // Nothing would be left behind: carry the whole window instead.
    session.start(source.native, anchorFor(source.native, current));
    current.mode = "window";
    push(source);
    return;
  }
  // Creating the window takes a moment; the session keeps tracking meanwhile.
  current.mode = "opening";
  const size = source.native.contentSize;
  removeTab(source, tab);
  tab.moves += 1;
  push(source);
  const torn = await openWindow([tab], size);
  if (drag !== current || !session.isActive || !session.start(torn.native, anchorFor(torn.native, current))) {
    // Released while the window was being created: it stays where it is.
    if (drag === current) drag = null;
    session.cancel();
    pushAll();
    return;
  }
  torn.native.focus();
  current.window = torn;
  current.mode = "window";
  pushAll();
}

function mergeInto(current: Drag, target: BrowserWindow, cursor: Point) {
  const dragged = current.window;
  const tab = current.tab!;
  // Stop moving the dragged window before it goes; the gesture carries on as
  // a drag along the target's strip.
  session.start(null, { x: 0, y: 0 });
  current.window = target;
  current.mode = "inStrip";
  removeTab(dragged, tab);
  closeWindow(dragged);
  target.tabs.push(tab);
  target.active = tab;
  tab.moves += 1;
  placeInStrip(current, target, stripRect(target), cursor);
  target.native.focus();
  push(target);
}

/** The window whose strip is under the cursor and not covered by another window. */
function windowWithStripAt(cursor: Point, excluding: BrowserWindow): BrowserWindow | null {
  const hit = WindowManager.getWindowAtPoint(cursor, excluding.native.id);
  const hitId = hit?.id;
  hit?.dispose();
  const window = windows.find((w) => w !== excluding && w.native.id === hitId);
  return window && contains(stripRect(window), cursor) ? window : null;
}

// ---------------------------------------------------------------------------
// Bindings
// ---------------------------------------------------------------------------

function bindWindow(window: BrowserWindow) {
  const { browser } = window;
  const tabById = (id: number) => window.tabs.find((tab) => tab.id === id);
  browser.bind("getState", async () => layoutOf(window));

  // A press on a tab, which may become a reorder, a tear-off or a merge.
  browser.bind("pressTab", async (id: number, grab: Point, pointer: Point) => {
    const tab = tabById(id);
    if (!tab || drag) return;
    window.active = tab;
    push(window);
    if (!session.start(null, { x: 0, y: 0 })) return;
    const content = window.native.contentBounds;
    drag = { tab, window, grab, press: { x: content.x + pointer.x, y: content.y + pointer.y }, mode: "pending", left: 0 };
  });

  // A press on the empty part of the strip moves the window.
  browser.bind("pressStrip", async (pointer: Point) => {
    if (drag) return;
    const inset = contentInset(window.native);
    if (session.start(window.native, { x: inset.x + pointer.x, y: inset.y + pointer.y })) {
      drag = { tab: null, window, grab: { x: 0, y: 0 }, press: { x: 0, y: 0 }, mode: "moveWindow", left: 0 };
    }
  });

  browser.bind("addTab", async () => {
    const tab = createTab();
    window.tabs.push(tab);
    window.active = tab;
    push(window);
  });
  browser.bind("closeTab", async (id: number) => {
    const tab = tabById(id);
    if (!tab || drag?.tab === tab) return;
    removeTab(window, tab);
    if (window.tabs.length === 0) closeWindow(window);
    else push(window);
  });
  browser.bind("closeWindow", async () => closeWindow(window));

  // The page reports what the user changed, so it survives a move.
  browser.bind("savePage", async (id: number, change: { address?: string; scroll?: number; like?: boolean }) => {
    const tab = tabById(id);
    if (!tab) return;
    if (typeof change.address === "string") tab.address = change.address;
    if (typeof change.scroll === "number") tab.scroll = change.scroll;
    if (change.like) {
      tab.likes += 1;
      push(window);
    }
  });
}

// ---------------------------------------------------------------------------
// Start: two windows side by side, with four and two tabs
// ---------------------------------------------------------------------------

// The startup window cannot take part: its creation options are fixed. Every
// browser window is opened anew, and the startup one closed afterwards.
const startup = new Deno.BrowserWindow({ title: "startup" });
const first = await openWindow([createTab(), createTab(), createTab(), createTab()]);
const second = await openWindow([createTab(), createTab()]);
startup.close();

const area = DisplayManager.getPrimary()?.workArea;
if (area) {
  const placed = [first, second];
  placed.forEach((window, i) => {
    const width = window.native.bounds.width;
    const step = Math.min(width + 24, Math.max(0, (area.width - width) / (placed.length - 1)));
    const left = area.x + (area.width - width - step * (placed.length - 1)) / 2 + step * i;
    window.native.setPosition({ x: left, y: area.y + 80 + 60 * i });
  });
}
pushAll();
