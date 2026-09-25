// The controls of the visual effect example. With an effect on, the page paints
// only the panel and leaves the rest of the window bare for the material.

const effects = document.getElementById("effects");
const backdrop = document.getElementById("backdrop");

function render(s) {
  document.getElementById("current").textContent = `Effect: ${s.current}`;
  document.getElementById("note").textContent = s.note;
  document.body.classList.toggle("has-effect", s.current !== "None");
  effects.replaceChildren(...s.effects.map(({ name, supported }) => {
    const chip = document.createElement("button");
    chip.className = "chip";
    chip.textContent = name;
    chip.disabled = !supported;
    chip.classList.toggle("selected", name === s.current);
    chip.addEventListener("click", async () => render(await bindings.apply(name)));
    return chip;
  }));
  backdrop.textContent = s.backdrop ? "Hide backdrop" : "Show backdrop";
  backdrop.classList.toggle("selected", s.backdrop);
}

backdrop.addEventListener("click", async () => render(await bindings.toggleBackdrop()));
bindings.status().then(render);
