// Shaped window example — twelve silhouettes, clipped by nativeapi, with a
// contour shadow. The deno desktop counterpart of flutter_shaped_window_example.
//
// Two windows: "Window shapes" holds the controls; "Shape preview" is
// transparent and frameless, and nativeapi clips it to the selected polygon
// (Window.setShape) or, where the renderer clips (Linux/Wayland), gives it a
// matching input region (Window.setInputShape). Shape changes, Restore
// rectangle and Toggle size morph over 450 ms: every frame sends the
// interpolated polygon to the window.
//
// Usage (after `npm install` at the repository root):
//   deno task dev

import {
  DisplayManager,
  TitleBarStyle,
  Window,
  WindowShadow,
  WindowShape,
  type Point,
} from "../../bindings/js/lib/index.ts";
import { nativeWindowOf, serve, serverUrl } from "./desktop.ts";
import { interpolateContour, LOOKS, morphContour, type Shape, SHAPES, shapePoints, type Target } from "./shapes.ts";

await serve("./ui/index.html", ["./ui/controls.js", "./ui/art.js", "./ui/preview.js", "./ui/style.css"]);

// ---------------------------------------------------------------------------
// Windows
// ---------------------------------------------------------------------------

const controls = new Deno.BrowserWindow({ title: "Window shapes", width: 480, height: 680 });
const controlsNative = await nativeWindowOf(controls, "Window shapes");
controls.addEventListener("close", () => Deno.exit(0));

// The preview paints nothing outside its artwork, so the webview must be
// transparent — a creation-only option, not in the typings yet.
const preview = new Deno.BrowserWindow({
  title: "Shape preview",
  width: 320,
  height: 320,
  resizable: false,
  transparent: true,
} as Deno.BrowserWindowOptions);
preview.navigate(serverUrl("/preview"));
const previewNative = await nativeWindowOf(preview, "Shape preview");

/** Linux clips in the renderer and only gives the window an input region. */
const usesInputShape = Window.isInputShapeSupported();

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

let shape: Shape = "circle";
let size = 320; // the preview's current edge, animated
let nativeSize = 320; // its window content edge, which stays at the larger end mid-morph
let toSize = 320;
let points: Point[] = morphContour(shape, size);
let rectangleRestored = false;
let count = 0;
let status = "Preparing preview…";
let reducedMotion = false;

const SHADOW_COLORS: Record<string, string> = {
  Black: "#000000",
  Purple: "#6558F5",
  Blue: "#1976D2",
  Rose: "#E74779",
  Green: "#00897B",
};
const SHADOW_PRESETS: Record<string, { opacity: number; blur: number; y: number; color: string }> = {
  Soft: { opacity: 0.3, blur: 18, y: 6, color: "#000000" },
  Float: { opacity: 0.32, blur: 32, y: 14, color: "#000000" },
  Sharp: { opacity: 0.4, blur: 3, y: 5, color: "#000000" },
  Glow: { opacity: 0.55, blur: 28, y: 0, color: "#9864EF" },
};
const DEFAULT_SHADOW = { enabled: true, color: "#000000", opacity: 0.3, blur: 18, x: 0, y: 6 };
let shadow = { ...DEFAULT_SHADOW };
let shadowError: string | null = null;

function selectedPreset(): string {
  if (!shadow.enabled) return "None";
  for (const [name, p] of Object.entries(SHADOW_PRESETS)) {
    if (shadow.opacity === p.opacity && shadow.blur === p.blur && shadow.y === p.y && shadow.x === 0 && shadow.color === p.color) {
      return name;
    }
  }
  return "Custom";
}

const polygonCss = (outline: Point[]) =>
  outline.map((p) => `${p.x.toFixed(2)}px ${p.y.toFixed(2)}px`).join(",");
const THUMBNAILS = Object.fromEntries(SHAPES.map((s) => [s, polygonCss(shapePoints(s, 46))]));

function controlsState() {
  return {
    shapes: SHAPES.map((s) => ({ id: s, thumbnail: THUMBNAILS[s], colors: LOOKS[s].colors })),
    shape,
    look: LOOKS[shape],
    rectangleRestored,
    toSize,
    status,
    shadow,
    shadowError,
    preset: selectedPreset(),
    presets: ["None", ...Object.keys(SHADOW_PRESETS)],
    shadowColors: SHADOW_COLORS,
  };
}

function previewState() {
  return {
    size,
    label: rectangleRestored ? "rectangle" : shape,
    look: LOOKS[shape],
    count,
    // Only the renderer-clipped path draws the outline itself.
    clip: usesInputShape && !rectangleRestored ? polygonCss(points) : null,
  };
}

function push(browser: Deno.BrowserWindow, state: unknown) {
  browser.executeJs(`window.__apply?.(${JSON.stringify(state)})`).catch(() => {
    // Not loaded yet; the page asks for its state once it is.
  });
}
const pushControls = () => push(controls, controlsState());
const pushPreview = () => push(preview, previewState());

// ---------------------------------------------------------------------------
// Shape
// ---------------------------------------------------------------------------

function applyPoints(outline: Point[], report = true): boolean {
  const polygon = WindowShape.create();
  if (!polygon) {
    status = "Could not allocate a shape.";
    return false;
  }
  try {
    for (const point of outline) {
      if (!polygon.addPoint(point)) {
        status = "Invalid polygon.";
        return false;
      }
    }
    const ok = usesInputShape ? previewNative.setInputShape(polygon) : previewNative.setShape(polygon);
    if (ok) {
      points = outline;
      rectangleRestored = false;
    }
    if (report) {
      status = ok
        ? usesInputShape
          ? `${shape}: renderer clip + native input region (${polygon.pointCount} vertices)`
          : `${shape}: native shape active (${polygon.pointCount} vertices)`
        : "Could not apply shape. Keeping the previous contour.";
      console.log(`[shape] ${status}; isShaped=${previewNative.isShaped}; isInputShaped=${previewNative.isInputShaped}`);
      if (!previewNative.isVisible) previewNative.show();
    }
    return ok;
  } finally {
    // The window copied the points and does not keep the builder.
    polygon.dispose();
  }
}

function clearShape() {
  const ok = usesInputShape ? previewNative.setInputShape(null) : previewNative.setShape(null);
  if (ok) rectangleRestored = true;
  status = ok ? "Rectangle restored" : "Could not restore shape";
  console.log(`[shape] ${status}`);
}

function setPreviewContentSize(edge: number) {
  previewNative.setContentSize({ width: edge, height: edge });
  nativeSize = edge;
}

// A morph interpolates between two resampled contours, and between two sizes.
const MORPH_MS = 450;
let morph: { from: Point[]; to: Point[]; fromSize: number; toSize: number; target: Target; start: number; timer?: ReturnType<typeof setInterval> } | null = null;
const easeInOutCubic = (t: number) => (t < 0.5 ? 4 * t * t * t : 1 - (-2 * t + 2) ** 3 / 2);

function stopMorph() {
  if (morph) clearInterval(morph.timer);
  morph = null;
}

function morphFrame(t: number) {
  const current = morph!;
  const nextSize = Math.round(current.fromSize + (current.toSize - current.fromSize) * t);
  // Keep the window at the larger end for the whole morph; resizing it every
  // frame would make the webview relayout on every step.
  const capacity = Math.max(current.fromSize, current.toSize);
  if (nativeSize < capacity) setPreviewContentSize(capacity);
  const outline = interpolateContour(current.from, current.to, t);
  size = nextSize;
  if (!applyPoints(outline, false)) {
    stopMorph();
    pushControls();
    return;
  }
  pushPreview();
  if (t === 1) {
    stopMorph();
    if (nativeSize !== current.toSize) setPreviewContentSize(current.toSize);
    if (current.target === null) clearShape();
    else applyPoints(outline);
    pushControls();
    pushPreview();
  }
}

function transitionTo(target: Target, targetSize = toSize) {
  // Retarget from the displayed frame, also when a click interrupts a morph.
  stopMorph();
  toSize = targetSize;
  const from = rectangleRestored ? morphContour(null, size) : points;
  const next: NonNullable<typeof morph> = { from, to: morphContour(target, toSize), fromSize: size, toSize, target, start: performance.now() };
  morph = next;
  rectangleRestored = false;
  if (reducedMotion) {
    morphFrame(1);
    return;
  }
  next.timer = setInterval(() => {
    const t = Math.min(1, (performance.now() - next.start) / MORPH_MS);
    morphFrame(easeInOutCubic(t));
  }, 16);
}

// ---------------------------------------------------------------------------
// Shadow
// ---------------------------------------------------------------------------

function hexToRgb(hex: string) {
  const n = parseInt(hex.slice(1), 16);
  return { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255 };
}

function applyShadow(): boolean {
  const native = WindowShadow.create();
  shadowError = null;
  try {
    if (!native) {
      shadowError = "Could not configure the preview shadow.";
    } else {
      native.setColor({ ...hexToRgb(shadow.color), a: Math.round(shadow.opacity * 255) });
      const valid = native.setBlurRadius(shadow.blur) && native.setOffset({ x: shadow.x, y: shadow.y });
      if (!valid || !previewNative.setCustomShadow(native)) {
        shadowError = "Could not apply the shadow parameters.";
      }
    }
  } finally {
    native?.dispose();
  }
  return shadowError === null;
}

let shadowAnimation: ReturnType<typeof setInterval> | undefined;
function stopShadowAnimation() {
  clearInterval(shadowAnimation);
  shadowAnimation = undefined;
}

/** Presets fade in over 220 ms; None fades the shadow out, then turns it off. */
function selectPreset(name: string) {
  stopShadowAnimation();
  if (name === "None" && !shadow.enabled) return;
  const from = { ...shadow, opacity: shadow.enabled ? shadow.opacity : 0 };
  const fadeOut = name === "None";
  const preset = SHADOW_PRESETS[name];
  const to = fadeOut
    ? { ...shadow, opacity: 0 }
    : { ...shadow, enabled: true, opacity: preset.opacity, blur: preset.blur, x: 0, y: preset.y, color: preset.color };
  if (!shadow.enabled && !fadeOut) {
    shadow = { ...shadow, enabled: true, opacity: 0 };
    applyShadow();
    previewNative.setHasShadow(true);
  }
  const fromRgb = hexToRgb(from.color);
  const toRgb = hexToRgb(to.color);
  const start = performance.now();
  const step = () => {
    const raw = reducedMotion ? 1 : Math.min(1, (performance.now() - start) / 220);
    const t = raw < 0.5 ? 2 * raw * raw : 1 - (-2 * raw + 2) ** 2 / 2;
    const mix = (a: number, b: number) => a + (b - a) * t;
    const channel = (k: "r" | "g" | "b") => Math.round(mix(fromRgb[k], toRgb[k])).toString(16).padStart(2, "0");
    shadow = raw === 1
      ? { ...to }
      : {
        ...shadow,
        opacity: mix(from.opacity, to.opacity),
        blur: mix(from.blur, to.blur),
        x: mix(from.x, to.x),
        y: mix(from.y, to.y),
        color: `#${channel("r")}${channel("g")}${channel("b")}`.toUpperCase(),
      };
    applyShadow();
    if (raw === 1) {
      stopShadowAnimation();
      if (fadeOut) {
        shadow = { ...shadow, enabled: false };
        previewNative.setHasShadow(false);
      }
    }
    pushControls();
  };
  if (reducedMotion) step();
  else shadowAnimation = setInterval(step, 16);
}

// ---------------------------------------------------------------------------
// Setup
// ---------------------------------------------------------------------------

previewNative.setTitleBarStyle(TitleBarStyle.Hidden);
previewNative.setBackgroundColor({ r: 0, g: 0, b: 0, a: 0 });
previewNative.setHasShadow(shadow.enabled);
applyShadow();
previewNative.setResizable(false);
// Where independent input shapes exist (Wayland), absolute positions are
// ignored: keep the preview above its controller instead.
if (usesInputShape) previewNative.setParentWindow(controlsNative);
setPreviewContentSize(size);
const area = DisplayManager.getPrimary()?.workArea;
if (area) {
  controlsNative.setPosition({ x: area.x + 60, y: area.y + 100 });
  previewNative.setPosition({ x: area.x + 590, y: area.y + 150 });
}
applyPoints(points);

// ---------------------------------------------------------------------------
// Bindings
// ---------------------------------------------------------------------------

controls.bind("getState", async (reduced: boolean) => {
  reducedMotion = Boolean(reduced);
  return controlsState();
});
controls.bind("selectShape", async (next: Shape) => {
  if (!SHAPES.includes(next)) return;
  shape = next;
  transitionTo(next);
  pushControls();
  pushPreview();
});
controls.bind("applyShape", async () => transitionTo(shape));
controls.bind("restoreRectangle", async () => transitionTo(null));
controls.bind("toggleSize", async () => {
  // Toggle the destination, not a possibly fractional in-flight size; a
  // restored rectangle stays a rectangle.
  const target = rectangleRestored || morph?.target === null ? null : shape;
  transitionTo(target, toSize === 320 ? 400 : 320);
  pushControls();
});
controls.bind("selectPreset", async (name: string) => selectPreset(name));
controls.bind("toggleShadow", async () => {
  stopShadowAnimation();
  shadow = { ...shadow, enabled: !shadow.enabled };
  previewNative.setHasShadow(shadow.enabled);
  console.log(`[shadow] hasShadow=${previewNative.hasShadow}`);
  pushControls();
});
controls.bind("changeShadow", async (change: Partial<typeof shadow>) => {
  stopShadowAnimation();
  const next = { ...shadow };
  if (typeof change.color === "string" && Object.values(SHADOW_COLORS).includes(change.color)) next.color = change.color;
  if (typeof change.opacity === "number") next.opacity = Math.min(1, Math.max(0, change.opacity));
  if (typeof change.blur === "number") next.blur = Math.min(64, Math.max(0, change.blur));
  if (typeof change.x === "number") next.x = Math.min(64, Math.max(-64, change.x));
  if (typeof change.y === "number") next.y = Math.min(64, Math.max(-64, change.y));
  shadow = next;
  applyShadow();
  pushControls();
});
controls.bind("resetShadow", async () => {
  stopShadowAnimation();
  shadow = { ...DEFAULT_SHADOW, enabled: shadow.enabled };
  applyShadow();
  pushControls();
});

preview.bind("getState", async () => previewState());
preview.bind("tap", async () => {
  count += 1;
  pushPreview();
});
preview.bind("startDragging", async () => previewNative.startDragging());
