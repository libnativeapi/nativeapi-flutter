// The artwork both pages draw: the shape's gradient with a few soft
// highlights and a dot texture (see .art in style.css).
export function art(colors) {
  const node = document.createElement("div");
  node.className = "art";
  node.style.cssText = `--c0:${colors[0]};--c1:${colors[1]};--c2:${colors[2]}`;
  return node;
}
