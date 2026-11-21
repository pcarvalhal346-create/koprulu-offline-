// Lumi, Rainha da Alquimia — original character drawn as separate parts on a
// shared 400x520 canvas. The generator crops every part and writes the offsets
// and joints to data/lumi_rig.lua so the GUI can rebuild and animate her.
import { lin, rad, glowFilter, sparkle, star } from './lib.mjs';

export const CANVAS = { w: 400, h: 520 };

export const DEFS =
  glowFilter('lg', 6) + glowFilter('lg2', 3) +
  `<filter id="lsh" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur in="SourceAlpha" stdDeviation="3"/><feOffset dy="3"/>` +
  `<feComponentTransfer><feFuncA type="linear" slope="0.3"/></feComponentTransfer><feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>` +
  rad('skin', [[0, '#FFF8FC'], [0.7, '#F6E6FF'], [1, '#E2C8FF']], 0.45, 0.4, 0.6) +
  lin('hair', [[0, '#9B6BFF'], [0.55, '#6E4AE0'], [1, '#3F5FD8']], 0, 0, 0.3, 1) +
  lin('hairHi', [[0, '#C7B2FF'], [1, '#7FA8FF']], 0, 0, 1, 1) +
  lin('gold', [[0, '#FFF1A8'], [0.5, '#FFD36A'], [1, '#C98A1E']], 0, 0, 0, 1) +
  lin('dress', [[0, '#FFFFFF'], [0.7, '#F1F7FF'], [1, '#D6E9FF']]) +
  lin('turq', [[0, '#7FF0E6'], [1, '#22A6B8']]) +
  lin('wing', [[0, '#C9F6FF', 0.85], [0.5, '#9FD8FF', 0.55], [1, '#C7A2FF', 0.35]], 0, 0, 1, 1) +
  rad('iris', [[0, '#FFD36A'], [0.45, '#F29A3E'], [0.75, '#9A4FE0'], [1, '#4A1F8A']], 0.5, 0.6, 0.6) +
  rad('gem', [[0, '#FFFFFF'], [0.4, '#8FF4FF'], [1, '#2A9BD6']], 0.4, 0.35, 0.7) +
  rad('starGem', [[0, '#FFFFFF'], [0.5, '#FFB3E6'], [1, '#FF75C9']], 0.45, 0.4, 0.7);

const OUT = '#4A2E8A';

function wing(side) {
  // drawn as the left wing; the right one is mirrored
  const body =
    `<g opacity="0.95"><path d="M184 304 C150 250 96 214 54 226 C34 232 36 262 62 276 C40 284 34 312 60 320 C44 336 54 366 84 362 C112 360 150 340 184 316 Z" fill="url(#wing)" stroke="#E6FAFF" stroke-width="3"/>` +
    `<path d="M182 308 C140 278 98 256 64 254 M182 312 C136 306 100 304 70 300 M182 314 C140 330 110 342 86 346" stroke="#FFFFFF" stroke-width="2.5" fill="none" opacity="0.8"/>` +
    `<path d="${sparkle(78, 246, 7)}" fill="#FFFFFF"/><path d="${sparkle(90, 340, 5)}" fill="#FFFFFF"/></g>`;
  return side === 'l' ? body : `<g transform="translate(400 0) scale(-1 1)">${body}</g>`;
}

const hairBack =
  `<path d="M110 150 C96 210 96 270 112 318 C120 342 140 348 150 330 C146 300 140 270 142 240 L258 240 C260 270 254 300 250 330 C260 348 280 342 288 318 C304 270 304 210 290 150 C276 96 236 76 200 76 C164 76 124 96 110 150 Z" fill="url(#hair)" stroke="${OUT}" stroke-width="4" stroke-linejoin="round"/>` +
  `<path d="M118 200 C112 240 114 280 126 310 M282 200 C288 240 286 280 274 310" stroke="url(#hairHi)" stroke-width="5" fill="none" stroke-linecap="round" opacity="0.8"/>`;

const body =
  // skirt (bell)
  `<g filter="url(#lsh)"><path d="M168 330 C150 380 128 430 112 464 C150 482 250 482 288 464 C272 430 250 380 232 330 Z" fill="url(#dress)" stroke="${OUT}" stroke-width="4" stroke-linejoin="round"/></g>` +
  `<path d="M186 334 C178 380 170 430 164 474 L190 476 C192 430 196 380 200 334 Z" fill="url(#turq)" opacity="0.85"/>` +
  `<path d="M214 334 C222 380 230 430 236 474 L210 476 C208 430 204 380 200 334 Z" fill="url(#turq)" opacity="0.55"/>` +
  `<path d="M112 464 C150 482 250 482 288 464" stroke="url(#gold)" stroke-width="8" fill="none" stroke-linecap="round"/>` +
  `<g filter="url(#lg2)"><path d="M120 470 C160 486 240 486 280 470" stroke="#9FF4FF" stroke-width="5" fill="none" opacity="0.8"/></g>` +
  `<path d="${star(150, 440, 7, 3)}" fill="#FFD36A"/><path d="${star(250, 440, 7, 3)}" fill="#FFD36A"/><path d="${star(200, 452, 8, 3.5)}" fill="#FFD36A"/>` +
  // bodice
  `<path d="M172 292 C168 312 168 326 166 336 C188 346 212 346 234 336 C232 326 232 312 228 292 C212 284 188 284 172 292 Z" fill="url(#turq)" stroke="${OUT}" stroke-width="4" stroke-linejoin="round"/>` +
  `<path d="M168 334 C190 344 210 344 232 334" stroke="url(#gold)" stroke-width="6" fill="none" stroke-linecap="round"/>` +
  `<path d="${star(200, 312, 10, 4.5)}" fill="url(#gold)" stroke="#9C5A00" stroke-width="1.5"/>` +
  // neck + collar
  `<path d="M190 270 L190 292 L210 292 L210 270 Z" fill="url(#skin)" stroke="${OUT}" stroke-width="3"/>` +
  `<path d="M170 292 C186 304 214 304 230 292" stroke="url(#gold)" stroke-width="7" fill="none" stroke-linecap="round"/>`;

function arm(side) {
  if (side === 'l') {
    return `<path d="M166 302 C150 318 140 340 138 364" stroke="${OUT}" stroke-width="17" stroke-linecap="round" fill="none"/>` +
      `<path d="M166 302 C150 318 140 340 138 364" stroke="#F6E6FF" stroke-width="11" stroke-linecap="round" fill="none"/>` +
      `<circle cx="138" cy="368" r="10" fill="url(#skin)" stroke="${OUT}" stroke-width="3"/>` +
      `<ellipse cx="166" cy="306" rx="18" ry="15" fill="url(#turq)" stroke="${OUT}" stroke-width="3.5"/>`;
  }
  return `<path d="M234 302 C256 318 280 336 300 350" stroke="${OUT}" stroke-width="17" stroke-linecap="round" fill="none"/>` +
    `<path d="M234 302 C256 318 280 336 300 350" stroke="#F6E6FF" stroke-width="11" stroke-linecap="round" fill="none"/>` +
    // scepter (held away from the face)
    `<path d="M310 272 L310 470" stroke="#8A4F00" stroke-width="11" stroke-linecap="round"/>` +
    `<path d="M310 272 L310 470" stroke="url(#gold)" stroke-width="7" stroke-linecap="round"/>` +
    `<circle cx="310" cy="288" r="9" fill="url(#gold)" stroke="#8A4F00" stroke-width="2"/>` +
    `<g filter="url(#lg)"><path d="${star(310, 254, 30, 13)}" fill="#FFB3E6" opacity="0.9"/></g>` +
    `<path d="${star(310, 254, 25, 11)}" fill="url(#starGem)" stroke="#B23A8E" stroke-width="3" stroke-linejoin="round"/>` +
    `<path d="${sparkle(304, 248, 7)}" fill="#FFFFFF"/>` +
    `<circle cx="304" cy="354" r="11" fill="url(#skin)" stroke="${OUT}" stroke-width="3"/>` +
    `<ellipse cx="234" cy="306" rx="18" ry="15" fill="url(#turq)" stroke="${OUT}" stroke-width="3.5"/>`;
}

const head =
  // fae ears
  `<path d="M122 208 C104 196 88 180 80 160 C98 162 116 172 128 188 Z" fill="url(#skin)" stroke="${OUT}" stroke-width="4" stroke-linejoin="round"/>` +
  `<path d="M120 196 C108 188 98 178 94 170 C104 172 114 178 122 186 Z" fill="#FFB3E6" opacity="0.7"/>` +
  `<path d="M278 208 C296 196 312 180 320 160 C302 162 284 172 272 188 Z" fill="url(#skin)" stroke="${OUT}" stroke-width="4" stroke-linejoin="round"/>` +
  `<path d="M280 196 C292 188 302 178 306 170 C296 172 286 178 278 186 Z" fill="#FFB3E6" opacity="0.7"/>` +
  // face
  `<ellipse cx="200" cy="200" rx="86" ry="80" fill="url(#skin)" stroke="${OUT}" stroke-width="4.5"/>` +
  `<ellipse cx="144" cy="246" rx="15" ry="9" fill="#FF9AD5" opacity="0.55"/>` +
  `<ellipse cx="256" cy="246" rx="15" ry="9" fill="#FF9AD5" opacity="0.55"/>` +
  // little glowing gem on the forehead
  `<path d="${star(200, 150, 8, 3.5, 4)}" fill="#9FF4FF" stroke="#2A9BD6" stroke-width="1.5"/>`;

const hairFront =
  `<path d="M114 176 C110 120 150 88 200 88 C250 88 290 120 286 176 C276 160 264 148 252 142 C244 152 232 152 224 138 C216 150 208 152 200 144 C192 152 184 150 176 138 C168 152 156 152 148 142 C136 148 124 160 114 176 Z" fill="url(#hair)" stroke="${OUT}" stroke-width="4" stroke-linejoin="round"/>` +
`<path d="M140 120 C160 104 184 98 206 100" stroke="url(#hairHi)" stroke-width="7" fill="none" stroke-linecap="round"/>` +
  `<path d="M254 112 C266 122 274 134 278 148" stroke="url(#hairHi)" stroke-width="5" fill="none" stroke-linecap="round" opacity="0.8"/>` +
  // side curls
  `<path d="M116 176 C104 206 108 236 124 252 C112 230 114 206 124 186 Z" fill="url(#hair)" stroke="${OUT}" stroke-width="3.5"/>` +
  `<path d="M284 176 C296 206 292 236 276 252 C288 230 286 206 276 186 Z" fill="url(#hair)" stroke="${OUT}" stroke-width="3.5"/>`;

const crown =
  `<path d="M160 104 L166 66 L184 86 L200 56 L216 86 L234 66 L240 104 Z" fill="url(#gold)" stroke="#8A4F00" stroke-width="3.5" stroke-linejoin="round"/>` +
  `<rect x="158" y="98" width="84" height="12" rx="6" fill="url(#gold)" stroke="#8A4F00" stroke-width="3"/>` +
  `<circle cx="166" cy="64" r="5" fill="#FFF6D6"/><circle cx="234" cy="64" r="5" fill="#FFF6D6"/>` +
  `<g filter="url(#lg2)"><path d="M200 70 L210 84 L200 98 L190 84 Z" fill="#9FF4FF"/></g>` +
  `<path d="M200 70 L210 84 L200 98 L190 84 Z" fill="url(#gem)" stroke="#1F6E9A" stroke-width="2"/>`;

// ----------------------------------------------------------------- faces --
const EYE_L = 162, EYE_R = 238, EYE_Y = 208;
function eye(cx, cy, opts = {}) {
  const ry = opts.ry || 27, rx = opts.rx || 23;
  const look = opts.look || [0, 0];
  const irisR = opts.iris || 19;
  return `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="#FFFFFF" stroke="${OUT}" stroke-width="3.5"/>` +
    `<ellipse cx="${cx + look[0]}" cy="${cy + 3 + look[1]}" rx="${irisR * 0.9}" ry="${irisR}" fill="url(#iris)"/>` +
    `<circle cx="${cx + look[0]}" cy="${cy + 5 + look[1]}" r="${irisR * 0.42}" fill="#2A0F4F"/>` +
    `<circle cx="${cx - 7 + look[0]}" cy="${cy - 6 + look[1]}" r="6.5" fill="#FFFFFF"/>` +
    `<circle cx="${cx + 7 + look[0]}" cy="${cy + 11 + look[1]}" r="3" fill="#FFFFFF"/>` +
    `<path d="M${cx - rx + 1} ${cy - ry * 0.45} C${cx - rx * 0.5} ${cy - ry - 2} ${cx + rx * 0.5} ${cy - ry - 2} ${cx + rx - 1} ${cy - ry * 0.45}" stroke="${OUT}" stroke-width="3.5" fill="none" stroke-linecap="round"/>` +
    (opts.brows === false ? '' : `<path d="M${cx - 15} ${cy - ry - 13} C${cx - 8} ${cy - ry - 24} ${cx + 8} ${cy - ry - 24} ${cx + 15} ${cy - ry - 13}" stroke="${OUT}" stroke-width="3.5" fill="none" stroke-linecap="round" opacity="0.75"/>`);
}
const pair = (fn) => fn(EYE_L, -1) + fn(EYE_R, 1);

export const EYES = {
  eyes_open: pair((x) => eye(x, EYE_Y)),
  eyes_closed: pair((x) => `<path d="M${x - 22} ${EYE_Y + 4} C${x - 10} ${EYE_Y + 14} ${x + 10} ${EYE_Y + 14} ${x + 22} ${EYE_Y + 4}" stroke="${OUT}" stroke-width="6" fill="none" stroke-linecap="round"/>`),
  eyes_happy: pair((x) => `<path d="M${x - 22} ${EYE_Y + 8} C${x - 12} ${EYE_Y - 14} ${x + 12} ${EYE_Y - 14} ${x + 22} ${EYE_Y + 8}" stroke="${OUT}" stroke-width="7" fill="none" stroke-linecap="round"/>`),
  eyes_wide: pair((x) => eye(x, EYE_Y - 2, { rx: 26, ry: 31, iris: 15 })),
  eyes_sad: pair((x, sd) => eye(x, EYE_Y + 2, { ry: 24, look: [0, 4], brows: false }) +
    // worried brows: the inner end (towards the nose) is raised
    `<path d="M${x - 16} ${EYE_Y - 30 + (sd < 0 ? 6 : -6)} L${x + 16} ${EYE_Y - 30 + (sd < 0 ? -6 : 6)}" stroke="${OUT}" stroke-width="4" stroke-linecap="round"/>`),
  eyes_think: pair((x) => eye(x, EYE_Y, { look: [6, -8] })),
};

const MY = 258;
export const MOUTHS = {
  mouth_smile: `<path d="M184 ${MY} C192 ${MY + 12} 208 ${MY + 12} 216 ${MY}" stroke="${OUT}" stroke-width="5" fill="none" stroke-linecap="round"/>`,
  mouth_open: `<path d="M182 ${MY - 2} C186 ${MY + 22} 214 ${MY + 22} 218 ${MY - 2} Z" fill="#7A1F5C" stroke="${OUT}" stroke-width="4" stroke-linejoin="round"/>` +
    `<ellipse cx="200" cy="${MY + 11}" rx="9" ry="5" fill="#FF8FB8"/>`,
  mouth_o: `<ellipse cx="200" cy="${MY + 6}" rx="10" ry="12" fill="#7A1F5C" stroke="${OUT}" stroke-width="4"/>`,
  mouth_sad: `<path d="M186 ${MY + 10} C194 ${MY} 206 ${MY} 214 ${MY + 10}" stroke="${OUT}" stroke-width="5" fill="none" stroke-linecap="round"/>`,
  mouth_grin: `<path d="M176 ${MY - 4} C182 ${MY + 26} 218 ${MY + 26} 224 ${MY - 4} Z" fill="#7A1F5C" stroke="${OUT}" stroke-width="4" stroke-linejoin="round"/>` +
    `<path d="M180 ${MY} L220 ${MY}" stroke="#FFFFFF" stroke-width="6"/><ellipse cx="200" cy="${MY + 14}" rx="11" ry="5" fill="#FF8FB8"/>`,
  mouth_small: `<path d="M192 ${MY + 6} L210 ${MY + 3}" stroke="${OUT}" stroke-width="5" stroke-linecap="round"/>`,
};

/** Parts in draw order with their joint (pivot) in canvas coordinates. */
export const PARTS = [
  { id: 'lumi_wing_l', joint: 'wing_l', pivot: [184, 306], body: wing('l') },
  { id: 'lumi_wing_r', joint: 'wing_r', pivot: [216, 306], body: wing('r') },
  { id: 'lumi_hair_back', joint: 'head_back', pivot: [200, 286], body: hairBack },
  { id: 'lumi_body', joint: 'body', pivot: [200, 400], body },
  { id: 'lumi_arm_l', joint: 'arm_l', pivot: [166, 304], body: arm('l') },
  { id: 'lumi_head', joint: 'head', pivot: [200, 286], body: head },
  { id: 'lumi_eyes', joint: 'head', pivot: [200, 286], face: 'eyes', variants: EYES },
  { id: 'lumi_mouth', joint: 'head', pivot: [200, 286], face: 'mouth', variants: MOUTHS },
  { id: 'lumi_hair_front', joint: 'head', pivot: [200, 286], body: hairFront },
  { id: 'lumi_crown', joint: 'head', pivot: [200, 286], body: crown },
  { id: 'lumi_arm_r', joint: 'arm_r', pivot: [234, 304], body: arm('r') },
];

/** Full portrait (all parts) for icons and previews. */
export function portraitBody(eyes = 'eyes_open', mouth = 'mouth_smile') {
  return PARTS.map((p) => p.variants ? p.variants[p.face === 'eyes' ? eyes : mouth] : p.body).join('');
}
