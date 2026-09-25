// The page shows what Deno reports; the drop target and drag sources are
// native. Cards start a native drag once the pointer moves past a threshold.

const DRAG_THRESHOLD = 4;
const drop = document.getElementById("drop");

function render(s) {
  drop.classList.toggle("hovering", s.hovering);
  document.getElementById("drop-title").textContent = s.hovering ? "Release to drop" : "Drop files or text here";
  document.getElementById("drop-hint").textContent = s.position
    ? `At ${Math.round(s.position.x)}, ${Math.round(s.position.y)}`
    : `Supported: ${s.dropSupported}`;
  document.getElementById("drops").textContent = `Drops: ${s.drops}`;
  const items = s.files.map((path) => {
    const li = document.createElement("li");
    li.innerHTML = "<strong></strong><small></small>";
    li.querySelector("strong").textContent = path.split(/[\\/]/).pop();
    li.querySelector("small").textContent = path;
    return li;
  });
  if (s.droppedText != null) {
    const li = document.createElement("li");
    li.textContent = `Text: ${s.droppedText}`;
    items.push(li);
  }
  document.getElementById("dropped").replaceChildren(...items);
  document.getElementById("note-name").textContent = s.note.split(/[\\/]/).pop();
  document.getElementById("text-value").textContent = s.text;
  document.getElementById("last-drag").textContent = `Last drag: ${s.lastDrag}`;
  document.getElementById("drag-supported").textContent = `Supported: ${s.dragSupported}`;
}

for (const card of document.querySelectorAll(".card")) {
  card.addEventListener("pointerdown", (down) => {
    if (down.button !== 0) return;
    down.preventDefault();
    const move = (event) => {
      if (Math.hypot(event.clientX - down.clientX, event.clientY - down.clientY) < DRAG_THRESHOLD) return;
      stop();
      bindings.dragOut(card.dataset.kind);
    };
    const stop = () => {
      removeEventListener("pointermove", move);
      removeEventListener("pointerup", stop);
    };
    addEventListener("pointermove", move);
    addEventListener("pointerup", stop);
  });
}

// Drop positions arrive in window content coordinates; tell Deno where the
// panel is so it can tell drops on it from drops beside it.
const report = () => {
  const r = drop.getBoundingClientRect();
  bindings.reportPanel({ x: r.x, y: r.y, width: r.width, height: r.height });
};
new ResizeObserver(report).observe(drop);

window.__apply = render;
bindings.getState().then(render);
