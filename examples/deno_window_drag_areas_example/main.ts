// Window drag areas example — custom window chrome: a bar that moves the
// window and eight inset handles that resize it, drawn by the page and handed
// to the system with Window.startDragging / startResizing. The deno desktop
// counterpart of flutter_window_drag_areas_example.
//
// Usage (after `npm install` at the repository root):
//   deno task dev

import { ResizeEdge, TitleBarStyle } from "../../bindings/js/lib/index.ts";
import { nativeWindowOf, serve } from "./desktop.ts";

await serve("./ui/index.html", ["./ui/app.js", "./ui/style.css"]);

const TITLE = "nativeapi · Drag areas";
const browser = new Deno.BrowserWindow({ title: TITLE, width: 720, height: 480 });
const window = await nativeWindowOf(browser, TITLE);
// Custom chrome: no native title bar or buttons, so moving and resizing is
// left to the page's drag areas.
window.setTitleBarStyle(TitleBarStyle.Hidden);
window.setMinimumSize({ width: 480, height: 320 });
window.setContentSize({ width: 720, height: 480 });
window.center();
browser.addEventListener("close", () => Deno.exit(0));

// A press on the bar or a handle: the system takes over the gesture until the
// button is released.
browser.bind("startDragging", async () => window.startDragging());
browser.bind("startResizing", async (edge: keyof typeof ResizeEdge) => {
  if (edge in ResizeEdge) window.startResizing(ResizeEdge[edge]);
});
browser.bind("toggleMaximize", async () => {
  if (window.isMaximized) window.unmaximize();
  else window.maximize();
});
