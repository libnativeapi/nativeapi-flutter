// The web side of the example. Every window loads this page: the main window
// shows the slots, a floating window shows exactly one panel. State comes from
// Deno (`bindings.getState()` and `window.__apply(state)` pushes); this code
// only renders it and reports what the user does.

const floatingPanel = location.pathname.startsWith("/panel/")
  ? location.pathname.split("/")[2]
  : null;
const app = document.getElementById("app");
let state = null;

// ---------------------------------------------------------------------------
// Panels: built once per page and moved between slots, so focus and caret in
// the notes survive a re-render.
// ---------------------------------------------------------------------------

const panelElements = {};

function element(tag, props = {}, children = []) {
  const node = Object.assign(document.createElement(tag), props);
  for (const child of children) node.append(child);
  return node;
}

function panelElement(id) {
  if (panelElements[id]) return panelElements[id];
  const meta = element("span", { className: "meta" });
  const action = element("button", {
    textContent: floatingPanel ? "Dock" : "Pop out",
    onclick: () => (floatingPanel ? bindings.dock(id) : bindings.popOut(id)),
  });
  const header = element("div", { className: "panel-header" }, [
    element("strong", { textContent: id === "inspector" ? "Inspector" : "Stopwatch" }),
    meta,
    action,
  ]);
  header.addEventListener("pointerdown", (event) => {
    if (event.button !== 0 || event.target.closest("button")) return;
    event.preventDefault();
    bindings.pressHeader(id, { x: event.clientX, y: event.clientY });
  });
  const body = id === "inspector" ? inspectorBody() : stopwatchBody();
  const panel = element("section", { className: "panel" }, [header, body.node]);
  panelElements[id] = { node: panel, update: (s) => {
    meta.textContent = `moved ${s.moves}×`;
    body.update(s);
  } };
  return panelElements[id];
}

function inspectorBody() {
  const notes = element("textarea", { placeholder: "Type something, then tear this panel out." });
  notes.addEventListener("input", () => bindings.setNotes(notes.value));
  const clicks = element("span");
  const node = element("div", { className: "panel-body" }, [
    notes,
    element("div", { className: "row" }, [
      element("button", { textContent: "+1", onclick: () => bindings.click() }),
      clicks,
    ]),
  ]);
  return {
    node,
    update(s) {
      if (document.activeElement !== notes && notes.value !== s.notes) notes.value = s.notes;
      clicks.textContent = `Clicked ${s.clicks} times`;
    },
  };
}

function stopwatchBody() {
  const time = element("div", { className: "time", textContent: "00:00.0" });
  const toggle = element("button", { onclick: () => bindings.toggleStopwatch() });
  const node = element("div", { className: "panel-body" }, [
    time,
    element("div", { className: "row" }, [
      toggle,
      element("button", { textContent: "Reset", onclick: () => bindings.resetStopwatch() }),
    ]),
  ]);
  let watch = null;
  const tick = () => {
    if (watch) {
      const ms = watch.accumulated + (watch.running ? Date.now() - watch.startedAt : 0);
      const minutes = String(Math.floor(ms / 60000)).padStart(2, "0");
      const seconds = String(Math.floor(ms / 1000) % 60).padStart(2, "0");
      time.textContent = `${minutes}:${seconds}.${Math.floor(ms / 100) % 10}`;
    }
    requestAnimationFrame(tick);
  };
  requestAnimationFrame(tick);
  return {
    node,
    update(s) {
      watch = s;
      toggle.textContent = s.running ? "Stop" : "Start";
    },
  };
}

// ---------------------------------------------------------------------------
// Layouts
// ---------------------------------------------------------------------------

let slots = null;

function buildWorkspace() {
  slots = {};
  const children = ["sidebar", "bottom"].map((id) => {
    const slot = element("div", { className: "slot" });
    slot.dataset.slot = id;
    slots[id] = slot;
    return slot;
  });
  const content = element("main", { className: "content" }, [
    element("h1", { textContent: "Workspace" }),
    element("p", {
      textContent:
        "Drag a panel by its header to tear it out into its own window. Drop it on an empty " +
        "slot to dock it again; drop it anywhere else and it keeps floating.",
    }),
    element("p", {
      textContent:
        "Panel state lives in Deno, so notes, counters and the running stopwatch survive every move.",
    }),
  ]);
  app.replaceChildren(element("div", { className: "workspace" }, [...children, content]));

  const report = () => {
    const rects = {};
    for (const [id, slot] of Object.entries(slots)) {
      const r = slot.getBoundingClientRect();
      rects[id] = { x: r.x, y: r.y, width: r.width, height: r.height };
    }
    bindings.reportSlots(rects);
  };
  new ResizeObserver(report).observe(app);
  report();
}

function render() {
  if (!state) return;
  if (floatingPanel) {
    const panel = panelElement(floatingPanel);
    if (!app.contains(panel.node)) {
      app.className = "floating";
      app.replaceChildren(panel.node);
    }
    panel.update(state.panels[floatingPanel]);
    return;
  }
  if (!slots) buildWorkspace();
  for (const [id, slot] of Object.entries(slots)) {
    const docked = state.dock[id];
    slot.classList.toggle("highlight", state.highlight === id);
    if (docked) {
      const panel = panelElement(docked);
      if (panel.node.parentElement !== slot) slot.replaceChildren(panel.node);
      panel.update(state.panels[docked]);
    } else if (!slot.querySelector(".placeholder")) {
      slot.replaceChildren(element("div", { className: "placeholder", textContent: "Drop a panel here" }));
    }
  }
}

window.__apply = (next) => {
  state = next;
  render();
};
bindings.getState().then(window.__apply);
