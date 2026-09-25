// Visual effect example — a window whose background is a translucent
// material, set with Window.setVisualEffect. The deno desktop counterpart of
// flutter_visual_effect_example.
//
// Usage (after `npm install` at the repository root):
//   deno task dev

import { Color, VisualEffect, Window } from "../../bindings/js/lib/index.ts";
import { nativeWindowOf, serve, transparentWindow } from "./desktop.ts";

await serve("./ui/index.html", ["./ui/app.js", "./ui/style.css"]);

const TITLE = "Visual effect";
// The material shows only where nothing is painted, so the webview must not
// paint a background of its own.
const browser = transparentWindow({ title: TITLE, width: 560, height: 480 });
const window = await nativeWindowOf(browser, TITLE);
window.setContentSize({ width: 560, height: 480 });
window.center();
// Let the material run to the top edge; the window buttons stay on top.
window.setContentUnderTitleBar(true);
browser.addEventListener("close", () => Deno.exit(0));

const EFFECTS = Object.entries(VisualEffect) as [string, VisualEffect][];
const nameOf = (effect: VisualEffect) => EFFECTS.find(([, value]) => value === effect)![0];

/** A plain red window behind this one, so there is something to blur. */
let backdrop: Window | null = null;
let note = "Pick an effect";

function status() {
  return {
    current: nameOf(window.visualEffect),
    note,
    backdrop: backdrop !== null,
    effects: EFFECTS.map(([name, value]) => ({ name, supported: Window.isVisualEffectSupported(value) })),
  };
}

browser.bind("status", async () => status());

browser.bind("apply", async (name: string) => {
  const effect = VisualEffect[name as keyof typeof VisualEffect];
  note = window.setVisualEffect(effect) ? `Applied ${name}` : `Refused ${name}`;
  return status();
});

browser.bind("toggleBackdrop", async () => {
  if (backdrop) {
    window.setParentWindow(null);
    backdrop.hide();
    backdrop.dispose();
    backdrop = null;
    return status();
  }
  backdrop = Window.create();
  if (backdrop) {
    const frame = window.bounds;
    backdrop.setTitle("Backdrop");
    backdrop.setBackgroundColor({ ...Color.Red });
    backdrop.setBounds({
      x: frame.x - 80,
      y: frame.y - 80,
      width: frame.width + 160,
      height: frame.height + 160,
    });
    backdrop.show();
    // A child stays above its parent, whichever of the two is brought forward.
    window.setParentWindow(backdrop);
    window.focus();
  }
  return status();
});
