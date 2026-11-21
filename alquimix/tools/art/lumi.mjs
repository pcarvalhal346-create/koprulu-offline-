// Lumi, Rei da Alquimia — original character: a young, energetic alchemist king
// (spiky copper hair, long teal alchemist coat, crystal gauntlet, elemental
// staff and a transmutation circle behind him). Drawn as separate parts on a
// shared 400x520 canvas; the generator crops every part and writes offsets and
// joints to data/lumi_rig.lua so the GUI can rebuild and animate him.
// Part ids are kept stable ("wing_l/wing_r" are the two halves of the circle).
import { lin, rad, glowFilter, sparkle, star } from './lib.mjs';

export const CANVAS = { w: 400, h: 520 };

export const DEFS =
  glowFilter('lg', 6) + glowFilter('lg2', 3) +
  `<filter id="lsh" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur in="SourceAlpha" stdDeviation="3"/><feOffset dy="3"/>` +
  `<feComponentTransfer><feFuncA type="linear" slope="0.3"/></feComponentTransfer><feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>` +
  `<clipPath id="halfL"><rect x="0" y="0" width="200" height="520"/></clipPath>` +
  `<clipPath id="halfR"><rect x="200" y="0" width="200" height="520"/></clipPath>` +
  rad('skin', [[0, '#FFF3EA'], [0.7, '#FCE1CF'], [1, '#EFC3A6']], 0.45, 0.4, 0.6) +
  lin('hair', [[0, '#FFC15A'], [0.45, '#FF8A3D'], [1, '#C8481E']], 0, 0, 0.3, 1) +
  lin('hairHi', [[0, '#FFF1A8'], [1, '#FFB347']], 0, 0, 1, 1) +
  lin('gold', [[0, '#FFF1A8'], [0.5, '#FFD36A'], [1, '#C98A1E']], 0, 0, 0, 1) +
  lin('coat', [[0, '#2FB3B8'], [0.55, '#1F7F9A'], [1, '#1B3A6B']]) +
  lin('coatDark', [[0, '#1B5C78'], [1, '#132A4F']]) +
  lin('pants', [[0, '#2A2445'], [1, '#17132B']]) +
  lin('boot', [[0, '#5A3A2A'], [1, '#2E1C14']]) +
  lin('gaunt', [[0, '#E9FBFF'], [0.4, '#7FD3FF'], [1, '#2F6FB8']], 0, 0, 1, 1) +
  rad('iris', [[0, '#FFE08A'], [0.45, '#F29A3E'], [0.8, '#2A8C9A'], [1, '#174A66']], 0.5, 0.6, 0.6) +
  rad('gem', [[0, '#FFFFFF'], [0.4, '#8FF4FF'], [1, '#2A9BD6']], 0.4, 0.35, 0.7);

const OUT = '#3A2448';

// ------------------------------------------------- transmutation circle --
function circleHalf(side) {
  const cx = 200, cy = 292;
  const tri = (r, rot) => {
    const p = [0, 1, 2].map((i) => {
      const a = (rot + i * 120) * Math.PI / 180;
      return `${(cx + r * Math.cos(a)).toFixed(1)},${(cy + r * Math.sin(a)).toFixed(1)}`;
    });
    return `<path d="M${p.join('L')}Z" fill="none" stroke="#9FF4FF" stroke-width="3"/>`;
  };
  const dots = [['#FF623F', -90], ['#36C9F6', 0], ['#51D989', 90], ['#B593FF', 180]].map(([c, a]) => {
    const r = a * Math.PI / 180;
    return `<circle cx="${(cx + 150 * Math.cos(r)).toFixed(1)}" cy="${(cy + 150 * Math.sin(r)).toFixed(1)}" r="11" fill="${c}" stroke="#FFFFFF" stroke-width="3"/>`;
  }).join('');
  let ticks = '';
  for (let i = 0; i < 24; i++) {
    const a = i * 15 * Math.PI / 180;
    ticks += `<path d="M${(cx + 132 * Math.cos(a)).toFixed(1)} ${(cy + 132 * Math.sin(a)).toFixed(1)} L${(cx + 142 * Math.cos(a)).toFixed(1)} ${(cy + 142 * Math.sin(a)).toFixed(1)}" stroke="#FFE8A3" stroke-width="3"/>`;
  }
  const art =
    `<g filter="url(#lg)" opacity="0.65"><circle cx="${cx}" cy="${cy}" r="150" fill="none" stroke="#58E6FF" stroke-width="12"/></g>` +
    `<circle cx="${cx}" cy="${cy}" r="150" fill="none" stroke="#C9F6FF" stroke-width="5"/>` +
    `<circle cx="${cx}" cy="${cy}" r="126" fill="none" stroke="#FFD36A" stroke-width="3" stroke-dasharray="10 6"/>` +
    ticks + tri(118, -90) + tri(118, 90) +
    `<circle cx="${cx}" cy="${cy}" r="58" fill="none" stroke="#9FF4FF" stroke-width="3"/>` + dots;
  return `<g clip-path="url(#half${side === 'l' ? 'L' : 'R'})" opacity="0.9">${art}</g>`;
}

// ------------------------------------------------------------------ hair --
const hairBack =
  `<path d="M116 186 L92 160 L120 150 L98 112 L136 118 L132 80 L166 98 L180 62 L204 90 L230 60 L240 98 L274 80 L268 118 L304 112 L282 150 L310 162 L284 188 ` +
  `C292 220 286 248 270 262 L252 240 L148 240 L130 262 C114 248 108 220 116 186 Z" fill="url(#hair)" stroke="${OUT}" stroke-width="4" stroke-linejoin="round"/>` +
  `<path d="M140 110 L160 100 M246 100 L262 112" stroke="url(#hairHi)" stroke-width="5" stroke-linecap="round"/>`;

// ------------------------------------------------------------------ body --
const body =
  // legs and boots
  `<path d="M178 400 L174 470 L196 470 L198 400 Z M202 400 L204 470 L226 470 L222 400 Z" fill="url(#pants)" stroke="${OUT}" stroke-width="3.5" stroke-linejoin="round"/>` +
  `<path d="M168 468 C168 456 200 456 200 468 L200 488 L160 488 C158 480 162 472 168 468 Z" fill="url(#boot)" stroke="${OUT}" stroke-width="3.5" stroke-linejoin="round"/>` +
  `<path d="M232 468 C232 456 200 456 200 468 L200 488 L240 488 C242 480 238 472 232 468 Z" fill="url(#boot)" stroke="${OUT}" stroke-width="3.5" stroke-linejoin="round"/>` +
  // long coat with tails
  `<g filter="url(#lsh)"><path d="M166 296 C150 340 140 400 118 472 L184 466 L192 380 L208 380 L216 466 L282 472 C260 400 250 340 234 296 C214 286 186 286 166 296 Z" fill="url(#coat)" stroke="${OUT}" stroke-width="4" stroke-linejoin="round"/></g>` +
  `<path d="M118 472 L184 466 M216 466 L282 472" stroke="url(#gold)" stroke-width="6" stroke-linecap="round"/>` +
  `<path d="M150 360 C146 400 136 440 126 466 M250 360 C254 400 264 440 274 466" stroke="#7FF0E6" stroke-width="3" fill="none" opacity="0.6"/>` +
  // inner vest and shirt
  `<path d="M186 300 L200 352 L214 300 Z" fill="#FFFFFF" stroke="${OUT}" stroke-width="3"/>` +
  `<path d="M180 304 L192 380 L208 380 L220 304 L210 336 L200 352 L190 336 Z" fill="#1E1A33" stroke="${OUT}" stroke-width="3" stroke-linejoin="round"/>` +
  // gold trim on the coat opening
  `<path d="M180 302 L190 380 M220 302 L210 380" stroke="url(#gold)" stroke-width="5" stroke-linecap="round"/>` +
  // belt with the four-element buckle
  `<rect x="174" y="372" width="52" height="14" rx="5" fill="#5A3A2A" stroke="${OUT}" stroke-width="3"/>` +
  `<path d="M200 368 L210 379 L200 390 L190 379 Z" fill="url(#gold)" stroke="#8A4F00" stroke-width="2"/>` +
  `<circle cx="200" cy="374" r="2.6" fill="#FF623F"/><circle cx="205" cy="379" r="2.6" fill="#36C9F6"/>` +
  `<circle cx="200" cy="384" r="2.6" fill="#51D989"/><circle cx="195" cy="379" r="2.6" fill="#B593FF"/>` +
  // coat emblem: original elemental circle
  `<circle cx="236" cy="330" r="11" fill="none" stroke="url(#gold)" stroke-width="3"/>` +
  `<path d="${star(236, 330, 8, 3.5, 4)}" fill="#FFD36A"/>` +
  // high collar + neck
  `<path d="M190 268 L190 292 L210 292 L210 268 Z" fill="url(#skin)" stroke="${OUT}" stroke-width="3"/>` +
  `<path d="M164 296 L172 270 L190 288 Z M236 296 L228 270 L210 288 Z" fill="url(#coatDark)" stroke="${OUT}" stroke-width="3.5" stroke-linejoin="round"/>` +
  `<path d="M172 270 L190 288 M228 270 L210 288" stroke="url(#gold)" stroke-width="3"/>`;

function arm(side) {
  if (side === 'l') {
    return `<path d="M168 302 C152 320 144 342 140 362" stroke="${OUT}" stroke-width="24" stroke-linecap="round" fill="none"/>` +
      `<path d="M168 302 C152 320 144 342 140 362" stroke="url(#coat)" stroke-width="17" stroke-linecap="round" fill="none"/>` +
      `<path d="M134 356 L150 362" stroke="url(#gold)" stroke-width="6" stroke-linecap="round"/>` +
      // white glove with a small original circle mark
      `<circle cx="140" cy="374" r="12" fill="#FFFFFF" stroke="${OUT}" stroke-width="3"/>` +
      `<circle cx="140" cy="374" r="5" fill="none" stroke="#2A9BD6" stroke-width="2"/>`;
  }
  return `<path d="M232 302 C254 318 278 334 298 346" stroke="${OUT}" stroke-width="24" stroke-linecap="round" fill="none"/>` +
    `<path d="M232 302 C254 318 278 334 298 346" stroke="url(#coat)" stroke-width="17" stroke-linecap="round" fill="none"/>` +
    // alchemy staff topped with a four-element orb
    `<path d="M310 262 L310 470" stroke="#8A4F00" stroke-width="11" stroke-linecap="round"/>` +
    `<path d="M310 262 L310 470" stroke="url(#gold)" stroke-width="7" stroke-linecap="round"/>` +
    `<path d="M294 270 C300 262 320 262 326 270 L310 280 Z" fill="url(#gold)" stroke="#8A4F00" stroke-width="2"/>` +
    `<g filter="url(#lg)"><circle cx="310" cy="244" r="26" fill="#9FF4FF" opacity="0.8"/></g>` +
    `<path d="M310 224 A20 20 0 0 1 330 244 L310 244 Z" fill="#FF623F"/>` +
    `<path d="M330 244 A20 20 0 0 1 310 264 L310 244 Z" fill="#36C9F6"/>` +
    `<path d="M310 264 A20 20 0 0 1 290 244 L310 244 Z" fill="#51D989"/>` +
    `<path d="M290 244 A20 20 0 0 1 310 224 L310 244 Z" fill="#B593FF"/>` +
    `<circle cx="310" cy="244" r="20" fill="none" stroke="#FFF6D6" stroke-width="3"/>` +
    `<path d="${sparkle(303, 237, 7)}" fill="#FFFFFF"/>` +
    // crystal gauntlet
    `<path d="M282 330 L300 336 L312 356 L300 368 L284 360 L276 344 Z" fill="url(#gaunt)" stroke="${OUT}" stroke-width="3" stroke-linejoin="round"/>` +
    `<path d="M284 340 L298 346 L304 358" stroke="#FFFFFF" stroke-width="2" fill="none" opacity="0.8"/>` +
    `<path d="M280 332 L278 322 M292 334 L292 324" stroke="url(#gold)" stroke-width="4" stroke-linecap="round"/>`;
}

// ------------------------------------------------------------------ head --
const head =
  // small elfin ears (he is a magical being, not a human child)
  `<path d="M124 210 C110 202 100 192 94 178 C108 178 120 186 130 196 Z" fill="url(#skin)" stroke="${OUT}" stroke-width="4" stroke-linejoin="round"/>` +
  `<path d="M276 210 C290 202 300 192 306 178 C292 178 280 186 270 196 Z" fill="url(#skin)" stroke="${OUT}" stroke-width="4" stroke-linejoin="round"/>` +
  `<path d="M200 278 C148 278 116 244 116 196 C116 150 154 122 200 122 C246 122 284 150 284 196 C284 244 252 278 200 278 Z" fill="url(#skin)" stroke="${OUT}" stroke-width="4.5"/>` +
  `<ellipse cx="146" cy="246" rx="12" ry="6" fill="#FF9A8A" opacity="0.4"/>` +
  `<ellipse cx="254" cy="246" rx="12" ry="6" fill="#FF9A8A" opacity="0.4"/>`;

const hairFront =
  `<path d="M116 188 C110 140 140 104 176 98 L190 74 L204 98 C240 100 282 128 286 186 L270 168 L262 186 L246 150 L236 176 L222 144 L210 172 L198 142 L186 170 L172 142 L160 172 L150 150 L138 182 L130 166 Z" ` +
  `fill="url(#hair)" stroke="${OUT}" stroke-width="4" stroke-linejoin="round"/>` +
  `<path d="M150 118 C168 106 188 102 204 104" stroke="url(#hairHi)" stroke-width="6" fill="none" stroke-linecap="round"/>` +
  // side spikes over the temples
  `<path d="M118 186 L104 226 L126 214 L124 244 L136 222 Z" fill="url(#hair)" stroke="${OUT}" stroke-width="3.5" stroke-linejoin="round"/>` +
  `<path d="M282 186 L296 226 L274 214 L276 244 L264 222 Z" fill="url(#hair)" stroke="${OUT}" stroke-width="3.5" stroke-linejoin="round"/>`;

// small crown worn at a jaunty angle
const crown =
  `<g transform="rotate(12 214 92)">` +
  `<path d="M180 104 L184 72 L198 88 L212 62 L226 88 L240 72 L244 104 Z" fill="url(#gold)" stroke="#8A4F00" stroke-width="3.5" stroke-linejoin="round"/>` +
  `<rect x="178" y="98" width="68" height="11" rx="5" fill="url(#gold)" stroke="#8A4F00" stroke-width="3"/>` +
  `<g filter="url(#lg2)"><path d="M212 76 L220 88 L212 100 L204 88 Z" fill="#9FF4FF"/></g>` +
  `<path d="M212 76 L220 88 L212 100 L204 88 Z" fill="url(#gem)" stroke="#1F6E9A" stroke-width="2"/>` +
  `<circle cx="184" cy="70" r="4" fill="#FFF6D6"/><circle cx="240" cy="70" r="4" fill="#FFF6D6"/></g>`;

// ----------------------------------------------------------------- faces --
const EYE_L = 164, EYE_R = 236, EYE_Y = 208;
function eye(cx, cy, opts = {}) {
  const ry = opts.ry || 24, rx = opts.rx || 21;
  const look = opts.look || [0, 0];
  const irisR = opts.iris || 17;
  return `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="#FFFFFF" stroke="${OUT}" stroke-width="3.5"/>` +
    `<ellipse cx="${cx + look[0]}" cy="${cy + 3 + look[1]}" rx="${irisR * 0.9}" ry="${irisR}" fill="url(#iris)"/>` +
    `<circle cx="${cx + look[0]}" cy="${cy + 5 + look[1]}" r="${irisR * 0.42}" fill="#1A1030"/>` +
    `<circle cx="${cx - 6 + look[0]}" cy="${cy - 5 + look[1]}" r="5.5" fill="#FFFFFF"/>` +
    `<circle cx="${cx + 6 + look[0]}" cy="${cy + 10 + look[1]}" r="2.5" fill="#FFFFFF"/>` +
    `<path d="M${cx - rx} ${cy - ry * 0.4} C${cx - rx * 0.5} ${cy - ry - 2} ${cx + rx * 0.5} ${cy - ry - 2} ${cx + rx} ${cy - ry * 0.4}" stroke="${OUT}" stroke-width="4.5" fill="none" stroke-linecap="round"/>` +
    // bold, confident (not angry) eyebrows
    (opts.brows === false ? '' : `<path d="M${cx - 17} ${cy - ry - 12} C${cx - 6} ${cy - ry - 19} ${cx + 6} ${cy - ry - 19} ${cx + 17} ${cy - ry - 14}" stroke="${OUT}" stroke-width="6" fill="none" stroke-linecap="round"/>`);
}
const pair = (fn) => fn(EYE_L, -1) + fn(EYE_R, 1);

export const EYES = {
  eyes_open: pair((x) => eye(x, EYE_Y)),
  eyes_closed: pair((x) => `<path d="M${x - 20} ${EYE_Y + 4} C${x - 10} ${EYE_Y + 13} ${x + 10} ${EYE_Y + 13} ${x + 20} ${EYE_Y + 4}" stroke="${OUT}" stroke-width="6" fill="none" stroke-linecap="round"/>`),
  eyes_happy: pair((x) => `<path d="M${x - 20} ${EYE_Y + 8} C${x - 11} ${EYE_Y - 12} ${x + 11} ${EYE_Y - 12} ${x + 20} ${EYE_Y + 8}" stroke="${OUT}" stroke-width="7" fill="none" stroke-linecap="round"/>`),
  eyes_wide: pair((x) => eye(x, EYE_Y - 2, { rx: 24, ry: 28, iris: 13 })),
  eyes_sad: pair((x, sd) => eye(x, EYE_Y + 2, { ry: 21, look: [0, 4], brows: false }) +
    `<path d="M${x - 16} ${EYE_Y - 28 + (sd < 0 ? 6 : -6)} L${x + 16} ${EYE_Y - 28 + (sd < 0 ? -6 : 6)}" stroke="${OUT}" stroke-width="5" stroke-linecap="round"/>`),
  eyes_think: pair((x) => eye(x, EYE_Y, { look: [6, -7] })),
};

const MY = 254;
export const MOUTHS = {
  mouth_smile: `<path d="M182 ${MY} C192 ${MY + 10} 210 ${MY + 10} 220 ${MY - 4}" stroke="${OUT}" stroke-width="5" fill="none" stroke-linecap="round"/>`,
  mouth_open: `<path d="M184 ${MY - 2} C188 ${MY + 20} 212 ${MY + 20} 216 ${MY - 2} Z" fill="#7A2A3C" stroke="${OUT}" stroke-width="4" stroke-linejoin="round"/>` +
    `<ellipse cx="200" cy="${MY + 10}" rx="8" ry="4.5" fill="#FF8FA0"/>`,
  mouth_o: `<ellipse cx="200" cy="${MY + 6}" rx="9" ry="11" fill="#7A2A3C" stroke="${OUT}" stroke-width="4"/>`,
  mouth_sad: `<path d="M186 ${MY + 9} C194 ${MY} 206 ${MY} 214 ${MY + 9}" stroke="${OUT}" stroke-width="5" fill="none" stroke-linecap="round"/>`,
  // confident grin with a small fang
  mouth_grin: `<path d="M176 ${MY - 6} C182 ${MY + 22} 218 ${MY + 22} 226 ${MY - 8} Z" fill="#7A2A3C" stroke="${OUT}" stroke-width="4" stroke-linejoin="round"/>` +
    `<path d="M180 ${MY - 3} L222 ${MY - 5}" stroke="#FFFFFF" stroke-width="6"/><path d="M210 ${MY - 2} L214 ${MY + 6} L218 ${MY - 2} Z" fill="#FFFFFF"/>`,
  mouth_small: `<path d="M190 ${MY + 5} L212 ${MY + 1}" stroke="${OUT}" stroke-width="5" stroke-linecap="round"/>`,
};

/** Parts in draw order with their joint (pivot) in canvas coordinates. */
export const PARTS = [
  { id: 'lumi_wing_l', joint: 'wing_l', pivot: [200, 292], body: circleHalf('l') },
  { id: 'lumi_wing_r', joint: 'wing_r', pivot: [200, 292], body: circleHalf('r') },
  { id: 'lumi_hair_back', joint: 'head_back', pivot: [200, 286], body: hairBack },
  { id: 'lumi_body', joint: 'body', pivot: [200, 400], body },
  { id: 'lumi_arm_l', joint: 'arm_l', pivot: [168, 304], body: arm('l') },
  { id: 'lumi_head', joint: 'head', pivot: [200, 286], body: head },
  { id: 'lumi_eyes', joint: 'head', pivot: [200, 286], face: 'eyes', variants: EYES },
  { id: 'lumi_mouth', joint: 'head', pivot: [200, 286], face: 'mouth', variants: MOUTHS },
  { id: 'lumi_hair_front', joint: 'head', pivot: [200, 286], body: hairFront },
  { id: 'lumi_crown', joint: 'head', pivot: [200, 286], body: crown },
  { id: 'lumi_arm_r', joint: 'arm_r', pivot: [232, 304], body: arm('r') },
];

/** Full portrait (all parts) for icons and previews. */
export function portraitBody(eyes = 'eyes_open', mouth = 'mouth_smile') {
  return PARTS.map((p) => p.variants ? p.variants[p.face === 'eyes' ? eyes : mouth] : p.body).join('');
}
