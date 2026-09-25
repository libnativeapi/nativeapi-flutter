// Multiple window example — three windows laid out on the primary display by
// nativeapi: WindowManager.setWillShowHook catches each window just before it
// is shown, sizes and positions it against Display.workArea, and then lets the
// show through with callOriginalShow. The deno desktop counterpart of
// flutter_multiple_window_example.
//
// Usage (after `npm install` at the repository root):
//   deno task dev

import { DisplayManager, type Rectangle, WindowManager } from "../../bindings/js/lib/index.ts";
import { serve, serverUrl } from "./desktop.ts";

await serve("./ui/index.html", ["./ui/app.js", "./ui/style.css"]);

const ROLES = ["Primary", "Secondary", "Tertiary"] as const;
type Role = (typeof ROLES)[number];
const titleOf = (role: Role) => `${role} Window`;

/**
 * The slot of each window: 60% of the work area, centred; the primary window
 * takes the top row, the other two share the bottom row.
 */
function layout(role: Role): Rectangle | null {
  const area = DisplayManager.getPrimary()?.workArea;
  if (!area) return null;
  const width = area.width * 0.6;
  const height = area.height * 0.6;
  const x = area.x + (area.width - width) / 2;
  const y = area.y + (area.height - height) / 2;
  const row = height / 2;
  switch (role) {
    case "Primary":
      return { x, y, width, height: row };
    case "Secondary":
      return { x, y: y + row, width: width / 2, height: row };
    case "Tertiary":
      return { x: x + width / 2, y: y + row, width: width / 2, height: row };
  }
}

const log: string[] = [];
function note(line: string) {
  console.log(line);
  log.push(line);
  broadcast();
}

// A will-show hook replaces the platform's show: a window whose hook does not
// call callOriginalShow() never appears.
WindowManager.setWillShowHook((windowId) => {
  const window = WindowManager.get(windowId);
  const role = ROLES.find((r) => titleOf(r) === window?.title);
  const slot = role && layout(role);
  if (window && slot) {
    window.setBounds(slot);
    note(`will show #${windowId} (${window.title}): placed at ${Math.round(slot.x)}, ${Math.round(slot.y)}, ${Math.round(slot.width)} × ${Math.round(slot.height)}`);
  }
  window?.dispose();
  WindowManager.callOriginalShow(windowId);
});
WindowManager.setWillHideHook((windowId) => {
  note(`will hide #${windowId}`);
  WindowManager.callOriginalHide(windowId);
});

const open = new Map<Role, Deno.BrowserWindow>();

function openWindow(role: Role) {
  const existing = open.get(role);
  if (existing) {
    existing.show();
    existing.focus();
    return;
  }
  const browser = new Deno.BrowserWindow({ title: titleOf(role) });
  browser.navigate(serverUrl(`/${role.toLowerCase()}`));
  browser.bind("getState", async () => state());
  browser.bind("open", async (next: Role) => {
    if (ROLES.includes(next)) openWindow(next);
  });
  browser.bind("hide", async () => browser.hide());
  browser.addEventListener("close", () => {
    open.delete(role);
    if (role === "Primary") Deno.exit(0);
    broadcast();
  });
  open.set(role, browser);
  broadcast();
}

function state() {
  return { open: [...open.keys()], log };
}

function broadcast() {
  const script = `window.__apply?.(${JSON.stringify(state())})`;
  for (const browser of open.values()) browser.executeJs(script).catch(() => {});
}

// The window deno desktop opens at startup is on screen before the hook is
// installed; open the primary window anew so it goes through the hook too.
const startup = new Deno.BrowserWindow({ title: "startup" });
openWindow("Primary");
startup.close();
