// Renders the window's title bar state, as Deno reports it after every change.

const strip = document.getElementById("strip");
const now = document.getElementById("now");
const note = document.getElementById("note");

function render(s) {
  const rows = [
    ["titleBarStyle", s.style],
    ["isContentUnderTitleBar", s.under],
    ["isWindowControlButtonsVisible", s.buttons],
    ["isContentUnderTitleBarSupported()", s.supported],
    ["contentSize", s.size],
  ];
  now.replaceChildren(...rows.flatMap(([key, value]) => {
    const dt = document.createElement("dt");
    const dd = document.createElement("dd");
    dt.textContent = key;
    dd.textContent = String(value);
    return [dt, dd];
  }));
  if (s.note) note.textContent = s.note;
  const selected = {
    normal: s.style === "normal" && !s.under,
    under: s.style === "normal" && s.under,
    hidden: s.style === "hidden",
    showButtons: s.buttons,
    hideButtons: !s.buttons,
  };
  for (const chip of document.querySelectorAll("[data-act]")) {
    chip.classList.toggle("selected", selected[chip.dataset.act]);
  }
  document.querySelector('[data-act="under"]').disabled = !s.supported;
  // Under a transparent title bar the strip runs up behind the window buttons.
  strip.classList.toggle("under-title-bar", s.style === "normal" && s.under);
}

for (const chip of document.querySelectorAll("[data-act]")) {
  chip.addEventListener("click", async () => render(await bindings.act(chip.dataset.act)));
}
document.getElementById("quit").addEventListener("click", () => bindings.quit());
strip.addEventListener("pointerdown", (event) => {
  if (event.button !== 0 || event.target.closest("button") || event.detail > 1) return;
  bindings.dragStrip();
});
strip.addEventListener("dblclick", (event) => {
  if (!event.target.closest("button")) bindings.toggleMaximize();
});

// contentSize changes with the window; keep the panel current.
let pending = 0;
addEventListener("resize", () => {
  clearTimeout(pending);
  pending = setTimeout(async () => render(await bindings.status()), 100);
});
bindings.status().then(render);
