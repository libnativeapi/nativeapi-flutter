// The twelve silhouettes, their colours, and the morph between any two of
// them — a port of flutter_shaped_window_example's shape_geometry.dart and
// shape_art.dart, so both examples draw the same outlines.

import type { Point } from "../../bindings/js/lib/index.ts";

export const SHAPES = [
  "circle",
  "star",
  "bubble",
  "heart",
  "flower",
  "hexagon",
  "squircle",
  "blob",
  "burst",
  "droplet",
  "diamond",
  "shield",
] as const;
export type Shape = (typeof SHAPES)[number];

/** Name and gradient (top left → bottom right) of each shape's artwork. */
export const LOOKS: Record<Shape, { name: string; colors: string[] }> = {
  circle: { name: "Aurora", colors: ["#6546F5", "#BF46E9", "#FF8799"] },
  star: { name: "Sunset", colors: ["#EA4564", "#FF843E", "#FFCD70"] },
  bubble: { name: "Ocean", colors: ["#154BBC", "#188BC6", "#64E4CB"] },
  heart: { name: "Berry", colors: ["#7525A3", "#D53788", "#FFA8CB"] },
  flower: { name: "Lime", colors: ["#176655", "#45993B", "#CCE868"] },
  hexagon: { name: "Glacier", colors: ["#3542AD", "#657DED", "#9FD9FF"] },
  squircle: { name: "Honey", colors: ["#B96616", "#EBA92E", "#FFDD86"] },
  blob: { name: "Lagoon", colors: ["#116C70", "#25A99E", "#84EBC7"] },
  burst: { name: "Coral", colors: ["#C32E56", "#F36776", "#FFAE9D"] },
  droplet: { name: "Rain", colors: ["#2340A2", "#467DED", "#90CEFF"] },
  diamond: { name: "Peach", colors: ["#C24D70", "#EF9175", "#FFD5AE"] },
  shield: { name: "Forest", colors: ["#245140", "#438568", "#B2D69A"] },
};

const pt = (x: number, y: number): Point => ({ x, y });
const lerp = (a: Point, b: Point, t: number): Point => pt(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
const range = <T>(count: number, f: (i: number) => T): T[] => Array.from({ length: count }, (_, i) => f(i));

function radial(size: number, count: number, radius: (a: number) => number): Point[] {
  return range(count, (i) => {
    const a = -Math.PI / 2 + (i * Math.PI * 2) / count;
    const r = size * radius(a);
    return pt(size / 2 + r * Math.cos(a), size / 2 + r * Math.sin(a));
  });
}

// Quadratic corner arcs are sampled into the same polygon the window gets, so
// clipping, hit testing and the shadow stay aligned.
function roundCorners(points: Point[]): Point[] {
  const rounded: Point[] = [];
  for (let i = 0; i < points.length; i++) {
    const corner = points[i];
    const entry = lerp(corner, points[(i + points.length - 1) % points.length], 0.2);
    const exit = lerp(corner, points[(i + 1) % points.length], 0.2);
    for (let j = 0; j <= 6; j++) {
      const t = j / 6;
      const a = (1 - t) * (1 - t);
      const b = 2 * (1 - t) * t;
      const c = t * t;
      rounded.push(pt(entry.x * a + corner.x * b + exit.x * c, entry.y * a + corner.y * b + exit.y * c));
    }
  }
  return rounded;
}

/** The outline of `shape` in a `size` × `size` square, content-local pixels. */
export function shapePoints(shape: Shape, size: number): Point[] {
  const c = size / 2;
  let points: Point[];
  switch (shape) {
    case "circle":
      points = range(128, (i) => {
        const a = (i * Math.PI * 2) / 128;
        return pt(c + (c - 4) * Math.cos(a), c + (c - 4) * Math.sin(a));
      });
      break;
    case "star":
      points = range(10, (i) => {
        const a = -Math.PI / 2 + (i * Math.PI) / 5;
        const r = (c - 4) * (i % 2 === 0 ? 1 : 0.6);
        return pt(c + r * Math.cos(a), c + r * Math.sin(a));
      });
      break;
    case "heart":
      points = range(96, (i) => {
        const t = (i * Math.PI * 2) / 96;
        const x = 16 * Math.sin(t) ** 3;
        const y = 13 * Math.cos(t) - 5 * Math.cos(2 * t) - 2 * Math.cos(3 * t) - Math.cos(4 * t);
        return pt(size * (0.5 + x / 36), size * (0.48 - y / 36));
      });
      break;
    case "flower":
      points = radial(size, 96, (a) => 0.39 + 0.075 * Math.cos(6 * (a + Math.PI / 2)));
      break;
    case "hexagon":
      points = radial(size, 6, () => 0.47);
      break;
    case "squircle": {
      const axis = (v: number) => Math.sign(v) * Math.abs(v) ** 0.5;
      points = range(96, (i) => {
        const a = -Math.PI / 2 + (i * Math.PI * 2) / 96;
        return pt(c + size * 0.43 * axis(Math.cos(a)), c + size * 0.43 * axis(Math.sin(a)));
      });
      break;
    }
    case "blob":
      points = radial(size, 96, (a) => 0.39 + 0.045 * Math.sin(3 * a + 1) + 0.025 * Math.cos(5 * a));
      break;
    case "burst":
      points = radial(size, 24, (a) => 0.4 + 0.065 * Math.cos(12 * (a + Math.PI / 2)));
      break;
    case "droplet":
      points = range(96, (i) => {
        const t = (i * Math.PI * 2) / 96;
        return pt(
          size * (0.5 + 0.46 * Math.sin(t) * (0.72 - 0.28 * Math.cos(t))),
          size * (0.5 - 0.46 * Math.cos(t)),
        );
      });
      break;
    case "diamond":
      points = radial(size, 4, () => 0.47);
      break;
    case "shield":
      points = [
        [0.5, 0.07], [0.9, 0.16], [0.85, 0.6], [0.7, 0.8],
        [0.5, 0.95], [0.3, 0.8], [0.15, 0.6], [0.1, 0.16],
      ].map(([x, y]) => pt(size * x, size * y));
      break;
    case "bubble":
      points = [
        [0.12, 0.08], [0.88, 0.08], [0.96, 0.16], [0.96, 0.72], [0.88, 0.8], [0.4, 0.8],
        [0.16, 0.96], [0.21, 0.8], [0.12, 0.8], [0.04, 0.72], [0.04, 0.16],
      ].map(([x, y]) => pt(size * x, size * y));
      break;
  }
  const cornered: Shape[] = ["star", "bubble", "hexagon", "burst", "diamond", "shield"];
  return cornered.includes(shape) ? roundCorners(points) : points;
}

/** Morph targets: a shape, or `null` for the plain rectangle. */
export type Target = Shape | null;

const REFERENCE = 320;
let landmarks: { parameters: number[]; polygons: Map<Target, { points: Point[]; fractions: number[] }> } | null = null;

// Every contour is resampled at the same perimeter landmarks, which include
// every original vertex, so any two can be interpolated point by point without
// twisting. Computed once at a fixed reference size.
function morphLandmarks() {
  if (landmarks) return landmarks;
  const polygons = new Map<Target, Point[]>(SHAPES.map((shape) => [shape, shapePoints(shape, REFERENCE)]));
  polygons.set(null, [pt(REFERENCE / 2, 0), pt(REFERENCE, 0), pt(REFERENCE, REFERENCE), pt(0, REFERENCE), pt(0, 0)]);
  // Give every clockwise contour the same top-centre starting landmark.
  const circle = polygons.get("circle")!;
  polygons.set("circle", [...circle.slice(96), ...circle.slice(0, 96)]);
  const bubble = polygons.get("bubble")!;
  polygons.set("bubble", [pt(REFERENCE / 2, REFERENCE * 0.08), ...bubble.slice(7), ...bubble.slice(0, 7)]);

  const all = new Set<number>(range(128, (i) => i / 128));
  const measured = new Map<Target, { points: Point[]; fractions: number[] }>();
  for (const [shape, points] of polygons) {
    const distances = [0];
    for (let i = 0; i < points.length; i++) {
      const a = points[i];
      const b = points[(i + 1) % points.length];
      distances.push(distances[distances.length - 1] + Math.hypot(b.x - a.x, b.y - a.y));
    }
    const total = distances[distances.length - 1];
    const fractions = distances.map((d) => d / total);
    measured.set(shape, { points, fractions });
    fractions.slice(0, points.length).forEach((f) => all.add(f));
  }
  landmarks = { parameters: [...all].sort((a, b) => a - b), polygons: measured };
  return landmarks;
}

/** The contour of `target` at `extent`, resampled for morphing. */
export function morphContour(target: Target, extent: number): Point[] {
  const { parameters, polygons } = morphLandmarks();
  const { points, fractions } = polygons.get(target)!;
  let edge = 0;
  return parameters.map((t) => {
    while (edge + 1 < points.length && fractions[edge + 1] <= t) edge++;
    const p = lerp(points[edge], points[(edge + 1) % points.length], (t - fractions[edge]) / (fractions[edge + 1] - fractions[edge]));
    // Circle and star keep their absolute 4 px inset; the rest scale fully.
    if (target === "circle" || target === "star") {
      const k = (extent - 8) / (REFERENCE - 8);
      return pt(extent / 2 + (p.x - REFERENCE / 2) * k, extent / 2 + (p.y - REFERENCE / 2) * k);
    }
    return pt(p.x * (extent / REFERENCE), p.y * (extent / REFERENCE));
  });
}

export function interpolateContour(from: Point[], to: Point[], t: number): Point[] {
  return from.map((p, i) => lerp(p, to[i], t));
}
