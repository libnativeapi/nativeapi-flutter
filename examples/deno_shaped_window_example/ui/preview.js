// The "Shape preview" window: artwork in a size × size square at the top
// left. The window clips it natively; only where the renderer clips (Linux)
// does the page apply the same polygon itself.

import { art } from "./art.js";

const app = document.getElementById("app");
const box = document.createElement("div");
box.className = "preview";
const drag = Object.assign(document.createElement("div"), { className: "drag", textContent: "⠿  DRAG ME" });
drag.addEventListener("pointerdown", (event) => {
  if (event.button === 0) bindings.startDragging();
});
const label = Object.assign(document.createElement("div"), { className: "label" });
const tap = Object.assign(document.createElement("button"), { className: "tap" });
tap.addEventListener("click", () => bindings.tap());
const lookName = Object.assign(document.createElement("div"), { className: "look" });
const content = document.createElement("div");
content.className = "preview-content";
content.append(drag, label, tap, lookName);
app.append(box);

let artwork = null;
window.__apply = (s) => {
  box.style.width = box.style.height = `${s.size}px`;
  box.style.clipPath = s.clip ? `polygon(evenodd, ${s.clip})` : "";
  const next = art(s.look.colors);
  next.append(content);
  if (artwork) artwork.replaceWith(next);
  else box.append(next);
  artwork = next;
  label.textContent = s.label;
  tap.textContent = `Tap · ${s.count}`;
  lookName.textContent = s.look.name.toUpperCase();
};
bindings.getState().then(window.__apply);
