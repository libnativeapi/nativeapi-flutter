// One browser window: the tab strip and the active tab's page. Deno sends the
// strip's layout and the page's state; presses and edits go back to it.

const strip = document.getElementById("strip");
const page = document.getElementById("page");
let state = null;
let pageTabId = null;

function el(tag, props = {}, ...children) {
  const node = Object.assign(document.createElement(tag), props);
  node.append(...children.filter((child) => child != null));
  return node;
}

// --- Strip ------------------------------------------------------------------

const tabNodes = new Map();

function tabNode(tab) {
  let node = tabNodes.get(tab.id);
  if (!node) {
    const close = el("button", { className: "tab-close", textContent: "×", title: "Close tab" });
    close.addEventListener("click", () => bindings.closeTab(tab.id));
    node = el("div", { className: "tab" }, el("span", { className: "dot" }), el("span", { className: "title" }), close);
    node.addEventListener("pointerdown", (event) => {
      if (event.button !== 0 || event.target.closest("button")) return;
      event.preventDefault();
      const r = node.getBoundingClientRect();
      bindings.pressTab(tab.id, { x: event.clientX - r.x, y: event.clientY - r.y }, { x: event.clientX, y: event.clientY });
    });
    tabNodes.set(tab.id, node);
  }
  node.querySelector(".dot").style.background = tab.color;
  node.querySelector(".title").textContent = tab.title;
  node.style.left = `${tab.left}px`;
  node.style.width = `${tab.width}px`;
  node.classList.toggle("active", tab.active);
  node.classList.toggle("dragging", tab.dragging);
  return node;
}

const newTab = el("button", { className: "new-tab", textContent: "+", title: "New tab" });
newTab.addEventListener("click", () => bindings.addTab());
const closeWindow = el("button", { className: "close-window", textContent: "×", title: "Close window" });
closeWindow.addEventListener("click", () => bindings.closeWindow());

strip.addEventListener("pointerdown", (event) => {
  // The empty part of the strip moves the window.
  if (event.button !== 0 || event.target !== strip) return;
  bindings.pressStrip({ x: event.clientX, y: event.clientY });
});

function renderStrip(s) {
  const ids = new Set(s.tabs.map((tab) => tab.id));
  for (const [id, node] of tabNodes) {
    if (!ids.has(id)) {
      node.remove();
      tabNodes.delete(id);
    }
  }
  const nodes = s.tabs.map(tabNode);
  newTab.style.left = `${s.newTabLeft}px`;
  strip.replaceChildren(...nodes, newTab, ...(s.closeButton ? [closeWindow] : []));
}

// --- Page -------------------------------------------------------------------

// A stand-in for a web page with state that would be lost if it were rebuilt:
// an edited address, a counter, a scroll position, a timer that keeps running.
let meta = null;
let like = null;

function buildPage(p) {
  const address = el("input", { className: "address", value: p.address, spellcheck: false });
  address.addEventListener("input", () => bindings.savePage(p.id, { address: address.value }));
  like = el("button", { className: "like" });
  like.addEventListener("click", () => bindings.savePage(p.id, { like: true }));
  meta = el("p", { className: "meta" });
  const list = el(
    "div",
    { className: "content" },
    el("h1", { textContent: p.title }),
    meta,
    el("div", { className: "row" }, like, el("span", { className: "hint", textContent: "Drag the tab to reorder, pull it down to tear it off, drop it on another strip to merge." })),
    ...Array.from({ length: 29 }, (_, i) =>
      el("div", {
        className: "paragraph",
        textContent: `${p.title} · paragraph ${i + 1}`,
        style: `background: color-mix(in srgb, ${p.color} ${8 + ((i + 1) % 3) * 5}%, transparent)`,
      })
    ),
  );
  let saving = 0;
  list.addEventListener("scroll", () => {
    clearTimeout(saving);
    saving = setTimeout(() => bindings.savePage(p.id, { scroll: list.scrollTop }), 100);
  });
  page.replaceChildren(el("div", { className: "toolbar" }, el("span", { textContent: "←  ⟳" }), address), list);
  list.scrollTop = p.scroll;
}

function renderPage() {
  const p = state?.page;
  if (!p) return;
  if (p.id !== pageTabId) {
    pageTabId = p.id;
    buildPage(p);
  }
  const seconds = Math.floor((Date.now() - p.openedAt) / 1000);
  meta.textContent = `Page state #${p.id} · open for ${seconds}s · moved between windows ${p.moves}×`;
  like.textContent = `👍 Like (${p.likes})`;
}
setInterval(renderPage, 1000);

window.__apply = (next) => {
  state = next;
  renderStrip(state);
  renderPage();
};
bindings.getState().then(window.__apply);
