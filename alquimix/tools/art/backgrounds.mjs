// Painted daylight backgrounds (480x854, displayed scaled to cover the screen):
// bright skies, fluffy clouds, rolling hills — a cheerful casual style with
// alchemy-themed scenery of our own.
import { svg, lin, rad, sparkle, rand } from './lib.mjs';

export const W = 480, H = 854;
const blur = (id, s) => `<filter id="${id}" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="${s}"/></filter>`;

function hills(r, y, amp, color, seg = 5, edge = null) {
  let d = `M-10 ${H} L-10 ${y}`;
  const step = (W + 20) / seg;
  let top = '';
  for (let i = 0; i < seg; i++) {
    const x1 = -10 + i * step + step / 2, x2 = -10 + (i + 1) * step;
    const seg_ = ` Q${x1.toFixed(1)} ${(y - amp * (0.5 + r())).toFixed(1)} ${x2.toFixed(1)} ${(y + (r() - 0.5) * amp * 0.4).toFixed(1)}`;
    d += seg_;
    top += seg_;
  }
  const body = `<path d="${d} L${W + 10} ${H} Z" fill="${color}"/>`;
  const rim = edge ? `<path d="M-10 ${y}${top}" stroke="${edge}" stroke-width="5" fill="none" opacity="0.7"/>` : '';
  return body + rim;
}

function cloud(x, y, s, op = 1) {
  return `<g transform="translate(${x} ${y}) scale(${s})" opacity="${op}">` +
    `<path d="M-60 20 C-80 20 -84 -4 -62 -8 C-62 -34 -26 -42 -12 -22 C-2 -50 46 -48 50 -16 C74 -22 92 -2 80 16 C86 30 70 36 60 30 L-50 30 C-58 30 -62 26 -60 20 Z" fill="#FFFFFF"/>` +
    `<path d="M-60 24 L74 24 C70 32 62 34 56 30 L-50 32 Z" fill="#D8ECFF"/></g>`;
}

function tree(x, y, s, c1, c2) {
  return `<g transform="translate(${x} ${y}) scale(${s})">` +
    `<rect x="-7" y="-6" width="14" height="46" rx="6" fill="#8A5A2B"/>` +
    `<circle cx="0" cy="-34" r="40" fill="${c2}"/><circle cx="-22" cy="-20" r="26" fill="${c1}"/><circle cx="22" cy="-22" r="28" fill="${c1}"/>` +
    `<ellipse cx="-12" cy="-52" rx="16" ry="9" fill="#FFFFFF" opacity="0.35"/>` +
    `<circle cx="-10" cy="-30" r="4" fill="#FF75C9"/><circle cx="14" cy="-14" r="4" fill="#FFE066"/></g>`;
}

function flowers(r, n, y0, y1) {
  let s = '';
  const cols = ['#FF75C9', '#FFE066', '#FFFFFF', '#B593FF', '#FF7A3A'];
  for (let i = 0; i < n; i++) {
    const x = r() * W, y = y0 + r() * (y1 - y0);
    s += `<circle cx="${x.toFixed(0)}" cy="${y.toFixed(0)}" r="${(3 + r() * 3).toFixed(1)}" fill="${cols[i % cols.length]}"/>`;
  }
  return s;
}

function path(color, edge) {
  const d = 'M210 854 C200 780 320 760 300 700 C280 640 160 650 180 590 C196 540 280 540 270 490';
  return `<path d="${d}" stroke="${edge}" stroke-width="74" fill="none" stroke-linecap="round"/>` +
    `<path d="${d}" stroke="${color}" stroke-width="62" fill="none" stroke-linecap="round"/>`;
}

export function menu() {
  const r = rand(11);
  // alchemy tower on the hill
  const tower =
    `<g transform="translate(330 470)">` +
    `<rect x="-34" y="-150" width="68" height="160" rx="10" fill="#B9A6FF"/><rect x="-34" y="-150" width="22" height="160" fill="#FFFFFF" opacity="0.25"/>` +
    `<path d="M-48 -146 L0 -230 L48 -146 Z" fill="#8A4FE8"/><path d="M-48 -146 L0 -230 L-10 -146 Z" fill="#FFFFFF" opacity="0.2"/>` +
    `<circle cx="0" cy="-238" r="12" fill="#FFE066"/>` +
    `<rect x="-12" y="-110" width="24" height="34" rx="12" fill="#5A2BB0"/><rect x="-14" y="-40" width="28" height="50" rx="14" fill="#5A2BB0"/>` +
    `<rect x="-90" y="-60" width="56" height="70" rx="8" fill="#9C8AE8"/><path d="M-98 -56 L-62 -110 L-26 -56 Z" fill="#FF75C9"/></g>`;
  // giant potion bottles at the sides (our own decoration)
  const bottle = (x, y, s, c) => `<g transform="translate(${x} ${y}) scale(${s})">` +
    `<path d="M-12 -40 L12 -40 L12 -14 C38 -2 44 34 20 48 L-20 48 C-44 34 -38 -2 -12 -14 Z" fill="${c}" stroke="#FFFFFF" stroke-width="5"/>` +
    `<rect x="-16" y="-50" width="32" height="12" rx="6" fill="#C98A1E"/><ellipse cx="-12" cy="10" rx="7" ry="14" fill="#FFFFFF" opacity="0.55"/></g>`;
  const body = `<rect width="${W}" height="${H}" fill="url(#sky)"/>` +
    `<g filter="url(#b1)"><circle cx="400" cy="90" r="70" fill="#FFF6C8" opacity="0.9"/></g><circle cx="400" cy="90" r="44" fill="#FFF9DC"/>` +
    cloud(90, 120, 1.0) + cloud(360, 220, 0.8) + cloud(170, 330, 0.6, 0.9) +
    hills(r, 520, 60, '#8EDC6A', 4, '#C8F5A0') + tower +
    hills(r, 610, 50, '#6CCB52', 5, '#A6EE84') +
    path('#F7D9A0', '#E0B46E') +
    hills(r, 760, 40, '#4FB848', 5, '#8EDC6A') +
    flowers(r, 40, 600, 840) +
    bottle(50, 700, 1.1, '#FF4FA0') + bottle(440, 760, 1.0, '#3C9CF5') + bottle(420, 640, 0.7, '#45C96B');
  return svg(W, H, body, lin('sky', [[0, '#4FB0FF'], [0.55, '#9ED8FF'], [1, '#D8F2FF']]) + blur('b1', 20));
}

export function world1() {
  const r = rand(21);
  let trees = '';
  for (let i = 0; i < 7; i++) trees += tree(30 + i * 70 + r() * 20, 470 + r() * 40, 0.7 + r() * 0.3, '#5ED46A', '#3BB55A');
  let trees2 = '';
  for (let i = 0; i < 4; i++) trees2 += tree(r() * W, 640 + r() * 120, 0.9 + r() * 0.4, '#6EE07A', '#43BF60');
  const body = `<rect width="${W}" height="${H}" fill="url(#sky)"/>` +
    cloud(100, 110, 1.0) + cloud(370, 180, 0.9) + cloud(230, 300, 0.55, 0.85) +
    hills(r, 420, 70, '#9BE07A', 4, '#CFF7AE') +
    // ruins of an old alchemy temple
    `<g opacity="0.95"><rect x="330" y="350" width="22" height="80" fill="#E6DCC8"/><rect x="380" y="362" width="22" height="68" fill="#E6DCC8"/><rect x="322" y="342" width="90" height="14" rx="4" fill="#F3EAD6"/>` +
    `<path d="${sparkle(366, 320, 12)}" fill="#9FF4FF"/></g>` +
    trees + hills(r, 560, 50, '#7BD45E', 5, '#B0F08E') +
    `<path d="M-10 640 C120 610 200 690 300 660 C380 636 440 680 500 662 L500 700 C440 716 380 676 300 704 C200 732 120 652 -10 684 Z" fill="url(#stream)"/>` +
    `<path d="M-10 646 C120 616 200 696 300 666 C380 642 440 686 500 668" stroke="#FFFFFF" stroke-width="3" fill="none" opacity="0.7"/>` +
    trees2 + hills(r, 790, 30, '#5CC24C', 5, '#8EDC6A') + flowers(r, 50, 560, 850);
  return svg(W, H, body, lin('sky', [[0, '#4FB8FF'], [0.6, '#A8E4FF'], [1, '#E6FAFF']]) + lin('stream', [[0, '#7FE4FF'], [1, '#36A8F0']], 0, 0, 1, 0));
}

export function world2() {
  const r = rand(31);
  const volcano = (x, y, w, h, c, rim) =>
    `<path d="M${x - w} ${y} L${x - w * 0.18} ${y - h} L${x + w * 0.18} ${y - h} L${x + w} ${y} Z" fill="${c}"/>` +
    `<path d="M${x - w * 0.18} ${y - h} L${x - w * 0.05} ${y - h + 30} L${x + w * 0.06} ${y - h + 14} L${x + w * 0.18} ${y - h} Z" fill="#FF7A1A"/>` +
    `<path d="M${x - w * 0.18} ${y - h} C${x - 10} ${y - h + 50} ${x + 14} ${y - h + 80} ${x - 6} ${y - h + 130}" stroke="#FF9A3C" stroke-width="10" fill="none" stroke-linecap="round"/>` +
    `<path d="M${x - w} ${y} L${x - w * 0.18} ${y - h} L${x - w * 0.05} ${y - h}" stroke="${rim}" stroke-width="5" fill="none" opacity="0.6"/>` +
    `<g filter="url(#b1)"><ellipse cx="${x}" cy="${y - h - 16}" rx="${w * 0.3}" ry="26" fill="#FFB347" opacity="0.85"/></g>`;
  let crystals = '';
  for (let i = 0; i < 7; i++) {
    const x = r() * W, y = 700 + r() * 140, s = 0.7 + r() * 0.6;
    crystals += `<g transform="translate(${x.toFixed(0)} ${y.toFixed(0)}) scale(${s.toFixed(2)})"><path d="M0 0 L12 -46 L24 0 Z" fill="#C77DFF"/><path d="M14 0 L28 -30 L38 0 Z" fill="#FF75C9"/><path d="M2 0 L12 -46 L10 0 Z" fill="#FFFFFF" opacity="0.4"/></g>`;
  }
  const body = `<rect width="${W}" height="${H}" fill="url(#sky)"/>` +
    cloud(110, 120, 0.9, 0.9) + cloud(380, 90, 0.7, 0.85) +
    volcano(140, 520, 190, 250, '#B8644A', '#FFC8A0') + volcano(380, 560, 160, 200, '#A0523C', '#FFC8A0') +
    hills(r, 600, 50, '#E0975A', 5, '#FFC890') +
    `<path d="M-10 712 C100 682 160 752 260 722 C360 692 420 752 500 732 L500 772 C420 792 360 732 260 762 C160 792 100 722 -10 752 Z" fill="url(#lava)"/>` +
    `<path d="M-10 712 C100 682 160 752 260 722 C360 692 420 752 500 732" stroke="#FFF3A0" stroke-width="4" fill="none"/>` +
    hills(r, 800, 30, '#C9774A', 5, '#F0A878') + crystals;
  return svg(W, H, body, lin('sky', [[0, '#FF9ABF'], [0.5, '#FFC08A'], [1, '#FFE2A8']]) +
    lin('lava', [[0, '#FFE27A'], [0.5, '#FF7A1A'], [1, '#FF4A2F']], 0, 0, 1, 0) + blur('b1', 14));
}

export function world3() {
  const r = rand(41);
  const island = (x, y, w, tower) =>
    `<path d="M${x - w} ${y} C${x - w} ${y - 18} ${x + w} ${y - 18} ${x + w} ${y} C${x + w * 0.6} ${y + w * 0.6} ${x + 10} ${y + w * 1.1} ${x} ${y + w * 1.3} C${x - 10} ${y + w * 1.1} ${x - w * 0.6} ${y + w * 0.6} ${x - w} ${y} Z" fill="#B58A6A"/>` +
    `<path d="M${x - w} ${y} C${x - w} ${y - 18} ${x + w} ${y - 18} ${x + w} ${y} C${x + w * 0.5} ${y + 10} ${x - w * 0.5} ${y + 10} ${x - w} ${y} Z" fill="#7BD45E"/>` +
    (tower ? `<rect x="${x - 15}" y="${y - 120}" width="30" height="112" rx="6" fill="#FFFFFF"/><path d="M${x - 24} ${y - 118} L${x} ${y - 172} L${x + 24} ${y - 118} Z" fill="#8A4FE8"/>` +
      `<circle cx="${x}" cy="${y - 84}" r="8" fill="#FFE066"/><circle cx="${x}" cy="${y - 178}" r="7" fill="#FFE066"/>` : '');
  const body = `<rect width="${W}" height="${H}" fill="url(#sky)"/>` +
    `<g filter="url(#b1)" opacity="0.6"><path d="M-20 300 C100 220 240 320 360 240 C420 200 470 220 520 200" stroke="#FFFFFF" stroke-width="60" fill="none"/></g>` +
    cloud(90, 100, 1.1) + cloud(360, 150, 0.9) +
    `<g transform="translate(240 330)"><circle r="56" fill="none" stroke="#FF75C9" stroke-width="10" opacity="0.85"/><circle r="40" fill="none" stroke="#58E6FF" stroke-width="6" opacity="0.9"/>` +
    `<path d="${sparkle(0, 0, 18)}" fill="#FFFFFF"/></g>` +
    island(90, 470, 70, true) + island(390, 420, 80, true) + island(250, 620, 60, false) + island(70, 760, 50, false) + island(410, 720, 64, true) +
    cloud(40, 580, 1.1, 0.95) + cloud(350, 640, 0.9, 0.95) + cloud(200, 820, 1.5) +
    [...Array(16)].map(() => `<path d="${sparkle(r() * W, r() * H, 3 + r() * 5)}" fill="#FFFFFF" opacity="0.8"/>`).join('');
  return svg(W, H, body, lin('sky', [[0, '#7FB8FF'], [0.5, '#C6B2FF'], [1, '#FFC6E8']]) + blur('b1', 18));
}
