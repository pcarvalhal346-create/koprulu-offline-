// Shared helpers for the art generator: SVG rendering, cropping, seeded random.
import { Resvg } from '@resvg/resvg-js';
import { PNG } from 'pngjs';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
export const ROOT = path.resolve(here, '../..');
export const FONTS = [
  path.join(ROOT, 'assets/fonts/Fredoka-SemiBold.ttf'),
  path.join(ROOT, 'assets/fonts/Nunito-ExtraBold.ttf'),
];

export function svg(w, h, body, defs = '') {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">` +
    `<defs>${defs}</defs>${body}</svg>`;
}

export function render(svgText) {
  const r = new Resvg(svgText, {
    font: { fontFiles: FONTS, loadSystemFonts: false, defaultFontFamily: 'Fredoka' },
    shapeRendering: 2, textRendering: 2, imageRendering: 0,
  });
  return r.render().asPng();
}

export function decode(buf) { return PNG.sync.read(buf); }
export function encode(png) { return PNG.sync.write(png, { colorType: 6 }); }

/** Bounding box of pixels with alpha > threshold. */
export function bbox(png, threshold = 2) {
  const { width, height, data } = png;
  let x0 = width, y0 = height, x1 = -1, y1 = -1;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      if (data[(y * width + x) * 4 + 3] > threshold) {
        if (x < x0) x0 = x; if (x > x1) x1 = x;
        if (y < y0) y0 = y; if (y > y1) y1 = y;
      }
    }
  }
  if (x1 < 0) return null;
  return { x0, y0, x1: x1 + 1, y1: y1 + 1 };
}

export function crop(png, b, pad = 2) {
  const x0 = Math.max(0, b.x0 - pad), y0 = Math.max(0, b.y0 - pad);
  const x1 = Math.min(png.width, b.x1 + pad), y1 = Math.min(png.height, b.y1 + pad);
  const out = new PNG({ width: x1 - x0, height: y1 - y0 });
  for (let y = y0; y < y1; y++) {
    png.data.copy(out.data, ((y - y0) * out.width) * 4, (y * png.width + x0) * 4, (y * png.width + x1) * 4);
  }
  return { png: out, x0, y0, x1, y1 };
}

export function write(rel, buf) {
  const p = path.join(ROOT, rel);
  fs.mkdirSync(path.dirname(p), { recursive: true });
  fs.writeFileSync(p, buf);
  return p;
}

/** Deterministic random (mulberry32) so the art is reproducible. */
export function rand(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6D2B79F5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// Common SVG snippets -------------------------------------------------------
export const shadowFilter = (id = 'sh', dy = 4, blur = 3, op = 0.35) =>
  `<filter id="${id}" x="-30%" y="-30%" width="160%" height="160%">` +
  `<feGaussianBlur in="SourceAlpha" stdDeviation="${blur}"/><feOffset dy="${dy}" result="o"/>` +
  `<feComponentTransfer><feFuncA type="linear" slope="${op}"/></feComponentTransfer>` +
  `<feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>`;

export const glowFilter = (id = 'gl', blur = 6) =>
  `<filter id="${id}" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="${blur}"/></filter>`;

export const lin = (id, stops, x1 = 0, y1 = 0, x2 = 0, y2 = 1) =>
  `<linearGradient id="${id}" x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}">` +
  stops.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}" stop-opacity="${a}"/>`).join('') +
  `</linearGradient>`;

export const rad = (id, stops, cx = 0.5, cy = 0.5, r = 0.5, fx = cx, fy = cy) =>
  `<radialGradient id="${id}" cx="${cx}" cy="${cy}" r="${r}" fx="${fx}" fy="${fy}">` +
  stops.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}" stop-opacity="${a}"/>`).join('') +
  `</radialGradient>`;

/** n-point star path centred on (cx, cy). */
export function star(cx, cy, outer, inner, n = 5, rot = -90) {
  const pts = [];
  for (let i = 0; i < n * 2; i++) {
    const r = i % 2 === 0 ? outer : inner;
    const a = (rot + i * 180 / n) * Math.PI / 180;
    pts.push(`${(cx + r * Math.cos(a)).toFixed(2)},${(cy + r * Math.sin(a)).toFixed(2)}`);
  }
  return `M${pts.join('L')}Z`;
}

/** 4-point sparkle path. */
export function sparkle(cx, cy, r, w = 0.22) {
  const i = r * w;
  return `M${cx},${cy - r} Q${cx + i},${cy - i} ${cx + r},${cy} Q${cx + i},${cy + i} ${cx},${cy + r} ` +
    `Q${cx - i},${cy + i} ${cx - r},${cy} Q${cx - i},${cy - i} ${cx},${cy - r}Z`;
}
