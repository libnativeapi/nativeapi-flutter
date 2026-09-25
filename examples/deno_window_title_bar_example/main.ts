// Window title bar example — every state a window's title bar can be in, on
// one screen, for testing by hand. The deno desktop counterpart of
// flutter_window_title_bar_example.
//
// Usage (after `npm install` at the repository root):
//   deno task dev

import { TitleBarStyle, Window } from "../../bindings/js/lib/index.ts";
import { nativeWindowOf, serve } from "./desktop.ts";

await serve("./ui/index.html", ["./ui/app.js", "./ui/style.css"]);

const TITLE = "nativeapi · Title bar";
const browser = new Deno.BrowserWindow({ title: TITLE, width: 620, height: 520 });
const window = await nativeWindowOf(browser, TITLE);
window.setMinimumSize({ width: 520, height: 420 });
window.setContentSize({ width: 620, height: 520 });
window.center();
browser.addEventListener("close", () => Deno.exit(0));

function status() {
  const size = window.contentSize;
  return {
    style: window.titleBarStyle === TitleBarStyle.Hidden ? "hidden" : "normal",
    under: window.isContentUnderTitleBar,
    buttons: window.isWindowControlButtonsVisible,
    supported: Window.isContentUnderTitleBarSupported(),
    size: `${Math.round(size.width)} × ${Math.round(size.height)}`,
  };
}

const actions: Record<string, [string, () => void]> = {
  normal: ["Standard title bar", () => {
    window.setContentUnderTitleBar(false);
    window.setTitleBarStyle(TitleBarStyle.Normal);
  }],
  under: ["The bar is a transparent overlay; its buttons stay", () => {
    window.setTitleBarStyle(TitleBarStyle.Normal);
    window.setContentUnderTitleBar(true);
  }],
  hidden: ["No title bar and no window buttons — move me by the strip", () => {
    window.setTitleBarStyle(TitleBarStyle.Hidden);
  }],
  showButtons: ["Buttons shown", () => window.setWindowControlButtonsVisible(true)],
  hideButtons: ["Buttons hidden", () => window.setWindowControlButtonsVisible(false)],
};

browser.bind("status", async () => status());
browser.bind("act", async (name: string) => {
  const [note, change] = actions[name];
  change();
  return { ...status(), note };
});
// The strip is the example's own title bar: a press on it hands the drag to
// the system, a double click maximizes and restores.
browser.bind("dragStrip", async () => window.startDragging());
browser.bind("toggleMaximize", async () => {
  if (window.isMaximized) window.unmaximize();
  else window.maximize();
});
browser.bind("quit", async () => Deno.exit(0));
