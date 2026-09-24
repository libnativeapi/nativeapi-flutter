// Window example — opens a window, reacts to its events, and runs the event
// loop alongside ordinary JavaScript timers until the window is closed.
//
// Usage (after `npm install` at the repository root):
//   npm start -w js_window_example           # Node.js 22.18+
//   deno task start                          # from this directory
//   bun main.ts                              # from this directory

import { Application, Display, DisplayManager, TitleBarStyle, Window, WindowManager } from "nativeapi";

const window = Window.create();
if (!window) {
  console.error("Failed to create a window.");
  process.exit(1);
}
console.log(`Created window #${window.id}`);

// --- Title and geometry ---
window.setTitle("JS Window Example");
window.setSize({ width: 800, height: 600 }, false);
window.setMinimumSize({ width: 400, height: 300 });
window.setTitleBarStyle(TitleBarStyle.Normal);
window.center();
console.log("Title:", window.title);
console.log("Bounds:", window.bounds);

const primary: Display | null = DisplayManager.getPrimary();
console.log("Primary display:", primary?.name);

// --- Events ---
// One listener receives every window event; `type` says which.
WindowManager.addListener((event) => {
  switch (event.type) {
    case "moved":
      console.log(`[event] window ${event.windowId} moved to`, event.newPosition);
      break;
    case "resized":
      console.log(`[event] window ${event.windowId} resized to`, event.newSize);
      break;
    case "closed":
      console.log(`[event] window ${event.windowId} closed`);
      if (event.windowId === window.id) {
        Application.quit(0);
      }
      break;
    default:
      console.log(`[event] window ${event.windowId} ${event.type}`);
  }
});
Application.addListener((event) => console.log("[app]", event.type));

// --- Run ---
// The platform loop is pumped from the JS event loop, so timers keep firing.
let seconds = 0;
const ticker = setInterval(() => {
  seconds += 1;
  window.setTitle(`JS Window Example — ${seconds}s`);
}, 1000);

const exitCode = await Application.run(window);
clearInterval(ticker);
console.log(`Event loop finished with exit code ${exitCode}`);
