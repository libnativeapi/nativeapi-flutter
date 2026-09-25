// Both windows load this page: /toolbar is the pill, / the main window. They
// share one model, which Deno owns and pushes after every change.

const isToolbar = location.pathname === "/toolbar";
document.body.dataset.page = isToolbar ? "toolbar" : "main";
const app = document.getElementById("app");

function el(tag, props = {}, ...children) {
  const node = Object.assign(document.createElement(tag), props);
  node.append(...children.filter((child) => child != null));
  return node;
}

function renderToolbar(m) {
  const swatches = m.swatches.map((color) => {
    const swatch = el("button", { className: "swatch", style: `background:${color}` });
    swatch.classList.toggle("selected", color === m.color);
    swatch.addEventListener("click", () => bindings.pick(color));
    return swatch;
  });
  const stamp = el("button", { className: "stamp", textContent: "✓ Stamp" });
  stamp.addEventListener("click", () => bindings.stamp());
  const pill = el("div", { className: "pill" }, ...swatches, stamp);
  pill.addEventListener("pointerdown", (event) => {
    if (event.button === 0 && !event.target.closest("button")) bindings.dragPill();
  });
  app.replaceChildren(pill);
}

function renderMain(m) {
  const attach = el("button", { textContent: m.attached ? "Detach toolbar" : "Attach toolbar" });
  attach.addEventListener("click", () => bindings.toggleAttached());
  const visible = el("button", { textContent: m.toolbarVisible ? "Hide toolbar" : "Show toolbar" });
  visible.addEventListener("click", () => bindings.toggleToolbar());
  app.replaceChildren(
    el("header", {}, el("h1", { textContent: "Floating toolbar" })),
    el(
      "main",
      {},
      el("p", {
        textContent:
          "The pill above this window is a second window: transparent, frameless, and a child of this one. Move, resize or minimize this window and it comes along.",
      }),
      m.canPlaceWindows ? null : el("p", {
        className: "notice",
        textContent:
          "Wayland: applications cannot place their windows here, so the pill cannot follow this window. It stays above it and shares its state; drag the pill to put it where you want it.",
      }),
      el("div", { className: "row" }, el("div", { className: "sample", style: `background:${m.color}` }), el("h2", { id: "stamps", textContent: `Stamps: ${m.stamps}` })),
      el("div", { className: "row" }, attach, visible),
      el("h3", { textContent: "Log" }),
      el("ol", { className: "log" }, ...m.log.map((line) => el("li", { textContent: line }))),
    ),
  );
}

window.__apply = (m) => (isToolbar ? renderToolbar(m) : renderMain(m));
bindings.getState().then(window.__apply);
