// Board art: cell tiles, obstacles (rock, frost, vines, corruption), portals,
// conveyor arrows and selection / hint highlights.
import { svg, lin, rad, shadowFilter, glowFilter, sparkle, rand } from './lib.mjs';

const C = 128;
const defs0 = shadowFilter('sh', 4, 3, 0.45) + glowFilter('gl', 5) + glowFilter('gl3', 10);

export const tile = (light) => svg(C, C,
  `<rect x="2" y="2" width="124" height="124" rx="14" fill="url(#t)" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="2"/>`,
  lin('t', light ? [[0, '#9CCBFF', 0.78], [1, '#7DB4F5', 0.78]] : [[0, '#6FA6EE', 0.78], [1, '#5A90DE', 0.78]]));

function rockShape(hard, cracked) {
  const r = rand(hard ? 77 : 31);
  const base = hard ? lin('rk', [[0, '#8C7FA8'], [0.6, '#544A6E'], [1, '#2F2840']]) : lin('rk', [[0, '#C9B79C'], [0.6, '#8E7A5E'], [1, '#5C4C38']]);
  let body = `<g filter="url(#sh)"><path d="M18 78 C12 52 30 22 60 18 C92 14 116 36 112 66 C110 96 88 112 60 110 C36 110 22 98 18 78 Z" fill="url(#rk)" stroke="${hard ? '#1E1830' : '#3E3020'}" stroke-width="3.5"/></g>`;
  body += `<path d="M34 46 C42 32 58 28 72 30" stroke="#FFFFFF" stroke-opacity="0.45" stroke-width="5" stroke-linecap="round" fill="none"/>`;
  for (let i = 0; i < 5; i++) {
    const x = 36 + r() * 56, y = 50 + r() * 44;
    body += `<ellipse cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" rx="${(4 + r() * 5).toFixed(1)}" ry="${(3 + r() * 3).toFixed(1)}" fill="#000000" opacity="0.15"/>`;
  }
  if (hard) {
    // crystal veins + metal band = resistant rock
    body += `<path d="M30 70 L50 62 L64 74 L86 58 L104 66" stroke="#B57BFF" stroke-width="5" fill="none" stroke-linejoin="round"/>` +
      `<path d="M30 70 L50 62 L64 74 L86 58 L104 66" stroke="#F0E0FF" stroke-width="2" fill="none" stroke-linejoin="round"/>` +
      `<path d="${sparkle(86, 40, 7)}" fill="#E8D4FF"/>`;
  }
  if (cracked) {
    body += `<path d="M60 20 L54 44 L66 56 L56 78 L64 96 M66 56 L86 64" stroke="#120C1C" stroke-width="4" fill="none" stroke-linejoin="round" stroke-linecap="round"/>`;
  }
  return svg(C, C, body, defs0 + base);
}
export const rock = () => rockShape(false, false);
export const rockHard = () => rockShape(true, false);
export const rockHardCracked = () => rockShape(true, true);

export function frost(layers) {
  const a = layers > 1 ? 0.62 : 0.42;
  const body = `<rect x="8" y="8" width="112" height="112" rx="20" fill="url(#fr)" stroke="#E6FAFF" stroke-width="4"/>` +
    `<path d="M20 30 L40 20 M20 52 L60 22 M88 108 L108 96 M70 108 L108 80" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" opacity="0.8"/>` +
    (layers > 1 ? `<rect x="16" y="16" width="96" height="96" rx="14" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-dasharray="14 8" opacity="0.8"/>` +
      `<path d="${sparkle(96, 30, 9)}" fill="#FFFFFF"/><path d="${sparkle(30, 98, 7)}" fill="#FFFFFF"/>` : '') +
    `<path d="M100 14 L110 24 L104 30" stroke="#FFFFFF" stroke-width="3" fill="none"/>`;
  return svg(C, C, body, lin('fr', [[0, '#E9FBFF', a], [1, '#7FD3FF', a + 0.1]], 0, 0, 1, 1));
}

export function vine() {
  const leaf = (x, y, rot) => `<path transform="translate(${x} ${y}) rotate(${rot})" d="M0 0 C6 -10 18 -10 22 0 C18 8 6 8 0 0 Z" fill="url(#lv)" stroke="#145226" stroke-width="2"/>`;
  const body = `<g filter="url(#sh)" fill="none" stroke-linecap="round">` +
    `<path d="M6 30 C30 50 40 10 64 30 C88 50 98 14 122 34" stroke="#2E6B2A" stroke-width="10"/>` +
    `<path d="M6 96 C30 76 40 116 64 96 C88 76 98 112 122 92" stroke="#2E6B2A" stroke-width="10"/>` +
    `<path d="M30 6 C50 30 10 40 30 64 C50 88 14 98 34 122" stroke="#3C8A35" stroke-width="9"/>` +
    `<path d="M98 6 C78 30 118 40 98 64 C78 88 114 98 94 122" stroke="#3C8A35" stroke-width="9"/></g>` +
    `<path d="M6 30 C30 50 40 10 64 30 C88 50 98 14 122 34 M6 96 C30 76 40 116 64 96 C88 76 98 112 122 92" stroke="#8BD66E" stroke-width="3" fill="none" opacity="0.7"/>` +
    leaf(60, 30, -30) + leaf(20, 64, 60) + leaf(96, 60, 200) + leaf(62, 98, 20) + leaf(100, 20, 140) +
    `<circle cx="34" cy="34" r="4" fill="#FF9AD5"/><circle cx="92" cy="94" r="4" fill="#FFE27A"/>`;
  return svg(C, C, body, defs0 + lin('lv', [[0, '#9BE58A'], [1, '#3BA64A']]));
}

export function corruption() {
  const r = rand(5);
  let wisps = '';
  for (let i = 0; i < 6; i++) {
    const x = 20 + r() * 88, y = 20 + r() * 88;
    wisps += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(2 + r() * 3).toFixed(1)}" fill="#E070FF" opacity="${(0.5 + r() * 0.5).toFixed(2)}"/>`;
  }
  const body = `<rect x="6" y="6" width="116" height="116" rx="24" fill="url(#co)"/>` +
    `<g filter="url(#gl)"><path d="M24 90 C30 60 50 80 56 50 C62 24 84 40 80 64 C78 84 100 76 104 56" stroke="#B030E0" stroke-width="7" fill="none" opacity="0.8"/></g>` +
    `<path d="M24 90 C30 60 50 80 56 50 C62 24 84 40 80 64 C78 84 100 76 104 56" stroke="#2A0A36" stroke-width="4" fill="none"/>` +
    wisps +
    `<rect x="6" y="6" width="116" height="116" rx="24" fill="none" stroke="#7A1FA8" stroke-width="4" stroke-dasharray="6 6"/>`;
  return svg(C, C, body, defs0 + rad('co', [[0, '#3A0D4F', 0.25], [0.7, '#22062E', 0.62], [1, '#12021A', 0.82]]));
}

export function portal(out) {
  const c1 = out ? '#58E6FF' : '#C77DFF', c2 = out ? '#0A5C8A' : '#4A148C';
  let arms = '';
  for (let i = 0; i < 4; i++) {
    arms += `<path transform="rotate(${i * 90} 64 64)" d="M64 64 C64 40 80 26 100 30" stroke="${c1}" stroke-width="6" fill="none" stroke-linecap="round" opacity="0.9"/>`;
  }
  const body = `<g filter="url(#gl)"><circle cx="64" cy="64" r="50" fill="none" stroke="${c1}" stroke-width="10"/></g>` +
    `<circle cx="64" cy="64" r="48" fill="url(#pt)" stroke="${c1}" stroke-width="5"/>` + arms +
    `<circle cx="64" cy="64" r="12" fill="#FFFFFF" opacity="0.85"/>` +
    `<path d="${out ? 'M64 104 L52 88 L76 88 Z' : 'M64 24 L52 40 L76 40 Z'}" fill="#FFFFFF"/>`;
  return svg(C, C, body, defs0 + rad('pt', [[0, '#FFFFFF', 0.6], [0.5, c1, 0.55], [1, c2, 0.85]]));
}

export function conveyor() {
  const body = `<rect x="4" y="34" width="120" height="60" rx="14" fill="#2B2440" opacity="0.75"/>` +
    `<rect x="4" y="34" width="120" height="60" rx="14" fill="none" stroke="#FFD36A" stroke-width="3" opacity="0.7"/>` +
    `<path d="M24 48 L44 64 L24 80 M56 48 L76 64 L56 80 M88 48 L108 64 L88 80" stroke="#FFD36A" stroke-width="7" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`;
  return svg(C, C, body, '');
}

export const selectRing = () => svg(C, C,
  `<g filter="url(#gl)"><rect x="10" y="10" width="108" height="108" rx="26" fill="none" stroke="#FFD36A" stroke-width="10"/></g>` +
  `<rect x="10" y="10" width="108" height="108" rx="26" fill="none" stroke="#FFF6D6" stroke-width="5"/>`, defs0);

export const hintGlow = () => svg(C, C, `<circle cx="64" cy="64" r="60" fill="url(#hg)"/>`,
  rad('hg', [[0, '#FFFFFF', 0.85], [0.6, '#FFF3C4', 0.4], [1, '#FFF3C4', 0]]));

export const partnerRing = () => svg(C, C,
  `<rect x="12" y="12" width="104" height="104" rx="26" fill="none" stroke="#7FFFD4" stroke-width="6" stroke-dasharray="16 10"/>`, '');

export const aura = () => svg(C, C, `<circle cx="64" cy="64" r="62" fill="url(#au)"/>`,
  rad('au', [[0.45, '#FFFFFF', 0], [0.75, '#FFFFFF', 0.75], [1, '#FFFFFF', 0]]));

export const boardFrame = () => svg(C, C,
  `<rect x="4" y="4" width="120" height="120" rx="26" fill="url(#bf)" stroke="#FFFFFF" stroke-opacity="0.95" stroke-width="5"/>` +
  `<rect x="11" y="11" width="106" height="106" rx="20" fill="none" stroke="#3E6FC8" stroke-opacity="0.6" stroke-width="2"/>`,
  lin('bf', [[0, '#3E78D8', 0.7], [1, '#2A5AB8', 0.75]]));
