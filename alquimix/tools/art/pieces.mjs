// Element pieces (128x128): 4 base elements, their charged states and 10 compounds.
// Every element has its own silhouette so it is recognisable without colour.
import { svg, lin, rad, shadowFilter, glowFilter, sparkle, star } from './lib.mjs';

const S = 128;
const common = shadowFilter('sh', 5, 3, 0.35) + glowFilter('gl', 5) + glowFilter('gl2', 2.5);

// ------------------------------------------------------------------ bodies --
// Glossy "jelly" rendering: saturated radial fill, darker lower half, a large
// specular highlight, a bottom rim light and a soft drop shadow. No heavy
// dark outlines (bright casual style), silhouettes stay unique per element.
function glossy(id, shape, stops, edge, extra = '') {
  const defs =
    `<clipPath id="${id}c"><path d="${shape}"/></clipPath>` +
    rad(`${id}g`, stops, 0.42, 0.38, 0.72) +
    lin(`${id}d`, [[0.45, '#000000', 0], [1, '#000000', 0.28]]) +
    lin(`${id}h`, [[0, '#FFFFFF', 0.95], [1, '#FFFFFF', 0.05]]);
  const body =
    `<g filter="url(#sh)"><path d="${shape}" fill="url(#${id}g)" stroke="${edge}" stroke-width="2.5" stroke-linejoin="round"/></g>` +
    `<g clip-path="url(#${id}c)">` +
    `<rect x="0" y="0" width="128" height="128" fill="url(#${id}d)"/>` +
    extra +
    `<ellipse cx="50" cy="40" rx="26" ry="16" transform="rotate(-25 50 40)" fill="url(#${id}h)"/>` +
    `<path d="M30 92 C44 112 84 114 100 90" stroke="#FFFFFF" stroke-opacity="0.45" stroke-width="5" fill="none" stroke-linecap="round"/>` +
    `</g>` +
    `<circle cx="40" cy="34" r="5" fill="#FFFFFF"/>`;
  return { defs, body };
}

function fireBody() {
  const outer = 'M64 8 C72 30 96 40 98 64 C100 90 86 114 64 118 C42 114 28 90 30 66 C32 50 42 42 46 30 C52 44 56 50 60 52 C58 36 58 22 64 8 Z';
  const core = `<path d="M64 56 C72 68 82 74 82 90 C82 104 74 112 64 112 C54 112 46 104 46 92 C46 78 56 72 58 62 C60 68 62 70 64 72 C63 64 62 60 64 56 Z" fill="#FFE97A" opacity="0.9"/>`;
  return glossy('fi', outer, [[0, '#FFE58A'], [0.45, '#FF7A3A'], [1, '#D8261A']], '#B3261A', core);
}

function waterBody() {
  const drop = 'M64 6 C78 30 104 54 104 80 C104 104 86 120 64 120 C42 120 24 104 24 80 C24 54 50 30 64 6 Z';
  const bubbles = `<circle cx="82" cy="68" r="6" fill="#FFFFFF" opacity="0.7"/><circle cx="74" cy="96" r="3.5" fill="#FFFFFF" opacity="0.6"/>`;
  return glossy('wa', drop, [[0, '#E2FCFF'], [0.45, '#38C8FA'], [1, '#1460D0']], '#1460C0', bubbles);
}

function earthBody() {
  const outer = 'M64 8 L106 32 L106 96 L64 120 L22 96 L22 32 Z';
  const facets =
    `<path d="M64 26 L88 40 L88 86 L64 100 L40 86 L40 40 Z" fill="#8CF7B8" opacity="0.55"/>` +
    `<path d="M64 8 L64 26 M106 32 L88 40 M106 96 L88 86 M64 120 L64 100 M22 96 L40 86 M22 32 L40 40" stroke="#FFFFFF" stroke-opacity="0.45" stroke-width="2.5"/>`;
  return glossy('ea', outer, [[0, '#C8FFDC'], [0.45, '#3BD67F'], [1, '#0E8A47']], '#0B7A3E', facets);
}

function airBody() {
  const orb = 'M64 14 C92 14 114 36 114 64 C114 92 92 114 64 114 C36 114 14 92 14 64 C14 36 36 14 64 14 Z';
  const swirl =
    `<path d="M64 64 m0 -6 a6 6 0 1 1 -6 6 a14 14 0 0 1 14 -14 a22 22 0 0 1 22 22 a30 30 0 0 1 -30 30 a36 36 0 0 1 -34 -26"` +
    ` stroke="#FFFFFF" stroke-width="8" fill="none" stroke-linecap="round" opacity="0.95"/>`;
  return glossy('ai', orb, [[0, '#FFFFFF'], [0.4, '#D2BCFF'], [1, '#7A4FE0']], '#5A36C0', swirl);
}

const BASE = { fire: fireBody, water: waterBody, earth: earthBody, air: airBody };
const CHARGE_COLOR = { fire: '#FFB347', water: '#7FE8FF', earth: '#8CFFB8', air: '#D9C8FF' };

export function basePiece(id) {
  const b = BASE[id]();
  return svg(S, S, b.body, common + b.defs);
}

/** Charged state: same silhouette, energy halo, rune and sparks. */
export function chargedPiece(id) {
  const b = BASE[id]();
  const c = CHARGE_COLOR[id];
  const halo = rad('hal', [[0.55, c, 0], [0.8, c, 0.85], [1, c, 0]]);
  const body = `<circle cx="64" cy="64" r="62" fill="url(#hal)"/>` +
    `<circle cx="64" cy="64" r="57" fill="none" stroke="${c}" stroke-width="3" stroke-dasharray="10 7" opacity="0.9"/>` +
    `<g transform="translate(64 64) scale(0.86) translate(-64 -64)">${b.body}</g>` +
    // golden rune (energy symbol) at the centre
    `<g filter="url(#gl2)"><path d="${star(64, 70, 17, 7, 4, -90)}" fill="#FFFFFF" opacity="0.9"/></g>` +
    `<path d="${star(64, 70, 14, 5.5, 4, -90)}" fill="#FFD36A" stroke="#A66A00" stroke-width="1.5"/>` +
    `<path d="${sparkle(20, 22, 9)}" fill="#FFFFFF"/><path d="${sparkle(108, 30, 7)}" fill="#FFFFFF"/>` +
    `<path d="${sparkle(104, 106, 8)}" fill="#FFFFFF"/>`;
  return svg(S, S, body, common + b.defs + halo);
}

// --------------------------------------------------------------- compounds --
// Compounds sit on a gold-rimmed medallion so they read as "special" pieces.
function medallion(c1, c2) {
  return rad('md', [[0, '#FFFFFF', 0.35], [0.25, c1], [1, c2]], 0.45, 0.35, 0.75) + lin('rim', [[0, '#FFF6C8'], [0.45, '#FFC93C'], [1, '#D07A10']]);
}
function wrap(inner, c1, c2, defs = '') {
  const body = `<g filter="url(#sh)"><circle cx="64" cy="64" r="57" fill="url(#rim)"/></g>` +
    `<circle cx="64" cy="64" r="50" fill="url(#md)"/>` +
    `<circle cx="64" cy="64" r="57" fill="none" stroke="#9C5A00" stroke-width="2"/>` +
    `<path d="M22 50 A44 44 0 0 1 64 13" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" fill="none" opacity="0.8"/>` +
    inner +
    `<ellipse cx="46" cy="34" rx="22" ry="10" transform="rotate(-25 46 34)" fill="#FFFFFF" opacity="0.35"/>`;
  return svg(S, S, body, common + medallion(c1, c2) + defs);
}

const COMPOUNDS = {
  steam: () => wrap(
    `<path d="M40 84 C28 84 26 68 38 66 C36 54 50 48 58 56 C62 44 80 44 82 58 C94 56 100 70 90 78 C94 88 82 94 76 88 C70 94 56 94 52 88 C48 92 40 90 40 84 Z" fill="url(#st1)" stroke="#7FA6C9" stroke-width="2.5"/>` +
    `<path d="M50 50 C46 42 54 36 50 28 M66 46 C62 38 70 32 66 22 M82 50 C78 42 86 36 82 28" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" fill="none" opacity="0.85"/>` +
    `<ellipse cx="54" cy="68" rx="10" ry="5" fill="#FFFFFF" opacity="0.8"/>`,
    '#5B8FD6', '#1D3B78', lin('st1', [[0, '#FFFFFF'], [1, '#C7DEF5']])),
  lava: () => wrap(
    `<path d="M30 78 C26 60 40 40 64 38 C90 36 104 58 98 78 C94 94 76 102 62 100 C44 100 34 92 30 78 Z" fill="#3B1C14" stroke="#1A0B07" stroke-width="2.5"/>` +
    `<path d="M40 70 L52 62 L58 72 L70 58 L76 70 L90 64 M50 86 L62 80 L72 90 L84 82" stroke="url(#lv1)" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>` +
    `<g filter="url(#gl)"><path d="M40 70 L52 62 L58 72 L70 58 L76 70 L90 64" stroke="#FF7A1A" stroke-width="8" fill="none" opacity="0.8"/></g>` +
    `<circle cx="64" cy="30" r="5" fill="#FFB347"/><circle cx="80" cy="26" r="3" fill="#FFD36A"/><circle cx="48" cy="28" r="3.5" fill="#FF7A1A"/>`,
    '#B2421A', '#4A1206', lin('lv1', [[0, '#FFE27A'], [1, '#FF5A1F']], 0, 0, 1, 0)),
  plasma: () => wrap(
    `<g filter="url(#gl)"><circle cx="64" cy="64" r="26" fill="#C77DFF"/></g>` +
    `<circle cx="64" cy="64" r="22" fill="url(#pl1)" stroke="#FFFFFF" stroke-width="2"/>` +
    `<path d="M64 20 L58 44 L68 46 L60 64 M106 62 L84 58 L84 68 L68 62 M64 108 L70 86 L60 84 L66 68 M22 66 L44 70 L44 60 L60 66" stroke="#FFE27A" stroke-width="4" stroke-linejoin="round" stroke-linecap="round" fill="none"/>` +
    `<path d="${sparkle(64, 64, 12)}" fill="#FFFFFF"/>`,
    '#6A2DB8', '#220A4A', rad('pl1', [[0, '#FFFFFF'], [0.5, '#E3B5FF'], [1, '#8A3FE0']])),
  life: () => wrap(
    `<path d="M64 102 C64 86 64 74 64 62" stroke="#2F8F3E" stroke-width="7" stroke-linecap="round"/>` +
    `<path d="M64 70 C50 72 34 64 32 46 C50 44 62 54 64 70 Z" fill="url(#lf1)" stroke="#1E6B2C" stroke-width="2.5"/>` +
    `<path d="M64 62 C76 62 94 52 96 32 C78 30 64 44 64 62 Z" fill="url(#lf1)" stroke="#1E6B2C" stroke-width="2.5"/>` +
    `<path d="M40 50 C48 54 56 60 62 66 M90 38 C82 44 74 50 66 58" stroke="#D6FFD9" stroke-width="2.5" fill="none" opacity="0.8"/>` +
    `<ellipse cx="64" cy="104" rx="22" ry="7" fill="#6B4A2B"/>` +
    `<path d="${sparkle(92, 82, 7)}" fill="#FFFFFF"/><path d="${sparkle(36, 84, 5)}" fill="#E8FFD9"/>`,
    '#7CD67A', '#1F5E2C', lin('lf1', [[0, '#B8FF9C'], [1, '#3BB34A']], 0, 0, 1, 1)),
  ice: () => wrap(
    `<g stroke="url(#ic1)" stroke-width="8" stroke-linecap="round" fill="none">` +
    `<path d="M64 24 L64 104 M29 44 L99 84 M29 84 L99 44"/></g>` +
    `<g stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" fill="none">` +
    `<path d="M64 24 L64 104 M29 44 L99 84 M29 84 L99 44 M56 32 L64 40 L72 32 M56 96 L64 88 L72 96 M36 56 L44 52 L38 44 M92 72 L84 76 L90 84 M36 72 L44 76 L38 84 M92 56 L84 52 L90 44"/></g>` +
    `<path d="${star(64, 64, 12, 6, 6)}" fill="#FFFFFF"/>`,
    '#7FD3FF', '#1A5D9A', lin('ic1', [[0, '#DFF6FF'], [1, '#5FB8F0']])),
  dust: () => wrap(
    `<path d="M34 46 C54 36 84 38 94 48 C80 50 62 52 50 60 C66 58 84 62 88 70 C74 72 60 74 52 82 C62 82 74 86 74 92" stroke="url(#ds1)" stroke-width="9" stroke-linecap="round" fill="none"/>` +
    `<path d="M34 46 C54 36 84 38 94 48 C80 50 62 52 50 60 C66 58 84 62 88 70 C74 72 60 74 52 82" stroke="#FFF4C9" stroke-width="3" stroke-linecap="round" fill="none" opacity="0.8"/>` +
    [[30, 64, 3], [40, 76, 2.5], [96, 60, 3], [100, 80, 2], [84, 98, 3], [44, 96, 2.5], [62, 30, 2.5], [78, 28, 2]].map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="#FFE8A3"/>`).join(''),
    '#C99A3E', '#5C3A10', lin('ds1', [[0, '#FFE8A3'], [1, '#D19A35']], 0, 0, 1, 0)),
  storm: () => wrap(
    `<path d="M34 60 C26 60 24 46 36 44 C36 32 52 28 58 36 C64 24 84 26 86 40 C98 38 104 54 94 60 Z" fill="#3E4C8C" stroke="#1E2754" stroke-width="2.5"/>` +
    `<path d="M40 52 C46 46 56 46 60 50" stroke="#8A9BE8" stroke-width="3" fill="none" stroke-linecap="round"/>` +
    `<g filter="url(#gl)"><path d="M66 58 L52 84 L64 84 L56 108 L80 76 L68 76 L76 58 Z" fill="#9FC3FF"/></g>` +
    `<path d="M66 58 L52 84 L64 84 L56 108 L80 76 L68 76 L76 58 Z" fill="#FFE27A" stroke="#B5791A" stroke-width="2" stroke-linejoin="round"/>` +
    `<path d="M40 70 L34 82 M94 68 L100 82" stroke="#9FC3FF" stroke-width="3" stroke-linecap="round"/>`,
    '#4E66D9', '#141C4D'),
  obsidian: () => wrap(
    `<g filter="url(#gl)"><path d="M64 20 L92 50 L82 104 L46 104 L36 50 Z" fill="#9A4DFF" opacity="0.8"/></g>` +
    `<path d="M64 22 L90 50 L80 102 L48 102 L38 50 Z" fill="url(#ob1)" stroke="#120818" stroke-width="2.5" stroke-linejoin="round"/>` +
    `<path d="M64 22 L64 102 M38 50 L64 62 L90 50 M48 102 L64 62 L80 102" stroke="#B57BFF" stroke-width="1.8" fill="none" opacity="0.7"/>` +
    `<path d="M64 22 L48 50 L56 60 Z" fill="#FFFFFF" opacity="0.35"/>` +
    `<path d="${sparkle(84, 36, 7)}" fill="#E8D4FF"/>`,
    '#5B2A8A', '#12071F', lin('ob1', [[0, '#4B2A6B'], [0.5, '#1E1230'], [1, '#0A0612']], 0, 0, 1, 1)),
  forest: () => wrap(
    `<ellipse cx="64" cy="100" rx="36" ry="8" fill="#3D6B2A"/>` +
    `<path d="M44 98 L44 88 M64 100 L64 86 M84 98 L84 88" stroke="#6B4A2B" stroke-width="5"/>` +
    `<path d="M44 34 L60 64 L52 64 L64 86 L24 86 L36 64 L28 64 Z" fill="url(#fo1)" stroke="#14532A" stroke-width="2.5" stroke-linejoin="round"/>` +
    `<path d="M84 40 L100 66 L94 66 L104 88 L64 88 L74 66 L68 66 Z" fill="url(#fo1)" stroke="#14532A" stroke-width="2.5" stroke-linejoin="round"/>` +
    `<path d="M64 22 L82 54 L74 54 L88 84 L40 84 L54 54 L46 54 Z" fill="url(#fo2)" stroke="#14532A" stroke-width="2.5" stroke-linejoin="round"/>` +
    `<path d="${sparkle(64, 46, 6)}" fill="#FFFDE0"/><circle cx="50" cy="74" r="3" fill="#FFE27A"/><circle cx="80" cy="70" r="3" fill="#FF9AD5"/>`,
    '#4FB86A', '#123F22', lin('fo1', [[0, '#7FE38A'], [1, '#2C8C43']]) + lin('fo2', [[0, '#A6F59A'], [1, '#34A050']])),
  crystal: () => wrap(
    `<g filter="url(#gl)"><path d="M64 18 L90 46 L64 110 L38 46 Z" fill="#FF9AD5" opacity="0.8"/></g>` +
    `<path d="M64 18 L90 46 L64 110 L38 46 Z" fill="url(#cr1)" stroke="#8A2C6B" stroke-width="2.5" stroke-linejoin="round"/>` +
    `<path d="M38 46 L90 46 M64 18 L54 46 L64 110 L74 46 Z" stroke="#FFFFFF" stroke-width="1.8" fill="none" opacity="0.8"/>` +
    `<path d="M64 18 L54 46 L38 46 Z" fill="#FFFFFF" opacity="0.55"/>` +
    `<path d="${sparkle(94, 30, 9)}" fill="#FFFFFF"/><path d="${sparkle(34, 80, 6)}" fill="#FFFFFF"/><path d="${sparkle(92, 86, 5)}" fill="#FFE6F6"/>`,
    '#E05BB0', '#4A0E3A', lin('cr1', [[0, '#FFE6F6'], [0.4, '#FF9AD5'], [1, '#B23A8E']], 0, 0, 1, 1)),
};

export function compoundPiece(id) { return COMPOUNDS[id](); }

export const BASE_IDS = Object.keys(BASE);
export const COMPOUND_IDS = Object.keys(COMPOUNDS);
