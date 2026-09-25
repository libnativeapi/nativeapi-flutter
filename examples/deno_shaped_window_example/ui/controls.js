// The "Window shapes" window: the gallery, window and size actions, and the
// shadow presets and parameters. Deno owns the state; this only renders it.

import { art } from "./art.js";

const app = document.getElementById("app");
let state = null;
let editingShadow = false;

function el(tag, props = {}, ...children) {
  const node = Object.assign(document.createElement(tag), props);
  node.append(...children.filter((child) => child != null));
  return node;
}

function chip(label, { selected = false, onClick = null } = {}) {
  const button = el("button", { className: "chip", textContent: label, disabled: !onClick });
  button.classList.toggle("selected", selected);
  if (onClick) button.addEventListener("click", onClick);
  return button;
}

function optionRow(label, ...children) {
  return el("div", { className: "option-row" }, el("span", { className: "option-label", textContent: label }), ...children);
}


function gallery() {
  const grid = el("div", { className: "gallery" });
  for (const shape of state.shapes) {
    const selected = !state.rectangleRestored && shape.id === state.shape;
    const thumb = art(shape.colors);
    thumb.classList.add("thumb");
    thumb.style.clipPath = `polygon(evenodd, ${shape.thumbnail})`;
    const card = el("button", { className: "card" }, thumb, el("span", { textContent: shape.id }));
    card.classList.toggle("selected", selected);
    card.addEventListener("click", () => bindings.selectShape(shape.id));
    grid.append(card);
  }
  return grid;
}

function slider(label, key, min, max, step, format) {
  const input = el("input", { type: "range", min, max, step, value: state.shadow[key] });
  input.setAttribute("aria-label", label);
  const value = el("span", { className: "mono value", textContent: format(state.shadow[key]) });
  input.addEventListener("input", () => {
    value.textContent = format(Number(input.value));
    bindings.changeShadow({ [key]: Number(input.value) });
  });
  return el("div", { className: "slider-row" }, el("span", { className: "option-label", textContent: label }), input, value);
}

function shadowControls() {
  const s = state.shadow;
  const px = (v) => `${Math.round(v)} px`;
  return el(
    "div",
    { className: "shadow-controls" },
    optionRow(
      "Shadow",
      chip("On", { selected: s.enabled, onClick: s.enabled ? null : () => bindings.toggleShadow() }),
      chip("Off", { selected: !s.enabled, onClick: s.enabled ? () => bindings.toggleShadow() : null }),
      el("span", { className: "hint", textContent: "Contour shadow" }),
    ),
    optionRow(
      "Color",
      ...Object.entries(state.shadowColors).map(([name, color]) =>
        chip(name, { selected: s.color === color, onClick: () => bindings.changeShadow({ color }) })
      ),
    ),
    slider("Opacity", "opacity", 0, 1, 0.01, (v) => `${Math.round(v * 100)}%`),
    slider("Blur radius", "blur", 0, 64, 1, px),
    slider("Horizontal", "x", -64, 64, 1, px),
    slider("Vertical", "y", -64, 64, 1, px),
    optionRow("Defaults", chip("Reset shadow parameters", { onClick: () => bindings.resetShadow() })),
    s.enabled ? null : el("p", { className: "hint", textContent: "Shadow hidden. Changes appear when enabled." }),
    state.shadowError ? el("p", { className: "danger", textContent: state.shadowError }) : null,
  );
}

function render() {
  // A slider being dragged re-renders on every step; keep its focus.
  const focused = document.activeElement?.getAttribute("aria-label");
  const header = el(
    "header",
    { style: `--accent-from:${state.look.colors[0]}` },
    el("strong", { textContent: "Outside the box." }),
    el("span", { textContent: "SHAPE PLAYGROUND" }),
  );
  const title = el(
    "div",
    { className: "section-title" },
    el("span", { textContent: editingShadow ? "CUSTOM SHADOW" : "SHAPE COLLECTION" }),
    editingShadow
      ? chip("Done", { selected: true, onClick: () => ((editingShadow = false), render()) })
      : el("span", { className: "mono", textContent: `${state.shapes.length} silhouettes` }),
  );
  const body = editingShadow ? shadowControls() : gallery();
  const windowRows = editingShadow ? [] : [
    optionRow(
      "Window",
      chip("Apply shape", { onClick: () => bindings.applyShape() }),
      chip("Restore rectangle", { onClick: () => bindings.restoreRectangle() }),
    ),
    optionRow(
      "Size",
      chip("Toggle size", { onClick: () => bindings.toggleSize() }),
      el("span", { className: "mono", textContent: `${state.toSize} × ${state.toSize} · 450 ms` }),
    ),
  ];
  const shadowTitle = el(
    "div",
    { className: "section-title" },
    el("span", { textContent: "SHADOW" }),
    el("span", { className: "mono preset", textContent: state.preset }),
    chip(editingShadow ? "Back to shapes" : "Adjust…", {
      selected: editingShadow,
      onClick: () => ((editingShadow = !editingShadow), render()),
    }),
  );
  const presets = el(
    "div",
    { className: "presets" },
    ...state.presets.map((name) =>
      chip(name, { selected: state.preset === name, onClick: () => bindings.selectPreset(name) })
    ),
  );
  const footer = el("footer", { className: state.shadowError ? "danger" : "mono", textContent: state.shadowError ?? state.status });
  app.replaceChildren(header, title, body, ...windowRows, shadowTitle, presets, footer);
  if (focused) app.querySelector(`[aria-label="${focused}"]`)?.focus();
}

window.__apply = (next) => {
  state = next;
  render();
};
bindings.getState(matchMedia("(prefers-reduced-motion: reduce)").matches).then(window.__apply);
