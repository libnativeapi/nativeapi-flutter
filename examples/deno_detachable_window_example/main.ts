// Detachable window example — a `deno desktop` app whose panels can be torn
// out of the main window into windows of their own and docked back, like
// dragging a tab out of a browser.
//
// `deno desktop` provides the windows and web content (Deno.BrowserWindow);
// nativeapi provides what the web layer cannot: a drag that keeps following
// the mouse after its content moved to another window (WindowDragSession),
// exact native geometry, hit testing across windows, and opacity.
//
// Usage (after `npm install` at the repository root):
//   deno task dev      # run with hot reload
//   deno task build    # package dist/DetachableWindow.app

import {
  type Point,
  type Rectangle,
  Window,
  type WindowDragEvent,
  WindowDragSession,
  WindowManager,
} from "../../bindings/js/lib/index.ts";

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

type PanelId = "inspector" | "stopwatch";
type SlotId = "sidebar" | "bottom";

const PANEL_IDS: PanelId[] = ["inspector", "stopwatch"];
const SLOT_IDS: SlotId[] = ["sidebar", "bottom"];

/** How far the cursor has to travel from the press before a panel pops out. */
const POP_OUT_DISTANCE = 8;

/**
 * Panel state lives here, not in the webviews: a panel is rendered by
 * whichever window shows it, so moving it never loses anything.
 */
const panels = {
  inspector: { title: "Inspector", moves: 0, notes: "", clicks: 0 },
  stopwatch: { title: "Stopwatch", moves: 0, running: false, startedAt: 0, accumulated: 0 },
};

const dock: Record<SlotId, PanelId | null> = { sidebar: "inspector", bottom: "stopwatch" };

interface Floating {
  browser: Deno.BrowserWindow;
  native: Window;
}
const floating = new Map<PanelId, Floating>();

/** Slot rectangles inside the main window's content, as its webview reports them. */
let slotRects: Partial<Record<SlotId, Rectangle>> = {};
/** The empty slot a dragged panel would dock into on release. */
let highlight: SlotId | null = null;

function snapshot() {
  return { dock, floating: [...floating.keys()], highlight, panels };
}

function slotOf(panel: PanelId): SlotId | null {
  return SLOT_IDS.find((slot) => dock[slot] === panel) ?? null;
}

// ---------------------------------------------------------------------------
// Windows
// ---------------------------------------------------------------------------

const html = await Deno.readTextFile(new URL("./ui/index.html", import.meta.url));
const assets: Record<string, [string, string]> = {
  "/ui/app.js": ["text/javascript", await Deno.readTextFile(new URL("./ui/app.js", import.meta.url))],
  "/ui/style.css": ["text/css", await Deno.readTextFile(new URL("./ui/style.css", import.meta.url))],
};

Deno.serve((request) => {
  const path = new URL(request.url).pathname;
  const asset = assets[path];
  if (asset) {
    return new Response(asset[1], { headers: { "content-type": asset[0] } });
  }
  return new Response(html, { headers: { "content-type": "text/html" } });
});

function serverUrl(path: string): string {
  const port = Deno.env.get("DENO_SERVE_ADDRESS")!.split(":").pop();
  return `http://127.0.0.1:${port}${path}`;
}

/**
 * The nativeapi Window behind a Deno.BrowserWindow. The two libraries number
 * windows independently, so find it by a title only it carries for a moment.
 */
async function nativeWindowOf(browser: Deno.BrowserWindow, title: string): Promise<Window> {
  const token = `${title} #${crypto.randomUUID()}`;
  browser.setTitle(token);
  try {
    for (let attempt = 0; attempt < 200; attempt++) {
      const match = WindowManager.getAll().find((window) => window.title === token);
      if (match) {
        return match;
      }
      await new Promise((resolve) => setTimeout(resolve, 10));
    }
    throw new Error(`no native window titled ${token}`);
  } finally {
    browser.setTitle(title);
  }
}

const main = new Deno.BrowserWindow({ title: "Detachable Window", width: 960, height: 640 });
const mainNative = await nativeWindowOf(main, "Detachable Window");
bindUi(main);
main.addEventListener("close", () => Deno.exit(0));

/** Pushes the current state into every open webview. */
function broadcast() {
  const script = `window.__apply(${JSON.stringify(snapshot())})`;
  for (const browser of [main, ...[...floating.values()].map((entry) => entry.browser)]) {
    browser.executeJs(script).catch(() => {
      // Not loaded yet; the page asks for the state itself once it is.
    });
  }
}

/** Screen rectangle of a slot, from the main window's content origin. */
function slotScreenRect(slot: SlotId): Rectangle | null {
  const rect = slotRects[slot];
  if (!rect) {
    return null;
  }
  const content = mainNative.contentBounds;
  return { x: content.x + rect.x, y: content.y + rect.y, width: rect.width, height: rect.height };
}

/** Offset of the content's top-left corner inside the window frame. */
function contentOffset(window: Window): Point {
  const frame = window.bounds;
  const content = window.contentBounds;
  return { x: content.x - frame.x, y: content.y - frame.y };
}

async function openFloating(panel: PanelId, contentRect: Rectangle): Promise<Floating> {
  const title = panels[panel].title;
  const browser = new Deno.BrowserWindow({
    title,
    width: Math.round(contentRect.width),
    height: Math.round(contentRect.height),
  });
  browser.navigate(serverUrl(`/panel/${panel}`));
  bindUi(browser);
  const native = await nativeWindowOf(browser, title);
  // BrowserWindow places new windows itself; put this one exactly over the
  // spot the panel occupied.
  native.setContentBounds(contentRect);
  const entry = { browser, native };
  floating.set(panel, entry);
  // Closing a floating window docks its panel back instead.
  browser.addEventListener("close", (event) => {
    if (floating.get(panel) === entry) {
      event.preventDefault();
      dockPanel(panel, null);
    }
  });
  return entry;
}

function dockPanel(panel: PanelId, slot: SlotId | null) {
  const target = slot ?? SLOT_IDS.find((candidate) => dock[candidate] === null);
  if (!target || dock[target] !== null) {
    return;
  }
  const entry = floating.get(panel);
  floating.delete(panel);
  dock[target] = panel;
  panels[panel].moves += 1;
  entry?.browser.close();
  mainNative.focus();
  broadcast();
}

// ---------------------------------------------------------------------------
// The drag gesture
// ---------------------------------------------------------------------------

type Gesture =
  // Pressed on a docked panel's header; not yet far enough to pop out.
  | { phase: "pressed"; panel: PanelId; slot: SlotId; press: Point; offset: Point }
  // Waiting for the new window before handing the drag over to it.
  | { phase: "popping"; panel: PanelId }
  // A floating window follows the cursor.
  | { phase: "moving"; panel: PanelId; entry: Floating };

const session = WindowDragSession.create()!;
let gesture: Gesture | null = null;

session.addListener((event) => void onDrag(event));

async function onDrag(event: WindowDragEvent) {
  const current = gesture;
  if (!current) {
    return;
  }
  const cursor = event.cursorPosition;

  if (current.phase === "pressed") {
    if (event.type !== "moved") {
      gesture = null; // A click, not a drag.
      return;
    }
    const distance = Math.hypot(cursor.x - current.press.x, cursor.y - current.press.y);
    if (distance < POP_OUT_DISTANCE) {
      return;
    }
    await popOut(current, cursor);
    return;
  }

  if (current.phase === "moving") {
    if (event.type === "moved") {
      updateHighlight(current, cursor);
    } else {
      finishMove(current, event.type === "ended");
    }
  }
}

/** Moves a docked panel into its own window under the cursor, mid-drag. */
async function popOut(pressed: Extract<Gesture, { phase: "pressed" }>, cursor: Point) {
  gesture = { phase: "popping", panel: pressed.panel };
  const slotRect = slotScreenRect(pressed.slot)!;
  dock[pressed.slot] = null;
  panels[pressed.panel].moves += 1;
  broadcast();

  // Where the panel sat, shifted by how far the cursor has already travelled.
  const origin = {
    x: slotRect.x + cursor.x - pressed.press.x,
    y: slotRect.y + cursor.y - pressed.press.y,
    width: slotRect.width,
    height: slotRect.height,
  };
  const entry = await openFloating(pressed.panel, origin);

  const inset = contentOffset(entry.native);
  const anchor = { x: inset.x + pressed.offset.x, y: inset.y + pressed.offset.y };
  if (session.isActive && session.start(entry.native, anchor)) {
    gesture = { phase: "moving", panel: pressed.panel, entry };
  } else {
    // Released while the window was being created: it stays where it is.
    gesture = null;
    entry.native.focus();
    broadcast();
  }
}

/** Highlights the empty slot under the cursor, looking through the dragged window. */
function updateHighlight(moving: Extract<Gesture, { phase: "moving" }>, cursor: Point) {
  let next: SlotId | null = null;
  const below = WindowManager.getWindowAtPoint(cursor, moving.entry.native.id);
  if (below?.id === mainNative.id) {
    next = SLOT_IDS.find((slot) => {
      const rect = slotScreenRect(slot);
      return dock[slot] === null && rect !== null && cursor.x >= rect.x &&
        cursor.x < rect.x + rect.width && cursor.y >= rect.y && cursor.y < rect.y + rect.height;
    }) ?? null;
  }
  below?.dispose();
  if (next !== highlight) {
    highlight = next;
    moving.entry.native.setOpacity(next ? 0.6 : 1);
    broadcast();
  }
}

function finishMove(moving: Extract<Gesture, { phase: "moving" }>, released: boolean) {
  gesture = null;
  const target = released ? highlight : null;
  highlight = null;
  moving.entry.native.setOpacity(1);
  if (target) {
    dockPanel(moving.panel, target);
  } else {
    // A panel left floating is what the user works with next.
    moving.entry.native.focus();
    broadcast();
  }
}

// ---------------------------------------------------------------------------
// Bindings: what the webviews can ask for
// ---------------------------------------------------------------------------

// Handlers are async because the webview side always receives a promise.
function bindUi(browser: Deno.BrowserWindow) {
  browser.bind("getState", async () => snapshot());

  browser.bind("reportSlots", async (rects: Partial<Record<SlotId, Rectangle>>) => {
    slotRects = rects;
  });

  // A press on a panel header, in content coordinates of the pressed window.
  browser.bind("pressHeader", async (panel: PanelId, point: Point) => {
    if (!PANEL_IDS.includes(panel) || gesture) {
      return;
    }
    const entry = floating.get(panel);
    if (entry) {
      const inset = contentOffset(entry.native);
      if (session.start(entry.native, { x: inset.x + point.x, y: inset.y + point.y })) {
        gesture = { phase: "moving", panel, entry };
      }
      return;
    }
    const slot = slotOf(panel);
    const rect = slot && slotRects[slot];
    if (!slot || !rect) {
      return;
    }
    const content = mainNative.contentBounds;
    const press = { x: content.x + point.x, y: content.y + point.y };
    // Follow the pointer without moving anything until it travels far enough.
    if (session.start(null, { x: 0, y: 0 })) {
      gesture = {
        phase: "pressed",
        panel,
        slot,
        press,
        offset: { x: point.x - rect.x, y: point.y - rect.y },
      };
    }
  });

  browser.bind("popOut", async (panel: PanelId) => {
    const slot = slotOf(panel);
    const rect = slot && slotScreenRect(slot);
    if (!slot || !rect || gesture) {
      return;
    }
    dock[slot] = null;
    panels[panel].moves += 1;
    broadcast();
    // Beside the main window, level with the slot it came from.
    const frame = mainNative.bounds;
    const entry = await openFloating(panel, { ...rect, x: frame.x + frame.width + 16 });
    entry.native.focus();
    broadcast();
  });

  browser.bind("dock", async (panel: PanelId) => dockPanel(panel, null));

  browser.bind("setNotes", async (text: string) => {
    panels.inspector.notes = String(text);
  });

  browser.bind("click", async () => {
    panels.inspector.clicks += 1;
    broadcast();
  });

  browser.bind("toggleStopwatch", async () => {
    const watch = panels.stopwatch;
    if (watch.running) {
      watch.accumulated += Date.now() - watch.startedAt;
    } else {
      watch.startedAt = Date.now();
    }
    watch.running = !watch.running;
    broadcast();
  });

  browser.bind("resetStopwatch", async () => {
    Object.assign(panels.stopwatch, { running: false, startedAt: 0, accumulated: 0 });
    broadcast();
  });
}
