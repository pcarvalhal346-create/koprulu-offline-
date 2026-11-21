// Painted backgrounds (480x854, displayed scaled to cover the screen).
import { svg, lin, rad, glowFilter, sparkle, rand } from './lib.mjs';

export const W = 480, H = 854;
const blur = (id, s) => `<filter id="${id}" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="${s}"/></filter>`;

function stars(r, n, maxY, color = '#FFFFFF') {
  let s = '';
  for (let i = 0; i < n; i++) {
    const x = r() * W, y = r() * maxY, sz = 0.8 + r() * 2.2;
    s += r() < 0.15 ? `<path d="${sparkle(x, y, sz * 3)}" fill="${color}" opacity="${(0.5 + r() * 0.5).toFixed(2)}"/>`
      : `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${sz.toFixed(1)}" fill="${color}" opacity="${(0.3 + r() * 0.6).toFixed(2)}"/>`;
  }
  return s;
}

function hills(r, y, amp, color, seg = 6) {
  let d = `M0 ${H} L0 ${y}`;
  const step = W / seg;
  for (let i = 0; i < seg; i++) {
    const x1 = i * step + step / 2, x2 = (i + 1) * step;
    d += ` Q${x1.toFixed(1)} ${(y - amp * (0.4 + r())).toFixed(1)} ${x2.toFixed(1)} ${(y + (r() - 0.5) * amp * 0.5).toFixed(1)}`;
  }
  return `<path d="${d} L${W} ${H} Z" fill="${color}"/>`;
}

export function menu() {
  const r = rand(11);
  let castle = '';
  const towers = [[150, 520, 34, 150], [200, 470, 40, 200], [250, 440, 46, 230], [300, 480, 38, 190], [345, 530, 30, 140]];
  for (const [x, y, w, h] of towers) {
    castle += `<rect x="${x - w / 2}" y="${y}" width="${w}" height="${h + 200}" fill="#1B1450"/>` +
      `<path d="M${x - w / 2 - 6} ${y} L${x} ${y - w * 1.3} L${x + w / 2 + 6} ${y} Z" fill="#2A1F6B"/>` +
      `<rect x="${x - 5}" y="${y + 30}" width="10" height="16" rx="5" fill="#FFD36A" opacity="0.9"/>`;
  }
  const body = `<rect width="${W}" height="${H}" fill="url(#sky)"/>` + stars(r, 120, 520) +
    `<g filter="url(#b1)" opacity="0.65"><path d="M-40 230 C80 160 200 300 300 200 C380 130 450 190 540 150 L540 230 C450 270 380 210 300 280 C200 370 80 240 -40 310 Z" fill="#58E6FF"/>` +
    `<path d="M-40 300 C100 240 220 360 340 280 C420 230 480 260 540 240 L540 290 C470 320 420 290 340 340 C220 420 100 300 -40 360 Z" fill="#FF75C9" opacity="0.7"/></g>` +
    `<g filter="url(#b2)"><circle cx="370" cy="120" r="46" fill="#FFF3C4" opacity="0.8"/></g><circle cx="370" cy="120" r="34" fill="#FFF8E0"/>` +
    hills(r, 600, 70, '#2A2270') + castle + hills(r, 680, 60, '#1B1450') + hills(r, 760, 40, '#120D3A') +
    `<g filter="url(#b2)">${[...Array(14)].map(() => `<circle cx="${(r() * W).toFixed(0)}" cy="${(560 + r() * 280).toFixed(0)}" r="${(3 + r() * 4).toFixed(1)}" fill="#FFE27A"/>`).join('')}</g>`;
  return svg(W, H, body, lin('sky', [[0, '#0C1238'], [0.45, '#2A1F6B'], [0.8, '#6553D9'], [1, '#B593FF']]) + blur('b1', 18) + blur('b2', 6));
}

export function world1() {
  const r = rand(21);
  let trees = '';
  for (let i = 0; i < 9; i++) {
    const x = r() * W, y = 470 + r() * 260, s = 0.6 + r() * 0.8;
    trees += `<g transform="translate(${x.toFixed(0)} ${y.toFixed(0)}) scale(${s.toFixed(2)})">` +
      `<rect x="-8" y="-10" width="16" height="90" rx="6" fill="#3B2A55"/>` +
      `<circle cx="0" cy="-40" r="56" fill="#1E7A6A"/><circle cx="-30" cy="-20" r="36" fill="#239178"/><circle cx="30" cy="-24" r="38" fill="#2AA585"/>` +
      `<circle cx="-14" cy="-60" r="6" fill="#BFFFE8"/><circle cx="20" cy="-36" r="5" fill="#FFE27A"/><circle cx="-36" cy="-22" r="4" fill="#BFFFE8"/></g>`;
  }
  let crystals = '';
  for (let i = 0; i < 6; i++) {
    const x = r() * W, y = 640 + r() * 180;
    crystals += `<path d="M${x} ${y} L${x + 10} ${y - 34} L${x + 20} ${y}Z" fill="#9FF4FF" opacity="0.85"/><path d="M${x + 12} ${y} L${x + 24} ${y - 22} L${x + 32} ${y}Z" fill="#C9B6FF" opacity="0.8"/>`;
  }
  const body = `<rect width="${W}" height="${H}" fill="url(#sky)"/>` + stars(r, 60, 360) +
    `<g filter="url(#b1)"><circle cx="110" cy="160" r="90" fill="#9FF4FF" opacity="0.35"/></g>` +
    hills(r, 420, 90, '#1D4F63') + hills(r, 500, 70, '#16425A') +
    // ruins
    `<g opacity="0.9"><rect x="320" y="380" width="26" height="120" fill="#4E5E8A"/><rect x="370" y="400" width="26" height="100" fill="#4E5E8A"/><rect x="310" y="372" width="96" height="16" fill="#5E6E9A"/></g>` +
    trees + hills(r, 640, 50, '#13384A') +
    `<path d="M-10 700 C120 660 200 760 300 720 C380 690 440 740 500 720 L500 760 C440 780 380 730 300 770 C200 810 120 710 -10 750 Z" fill="url(#stream)"/>` +
    crystals + hills(r, 790, 30, '#0D2836') +
    `<g filter="url(#b2)">${[...Array(18)].map(() => `<circle cx="${(r() * W).toFixed(0)}" cy="${(300 + r() * 540).toFixed(0)}" r="${(2 + r() * 3).toFixed(1)}" fill="#E8FFB0"/>`).join('')}</g>`;
  return svg(W, H, body, lin('sky', [[0, '#0E2245'], [0.5, '#1F5C7A'], [1, '#51D989']]) +
    lin('stream', [[0, '#58E6FF'], [1, '#2A9BD6']], 0, 0, 1, 0) + blur('b1', 30) + blur('b2', 2.5));
}

export function world2() {
  const r = rand(31);
  const volcano = (x, y, w, h, c) =>
    `<path d="M${x - w} ${y} L${x - w * 0.18} ${y - h} L${x + w * 0.18} ${y - h} L${x + w} ${y} Z" fill="${c}"/>` +
    `<path d="M${x - w * 0.18} ${y - h} C${x - 10} ${y - h + 40} ${x + 14} ${y - h + 70} ${x - 6} ${y - h + 120}" stroke="#FF7A1A" stroke-width="7" fill="none"/>` +
    `<g filter="url(#b1)"><ellipse cx="${x}" cy="${y - h - 10}" rx="${w * 0.3}" ry="30" fill="#FF9A3C" opacity="0.8"/></g>`;
  let gears = '';
  for (let i = 0; i < 3; i++) {
    const x = 60 + i * 170 + r() * 40, y = 640 + r() * 60, rr = 26 + r() * 18;
    let teeth = '';
    for (let k = 0; k < 8; k++) teeth += `<rect x="${x - 6}" y="${y - rr - 10}" width="12" height="16" fill="#6B4A2B" transform="rotate(${k * 45} ${x} ${y})"/>`;
    gears += teeth + `<circle cx="${x}" cy="${y}" r="${rr}" fill="#8A5A2B" stroke="#4A2E10" stroke-width="4"/><circle cx="${x}" cy="${y}" r="${rr * 0.35}" fill="#4A2E10"/>`;
  }
  const body = `<rect width="${W}" height="${H}" fill="url(#sky)"/>` + stars(r, 40, 260, '#FFD36A') +
    `<g filter="url(#b1)">${[...Array(6)].map(() => `<ellipse cx="${(r() * W).toFixed(0)}" cy="${(120 + r() * 200).toFixed(0)}" rx="90" ry="26" fill="#3A1030" opacity="0.6"/>`).join('')}</g>` +
    volcano(140, 520, 200, 250, '#3A1830') + volcano(380, 560, 170, 200, '#2B1028') +
    hills(r, 600, 50, '#24101F') +
    `<path d="M-10 720 C100 690 160 760 260 730 C360 700 420 760 500 740 L500 780 C420 800 360 740 260 770 C160 800 100 730 -10 760 Z" fill="url(#lava)"/>` +
    `<g filter="url(#b2)"><path d="M-10 720 C100 690 160 760 260 730 C360 700 420 760 500 740" stroke="#FFD36A" stroke-width="4" fill="none"/></g>` +
    gears + hills(r, 800, 30, '#180A14') +
    `<g>${[...Array(5)].map(() => { const x = r() * W, y = 780 + r() * 60; return `<path d="M${x} ${y} L${x + 12} ${y - 40} L${x + 24} ${y}Z" fill="#C77DFF" opacity="0.85"/>`; }).join('')}</g>` +
    `<g filter="url(#b2)">${[...Array(22)].map(() => `<circle cx="${(r() * W).toFixed(0)}" cy="${(300 + r() * 540).toFixed(0)}" r="${(1.5 + r() * 2.5).toFixed(1)}" fill="#FFB347"/>`).join('')}</g>`;
  return svg(W, H, body, lin('sky', [[0, '#1A0B2E'], [0.45, '#5A1F4A'], [0.8, '#C2452A'], [1, '#FF9A3C']]) +
    lin('lava', [[0, '#FFE27A'], [0.5, '#FF7A1A'], [1, '#E2361F']], 0, 0, 1, 0) + blur('b1', 16) + blur('b2', 3));
}

export function world3() {
  const r = rand(41);
  const island = (x, y, w, tower) =>
    `<path d="M${x - w} ${y} C${x - w} ${y - 20} ${x + w} ${y - 20} ${x + w} ${y} C${x + w * 0.6} ${y + w * 0.6} ${x + 10} ${y + w * 1.1} ${x} ${y + w * 1.3} C${x - 10} ${y + w * 1.1} ${x - w * 0.6} ${y + w * 0.6} ${x - w} ${y} Z" fill="#3A3A8A"/>` +
    `<path d="M${x - w} ${y} C${x - w} ${y - 20} ${x + w} ${y - 20} ${x + w} ${y} Z" fill="#45C96B"/>` +
    (tower ? `<rect x="${x - 14}" y="${y - 120}" width="28" height="110" fill="#E8E2FF"/><path d="M${x - 22} ${y - 118} L${x} ${y - 170} L${x + 22} ${y - 118} Z" fill="#6553D9"/>` +
      `<circle cx="${x}" cy="${y - 84}" r="7" fill="#FFD36A"/>` : '');
  const bolt = (x, y) => `<g filter="url(#b2)"><path d="M${x} ${y} L${x - 16} ${y + 50} L${x + 4} ${y + 50} L${x - 10} ${y + 110}" stroke="#BFE4FF" stroke-width="6" fill="none"/></g>` +
    `<path d="M${x} ${y} L${x - 16} ${y + 50} L${x + 4} ${y + 50} L${x - 10} ${y + 110}" stroke="#FFFFFF" stroke-width="2.5" fill="none"/>`;
  const cloud = (x, y, s, c) => `<g transform="translate(${x} ${y}) scale(${s})"><path d="M0 40 C-30 40 -34 10 -6 6 C0 -20 40 -24 50 0 C70 -14 100 0 96 24 C120 26 118 50 96 50 L0 50 Z" fill="${c}"/></g>`;
  const body = `<rect width="${W}" height="${H}" fill="url(#sky)"/>` + stars(r, 90, 500) +
    cloud(40, 120, 1.4, '#3E4C8C') + cloud(280, 80, 1.6, '#4E5AA8') + bolt(120, 190) + bolt(360, 160) +
    `<g filter="url(#b1)"><circle cx="240" cy="330" r="70" fill="#FF75C9" opacity="0.45"/></g>` +
    `<circle cx="240" cy="330" r="56" fill="none" stroke="#FF75C9" stroke-width="8" opacity="0.8"/><circle cx="240" cy="330" r="40" fill="none" stroke="#58E6FF" stroke-width="5" opacity="0.8"/>` +
    island(90, 470, 70, true) + island(380, 420, 80, true) + island(250, 620, 60, false) + island(70, 760, 50, false) + island(410, 720, 64, true) +
    cloud(-20, 560, 1.2, '#7A86D8') + cloud(330, 600, 1.0, '#8A96E8') + cloud(160, 800, 1.6, '#9AA6F0') +
    `<g filter="url(#b2)">${[...Array(20)].map(() => `<circle cx="${(r() * W).toFixed(0)}" cy="${(r() * H).toFixed(0)}" r="${(1.5 + r() * 2.5).toFixed(1)}" fill="#BFE4FF"/>`).join('')}</g>`;
  return svg(W, H, body, lin('sky', [[0, '#0A0F3A'], [0.4, '#2A2A8A'], [0.75, '#6553D9'], [1, '#FF75C9']]) + blur('b1', 24) + blur('b2', 3));
}
