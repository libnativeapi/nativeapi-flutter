// Drag and drop example — between the window and other applications:
//
// - the left panel is a drop region: drop files (from Finder / Explorer / a
//   file manager) or text (from an editor) on it;
// - the two cards on the right drag out: the note as a file into a file
//   manager, the text into an editor, or either onto the left panel.
//
// nativeapi's DropTarget lays a transparent layer over the whole window,
// above the webview, so drops never reach the page; positions are matched
// against the panel's rectangle here. The deno desktop counterpart of
// flutter_drag_drop_example.
//
// Usage (after `npm install` at the repository root):
//   deno task dev

import { join } from "node:path";
import { tmpdir } from "node:os";
import {
  DragOperation,
  DragSource,
  DropTarget,
  type Point,
  type Rectangle,
} from "../../bindings/js/lib/index.ts";
import { nativeWindowOf, serve } from "./desktop.ts";

await serve("./ui/index.html", ["./ui/app.js", "./ui/style.css"]);

const NOTE = join(tmpdir(), "nativeapi-drag-drop-note.txt");
Deno.writeTextFileSync(NOTE, "A note dragged out of deno_drag_drop_example.\n");
const TEXT = "Hello from nativeapi";

const TITLE = "nativeapi · Drag and drop";
const browser = new Deno.BrowserWindow({ title: TITLE, width: 760, height: 460 });
const window = await nativeWindowOf(browser, TITLE);
window.setContentSize({ width: 760, height: 460 });
window.center();
browser.addEventListener("close", () => Deno.exit(0));

const state = {
  dropSupported: DropTarget.isSupported(),
  dragSupported: DragSource.isSupported(),
  note: NOTE,
  text: TEXT,
  hovering: false,
  position: null as Point | null,
  drops: 0,
  files: [] as string[],
  droppedText: null as string | null,
  lastDrag: "-",
};

/** The drop panel, in content coordinates, as the page reports it. */
let panel: Rectangle | null = null;
const inPanel = (p: Point) =>
  panel !== null && p.x >= panel.x && p.y >= panel.y && p.x < panel.x + panel.width && p.y < panel.y + panel.height;

function push() {
  browser.executeJs(`window.__apply?.(${JSON.stringify(state)})`).catch(() => {});
}

// The drop target covers the whole window; only the panel takes drops.
const target = DropTarget.create(window);
target?.addListener((event) => {
  const inside = inPanel(event.position);
  switch (event.type) {
    case "entered":
    case "moved":
      state.hovering = inside;
      state.position = inside ? { x: event.position.x - panel!.x, y: event.position.y - panel!.y } : null;
      break;
    case "exited":
      state.hovering = false;
      state.position = null;
      break;
    case "dropped":
      state.hovering = false;
      state.position = null;
      if (inside) {
        state.drops += 1;
        state.files = event.filePaths;
        state.droppedText = event.text;
      }
      break;
  }
  push();
});

browser.bind("getState", async () => state);
browser.bind("reportPanel", async (rect: Rectangle) => {
  panel = rect;
});

// Called once the pointer has moved past the drag threshold on a card, while
// the button is still down: the system takes the drag from there.
browser.bind("dragOut", async (kind: "note" | "text") => {
  const source = DragSource.create();
  if (!source) return false;
  if (kind === "note") source.setFilePaths([NOTE]);
  else source.setText(TEXT);
  source.setDragOperation(DragOperation.Copy);
  source.addListener((event) => {
    state.lastDrag = Object.entries(DragOperation).find(([, v]) => v === event.operation)![0].toLowerCase();
    push();
    source.dispose();
  });
  const started = source.startDragging(window);
  if (!started) source.dispose();
  return started;
});
