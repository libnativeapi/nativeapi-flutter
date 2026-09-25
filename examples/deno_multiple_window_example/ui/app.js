// One page for all three windows; the path says which one this is.

const ROLES = ["Primary", "Secondary", "Tertiary"];
const role = ROLES.find((r) => location.pathname === `/${r.toLowerCase()}`) ?? "Primary";
const next = ROLES[ROLES.indexOf(role) + 1];

document.getElementById("title").textContent = `${role} Window`;
document.getElementById("about").textContent = next
  ? `Each window's button opens the next one. The will-show hook places the ${next.toLowerCase()} window before it appears.`
  : "The last of the three. Hide it and open it again from the secondary window: the hook places it again.";

const actions = document.getElementById("actions");
function button(label, onClick) {
  const node = Object.assign(document.createElement("button"), { textContent: label });
  node.addEventListener("click", onClick);
  actions.append(node);
  return node;
}
const openNext = next ? button(`Open ${next} Window`, () => bindings.open(next)) : null;
if (role !== "Primary") button("Hide", () => bindings.hide());

window.__apply = (s) => {
  if (openNext) openNext.textContent = s.open.includes(next) ? `Show ${next} Window` : `Open ${next} Window`;
  document.getElementById("log").replaceChildren(
    ...s.log.slice(-8).map((line) => Object.assign(document.createElement("li"), { textContent: line })),
  );
};
bindings.getState().then(window.__apply);
