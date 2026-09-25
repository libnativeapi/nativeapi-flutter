// The drag areas: pressing the bar or a handle hands the gesture to the
// system through Deno; everything else is ordinary page behaviour.

const LIMITED = new Set(["Right", "Bottom", "BottomRight"]);
let limited = false;
let clicks = 0;

const bar = document.getElementById("bar");
bar.addEventListener("pointerdown", (event) => {
  // The second press of a double click must not start a drag.
  if (event.button === 0 && event.detail === 1) bindings.startDragging();
});
bar.addEventListener("dblclick", () => bindings.toggleMaximize());

for (const handle of document.querySelectorAll(".edge")) {
  handle.addEventListener("pointerdown", (event) => {
    if (event.button !== 0 || handle.hidden) return;
    event.preventDefault();
    bindings.startResizing(handle.dataset.edge);
  });
}

document.getElementById("add").addEventListener("click", () => {
  clicks += 1;
  document.getElementById("clicks").textContent = `Clicks: ${clicks}`;
});

const edges = document.getElementById("edges");
edges.addEventListener("click", () => {
  limited = !limited;
  edges.textContent = limited ? "Edges: right and bottom" : "Edges: all";
  for (const handle of document.querySelectorAll(".edge")) {
    handle.hidden = limited && !LIMITED.has(handle.dataset.edge);
  }
});

const size = document.getElementById("size");
const showSize = () => (size.textContent = `Size: ${innerWidth} x ${innerHeight}`);
addEventListener("resize", showSize);
showSize();
