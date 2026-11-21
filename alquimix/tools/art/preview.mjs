// Dev helper: renders a contact sheet of SVG generators to out/preview.png
import { render, svg } from './lib.mjs';
import fs from 'node:fs';
export function sheet(items, cell = 128, cols = 8, bg = '#15224E') {
  const rows = Math.ceil(items.length / cols);
  const parts = items.map((s, i) => {
    const b64 = Buffer.from(render(s)).toString('base64');
    return `<image x="${(i % cols) * cell}" y="${Math.floor(i / cols) * cell}" width="${cell}" height="${cell}" href="data:image/png;base64,${b64}"/>`;
  }).join('');
  fs.mkdirSync('out', { recursive: true });
  fs.writeFileSync('out/preview.png', render(svg(cols * cell, rows * cell, `<rect width="100%" height="100%" fill="${bg}"/>` + parts)));
}
