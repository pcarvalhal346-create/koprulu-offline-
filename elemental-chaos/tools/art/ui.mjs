// Interface art: 9-slice panels and buttons, icons, stars, map nodes, logo,
// dialogue bubble, book cards and the tutorial hand.
import { svg, lin, rad, shadowFilter, glowFilter, sparkle, star } from './lib.mjs';
import { basePiece } from './pieces.mjs';

const d0 = shadowFilter('sh', 4, 3, 0.45) + glowFilter('gl', 5);

export const panel = () => svg(128, 128,
  `<rect x="6" y="6" width="116" height="116" rx="34" fill="url(#p)" stroke="#FFD36A" stroke-width="5"/>` +
  `<rect x="14" y="14" width="100" height="100" rx="28" fill="none" stroke="#FFFFFF" stroke-opacity="0.2" stroke-width="2"/>`,
  lin('p', [[0, '#6553D9'], [1, '#3A2B94']]));

export const panelDark = () => svg(128, 128,
  `<rect x="4" y="4" width="120" height="120" rx="30" fill="#15224E" fill-opacity="0.92" stroke="#B593FF" stroke-width="4"/>`, '');

export const bubble = () => svg(128, 128,
  `<rect x="6" y="6" width="116" height="116" rx="32" fill="url(#bb)" stroke="#6553D9" stroke-width="5"/>`,
  lin('bb', [[0, '#FFFFFF'], [1, '#EEE7FF']]));

export function button(kind) {
  const g = {
    primary: [['#FFE38A'], ['#FFB234'], ['#C46A00']],
    secondary: [['#B9A6FF'], ['#7A63F0'], ['#3A2B94']],
    danger: [['#FFA3C8'], ['#FF5D9E'], ['#A3205B']],
    green: [['#B6FFB0'], ['#45C96B'], ['#1D7A3A']],
  }[kind];
  return svg(128, 128,
    `<rect x="6" y="14" width="116" height="106" rx="34" fill="${g[2][0]}"/>` +
    `<rect x="6" y="6" width="116" height="106" rx="34" fill="url(#b)" stroke="${g[2][0]}" stroke-width="4"/>` +
    `<rect x="18" y="14" width="92" height="34" rx="17" fill="#FFFFFF" opacity="0.35"/>`,
    lin('b', [[0, g[0][0]], [1, g[1][0]]]));
}

export const roundButton = (kind = 'secondary') => {
  const g = kind === 'primary' ? ['#FFE38A', '#FFB234', '#C46A00'] : ['#B9A6FF', '#7A63F0', '#3A2B94'];
  return svg(128, 128,
    `<circle cx="64" cy="70" r="56" fill="${g[2]}"/>` +
    `<circle cx="64" cy="62" r="56" fill="url(#rb)" stroke="${g[2]}" stroke-width="4"/>` +
    `<ellipse cx="64" cy="34" rx="34" ry="16" fill="#FFFFFF" opacity="0.35"/>`,
    lin('rb', [[0, g[0]], [1, g[1]]]));
};

// icons (white, drawn on 96x96) ---------------------------------------------
const W = '#FFFFFF';
const ic = (body) => svg(96, 96, `<g filter="url(#sh)">${body}</g>`, shadowFilter('sh', 2, 1.5, 0.4));
export const icons = {
  pause: () => ic(`<rect x="26" y="20" width="16" height="56" rx="6" fill="${W}"/><rect x="54" y="20" width="16" height="56" rx="6" fill="${W}"/>`),
  play: () => ic(`<path d="M30 18 L78 48 L30 78 Z" fill="${W}" stroke="${W}" stroke-width="6" stroke-linejoin="round"/>`),
  close: () => ic(`<path d="M24 24 L72 72 M72 24 L24 72" stroke="${W}" stroke-width="13" stroke-linecap="round"/>`),
  back: () => ic(`<path d="M58 18 L28 48 L58 78" stroke="${W}" stroke-width="13" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`),
  retry: () => ic(`<path d="M72 48 A24 24 0 1 1 64 30" stroke="${W}" stroke-width="11" fill="none" stroke-linecap="round"/><path d="M56 12 L76 30 L52 40 Z" fill="${W}"/>`),
  map: () => ic(`<path d="M14 24 L36 16 L60 24 L82 16 L82 72 L60 80 L36 72 L14 80 Z" fill="${W}"/><path d="M36 16 L36 72 M60 24 L60 80" stroke="#6553D9" stroke-width="4"/>`),
  gear: () => {
    let teeth = '';
    for (let i = 0; i < 8; i++) teeth += `<rect x="42" y="8" width="12" height="18" rx="3" fill="${W}" transform="rotate(${i * 45} 48 48)"/>`;
    return ic(teeth + `<circle cx="48" cy="48" r="26" fill="${W}"/><circle cx="48" cy="48" r="11" fill="#6553D9"/>`);
  },
  book: () => ic(`<path d="M48 26 C38 18 22 16 12 20 L12 76 C24 72 38 74 48 82 C58 74 72 72 84 76 L84 20 C74 16 58 18 48 26 Z" fill="${W}"/><path d="M48 26 L48 82" stroke="#6553D9" stroke-width="4"/><path d="${sparkle(66, 44, 9)}" fill="#FFD36A"/>`),
  music: () => ic(`<path d="M36 70 L36 24 L76 16 L76 62" stroke="${W}" stroke-width="8" fill="none" stroke-linejoin="round"/><ellipse cx="28" cy="72" rx="13" ry="10" fill="${W}"/><ellipse cx="68" cy="64" rx="13" ry="10" fill="${W}"/>`),
  sound: () => ic(`<path d="M14 38 L30 38 L52 18 L52 78 L30 58 L14 58 Z" fill="${W}"/><path d="M62 34 C70 42 70 54 62 62 M70 24 C84 38 84 58 70 72" stroke="${W}" stroke-width="7" fill="none" stroke-linecap="round"/>`),
  motion: () => ic(`<path d="M14 60 C30 30 50 70 66 40" stroke="${W}" stroke-width="9" fill="none" stroke-linecap="round"/><circle cx="76" cy="34" r="10" fill="${W}"/>`),
  tutorial: () => ic(`<circle cx="48" cy="48" r="34" fill="${W}"/><path d="M38 38 C38 26 58 26 58 38 C58 48 48 48 48 58" stroke="#6553D9" stroke-width="8" fill="none" stroke-linecap="round"/><circle cx="48" cy="70" r="5" fill="#6553D9"/>`),
  lock: () => ic(`<path d="M30 44 L30 32 C30 14 66 14 66 32 L66 44" stroke="${W}" stroke-width="9" fill="none"/><rect x="20" y="42" width="56" height="42" rx="10" fill="${W}"/><circle cx="48" cy="60" r="6" fill="#6553D9"/><rect x="45" y="60" width="6" height="14" fill="#6553D9"/>`),
  check: () => ic(`<path d="M20 50 L40 70 L78 28" stroke="${W}" stroke-width="13" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`),
  moves: () => ic(`<path d="M18 48 L78 48 M60 30 L78 48 L60 66" stroke="${W}" stroke-width="10" fill="none" stroke-linecap="round" stroke-linejoin="round"/><path d="M38 30 L18 48 L38 66" stroke="${W}" stroke-width="10" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`),
  plus: () => ic(`<path d="M48 20 L48 76 M20 48 L76 48" stroke="${W}" stroke-width="13" stroke-linecap="round"/>`),
  arrow: () => ic(`<path d="M48 84 L48 30 M24 46 L48 18 L72 46" stroke="${W}" stroke-width="12" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`),
};

export const starFull = () => svg(96, 96,
  `<g filter="url(#gl)"><path d="${star(48, 50, 42, 19)}" fill="#FFD36A" opacity="0.7"/></g>` +
  `<path d="${star(48, 50, 40, 18)}" fill="url(#sf)" stroke="#B5791A" stroke-width="4" stroke-linejoin="round"/>` +
  `<path d="${star(44, 44, 16, 7)}" fill="#FFFFFF" opacity="0.5"/>`,
  d0 + lin('sf', [[0, '#FFF1A8'], [1, '#FFB234']]));

export const starEmpty = () => svg(96, 96,
  `<path d="${star(48, 50, 40, 18)}" fill="#2A2270" fill-opacity="0.85" stroke="#7A6CC9" stroke-width="4" stroke-linejoin="round"/>`, '');

export function mapNode(state) {
  const s = {
    locked: ['#8D8AA6', '#4B4866', '#2B2940'],
    open: ['#C9B6FF', '#7A63F0', '#3A2B94'],
    done: ['#FFF1A8', '#FFB234', '#9C5A00'],
  }[state];
  return svg(128, 128,
    `<g filter="url(#sh)"><circle cx="64" cy="64" r="52" fill="url(#mn)" stroke="${s[2]}" stroke-width="6"/></g>` +
    `<circle cx="64" cy="64" r="42" fill="none" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="3"/>` +
    `<ellipse cx="56" cy="38" rx="24" ry="11" fill="#FFFFFF" opacity="0.35"/>`,
    d0 + rad('mn', [[0, s[0]], [1, s[1]]], 0.45, 0.35, 0.7));
}

export const nodeGlow = () => svg(128, 128, `<circle cx="64" cy="64" r="62" fill="url(#ng)"/>`,
  rad('ng', [[0.5, '#FFF3C4', 0.95], [0.75, '#FFD36A', 0.5], [1, '#FFD36A', 0]]));

export const pathDot = () => svg(32, 32, `<circle cx="16" cy="16" r="11" fill="#FFF3C4" stroke="#B5791A" stroke-width="3"/>`, '');

export const ribbon = () => svg(256, 96,
  `<path d="M8 30 L40 30 L40 80 L24 70 L8 80 Z M248 30 L216 30 L216 80 L232 70 L248 80 Z" fill="#B5791A"/>` +
  `<rect x="28" y="14" width="200" height="60" rx="14" fill="url(#rbn)" stroke="#8A4F00" stroke-width="4"/>` +
  `<rect x="38" y="20" width="180" height="16" rx="8" fill="#FFFFFF" opacity="0.3"/>`,
  lin('rbn', [[0, '#FFE38A'], [1, '#FF9A3C']]));

export const card = (known) => svg(256, 320,
  `<rect x="6" y="6" width="244" height="308" rx="30" fill="url(#cd)" stroke="${known ? '#FFD36A' : '#5B4FA0'}" stroke-width="6"/>` +
  `<rect x="18" y="18" width="220" height="284" rx="22" fill="none" stroke="#FFFFFF" stroke-opacity="0.2" stroke-width="2"/>` +
  (known ? `<path d="${sparkle(36, 36, 10)}" fill="#FFD36A"/><path d="${sparkle(220, 284, 10)}" fill="#FFD36A"/>` : ''),
  known ? lin('cd', [[0, '#6553D9'], [1, '#2A1F6B']]) : lin('cd', [[0, '#2E2861'], [1, '#191536']]));

export const hand = () => svg(128, 128,
  `<g filter="url(#sh)"><path d="M48 20 C48 12 60 12 60 20 L60 58 L62 46 C62 38 74 38 74 46 L74 60 L76 52 C76 44 88 44 88 52 L88 66 L90 60 C90 52 102 52 102 60 L102 86 C102 104 90 118 70 118 L60 118 C46 118 38 110 32 98 L18 70 C14 62 24 56 30 62 L48 80 Z" fill="#FFFFFF" stroke="#3A2B94" stroke-width="5" stroke-linejoin="round"/></g>`, d0);

export const white = () => svg(16, 16, `<rect width="16" height="16" fill="#FFFFFF"/>`, '');

export const softCircle = () => svg(64, 64, `<circle cx="32" cy="32" r="31" fill="url(#sc)"/>`,
  rad('sc', [[0, '#FFFFFF', 1], [0.55, '#FFFFFF', 0.6], [1, '#FFFFFF', 0]]));

export const roundRect = () => svg(64, 64, `<rect x="0" y="0" width="64" height="64" rx="18" fill="#FFFFFF"/>`, '');

export const goalSlot = () => svg(128, 128,
  `<rect x="4" y="4" width="120" height="120" rx="28" fill="#15224E" fill-opacity="0.75" stroke="#B593FF" stroke-width="3"/>`, '');

export function logo() {
  const pieces = ['fire', 'water', 'earth', 'air'].map((id, i) => {
    const s = basePiece(id).replace(/^<svg[^>]*>/, '').replace(/<\/svg>$/, '');
    const x = [40, 210, 520, 690][i];
    return `<g transform="translate(${x - 40} ${i % 2 ? 12 : 4}) scale(0.62)">${s.replace(/id="(\w+)"/g, `id="$1${i}"`).replace(/url\(#(\w+)\)/g, `url(#$1${i})`)}</g>`;
  }).join('');
  const text = (t, y, size) =>
    `<text x="380" y="${y}" text-anchor="middle" font-family="Fredoka" font-size="${size}" font-weight="600" letter-spacing="2" ` +
    `stroke="#2A1460" stroke-width="22" stroke-linejoin="round" fill="#2A1460">${t}</text>` +
    `<text x="380" y="${y}" text-anchor="middle" font-family="Fredoka" font-size="${size}" font-weight="600" letter-spacing="2" fill="url(#lg)" stroke="#FFF6D6" stroke-width="3">${t}</text>`;
  return svg(760, 330,
    `<g filter="url(#gl)" opacity="0.7"><ellipse cx="380" cy="180" rx="330" ry="110" fill="#B593FF"/></g>` +
    pieces + text('ELEMENTAL', 170, 124) + text('CHAOS', 300, 136) +
    `<path d="${sparkle(668, 210, 22)}" fill="#FFFFFF"/><path d="${sparkle(96, 250, 16)}" fill="#FFF3C4"/>`,
    glowFilter('gl', 26) + lin('lg', [[0, '#FFF6C2'], [0.45, '#FFD36A'], [0.7, '#FF9A3C'], [1, '#FF75C9']]));
}
