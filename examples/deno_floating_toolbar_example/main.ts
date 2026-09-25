// Floating toolbar example — a second window that is transparent, frameless
// and shadowless, belongs to the main window, and stays centred above it while
// the main window is moved, resized, minimized and restored. The deno desktop
// counterpart of flutter_floating_toolbar_example.
//
// Usage (after `npm install` at the repository root):
//   deno task dev

import { DisplayManager, TitleBarStyle, WindowManager } from "../../bindings/js/lib/index.ts";
import { nativeWindowOf, serve, serverUrl } from "./desktop.ts";

await serve("./ui/index.html", ["./ui/app.js", "./ui/style.css"]);

const MAIN_SIZE = { width: 720, height: 520 };
const TOOLBAR_SIZE = { width: 380, height: 64 };
/** How far the toolbar floats above the main window's top edge. */
const TOOLBAR_GAP = 10;
const SWATCHES = ["#3F51B5", "#009688", "#FF9800", "#E91E63"];

/**
 * On Wayland an application can neither place its top-level windows nor find
 * out where they are: the toolbar stays where the desktop puts it, and the
 * user drags it by the pill instead.
 */
const canPlaceWindows = !(Deno.build.os === "linux" && Deno.env.get("WAYLAND_DISPLAY") &&
  Deno.env.get("GDK_BACKEND") !== "x11");

// Both windows render this; Deno pushes it to them after every change.
const model = {
  color: SWATCHES[0],
  stamps: 0,
  attached: true,
  toolbarVisible: true,
  canPlaceWindows,
  swatches: SWATCHES,
  log: [] as string[],
};

const main = new Deno.BrowserWindow({ title: "Floating toolbar", ...MAIN_SIZE });
const mainNative = await nativeWindowOf(main, "Floating toolbar");
mainNative.setMinimumSize({ width: 480, height: 360 });

// The toolbar paints nothing but its pill, so its webview is transparent — a
// creation-only option, not in the typings yet.
const toolbar = new Deno.BrowserWindow({ title: "Toolbar", ...TOOLBAR_SIZE, transparent: true } as Deno.BrowserWindowOptions);
toolbar.navigate(serverUrl("/toolbar"));
const toolbarNative = await nativeWindowOf(toolbar, "Toolbar");

function broadcast() {
  const script = `window.__apply?.(${JSON.stringify(model)})`;
  for (const browser of [main, toolbar]) browser.executeJs(script).catch(() => {});
}

function note(message: string) {
  console.log(`[floating_toolbar] ${message}`);
  model.log.unshift(message);
  model.log.length = Math.min(model.log.length, 40);
  broadcast();
}

/**
 * Centres the toolbar above the main window. On macOS a child window already
 * moves with its parent; elsewhere this is what makes it follow, and on every
 * platform it re-centres after a resize.
 */
function placeToolbar() {
  const frame = mainNative.bounds;
  const size = toolbarNative.bounds;
  toolbarNative.setPosition({
    x: frame.x + (frame.width - size.width) / 2,
    y: frame.y - size.height - TOOLBAR_GAP,
  });
}

function attach() {
  const ok = toolbarNative.setParentWindow(mainNative);
  if (ok) placeToolbar();
  model.attached = ok;
  note(ok ? "Toolbar attached to the main window" : "setParentWindow failed");
}

function detach() {
  toolbarNative.setParentWindow(null);
  model.attached = false;
  note("Toolbar detached: it no longer follows");
}

function setToolbarVisible(visible: boolean) {
  if (visible) {
    if (model.attached) placeToolbar();
    toolbarNative.showInactive();
  } else {
    toolbarNative.hide();
  }
  model.toolbarVisible = visible;
  note(visible ? "Toolbar shown" : "Toolbar hidden");
}

// Leave room above the main window for the toolbar.
const area = DisplayManager.getPrimary()?.workArea;
if (area) mainNative.setPosition({ x: area.x + (area.width - MAIN_SIZE.width) / 2, y: area.y + 120 });

// Everything that makes a window a floating toolbar.
toolbarNative.setTitleBarStyle(TitleBarStyle.Hidden);
toolbarNative.setBackgroundColor({ r: 0, g: 0, b: 0, a: 0 });
toolbarNative.setHasShadow(false);
toolbarNative.setResizable(false);
toolbarNative.setMovable(false);
toolbarNative.setVisibleInTaskbar(false);
// Hiding the title bar keeps the frame; give the content its size back.
toolbarNative.setContentSize(TOOLBAR_SIZE);
attach();

const mainId = mainNative.id;
const toolbarId = toolbarNative.id;
const listener = WindowManager.addListener((event) => {
  const name = event.windowId === mainId ? "main" : event.windowId === toolbarId ? "toolbar" : `#${event.windowId}`;
  switch (event.type) {
    case "moved":
    case "resized":
      if (event.windowId === mainId && model.attached) placeToolbar();
      break;
    case "created":
    case "closed":
    case "minimized":
      note(`${event.type}: ${name}`);
      break;
    case "restored":
      note(`restored: ${name}`);
      if (event.windowId === mainId && model.attached) placeToolbar();
      break;
  }
});

/** Children first, then the parent: what closing a parent does to its children differs between platforms. */
main.addEventListener("close", () => {
  WindowManager.removeListener(listener);
  toolbarNative.setParentWindow(null);
  toolbar.close();
  Deno.exit(0);
});

for (const browser of [main, toolbar]) {
  browser.bind("getState", async () => model);
  browser.bind("pick", async (color: string) => {
    if (SWATCHES.includes(color)) model.color = color;
    broadcast();
  });
  browser.bind("stamp", async () => {
    model.stamps += 1;
    broadcast();
  });
}
main.bind("toggleAttached", async () => (model.attached ? detach() : attach()));
main.bind("toggleToolbar", async () => setToolbarVisible(!model.toolbarVisible));
// Only where the app cannot place the toolbar does the pill move it.
toolbar.bind("dragPill", async () => {
  if (!canPlaceWindows) toolbarNative.startDragging();
});
