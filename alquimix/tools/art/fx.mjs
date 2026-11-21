// Particle and effect sprites (white or coloured; tinted at runtime).
import { svg, lin, rad, glowFilter, sparkle, star } from './lib.mjs';

export const fx = {
  spark: () => svg(64, 64, `<path d="${sparkle(32, 32, 30, 0.18)}" fill="#FFFFFF"/><circle cx="32" cy="32" r="6" fill="#FFFFFF"/>`),
  dot: () => svg(32, 32, `<circle cx="16" cy="16" r="15" fill="url(#d)"/>`, rad('d', [[0, '#FFFFFF'], [0.5, '#FFFFFF', 0.8], [1, '#FFFFFF', 0]])),
  ring: () => svg(128, 128, `<circle cx="64" cy="64" r="56" fill="none" stroke="#FFFFFF" stroke-width="8"/>`),
  glow: () => svg(128, 128, `<circle cx="64" cy="64" r="63" fill="url(#g)"/>`, rad('g', [[0, '#FFFFFF'], [0.35, '#FFFFFF', 0.6], [1, '#FFFFFF', 0]])),
  star: () => svg(64, 64, `<path d="${star(32, 33, 29, 13)}" fill="#FFFFFF"/>`),
  flame: () => svg(48, 64, `<path d="M24 2 C30 18 44 26 44 42 C44 56 34 62 24 62 C14 62 4 56 4 42 C4 30 14 24 16 12 C18 20 22 22 24 24 C22 16 22 10 24 2 Z" fill="url(#f)"/>`,
    lin('f', [[0, '#FFF3A0'], [0.5, '#FF9A3C'], [1, '#FF4A1F']])),
  drop: () => svg(40, 56, `<path d="M20 2 C26 16 38 28 38 38 C38 48 30 54 20 54 C10 54 2 48 2 38 C2 28 14 16 20 2 Z" fill="#BFF3FF"/>`),
  leaf: () => svg(56, 40, `<path d="M2 20 C14 2 42 2 54 20 C42 38 14 38 2 20 Z" fill="#8BE36E"/><path d="M4 20 L52 20" stroke="#2E8B3C" stroke-width="3"/>`),
  shard: () => svg(40, 64, `<path d="M20 2 L38 24 L20 62 L2 24 Z" fill="#E6FAFF" stroke="#7FD3FF" stroke-width="3"/>`),
  bolt: () => svg(64, 128, `<path d="M38 2 L10 70 L30 70 L18 126 L56 48 L34 48 L48 2 Z" fill="#FFFFFF"/>`),
  beam: () => svg(256, 48, `<rect x="0" y="4" width="256" height="40" rx="20" fill="url(#b)"/>`,
    lin('b', [[0, '#FFFFFF', 0], [0.15, '#FFFFFF', 0.9], [0.85, '#FFFFFF', 0.9], [1, '#FFFFFF', 0]], 0, 0, 1, 0) ),
  beam_v: () => svg(48, 256, `<rect x="4" y="0" width="40" height="256" rx="20" fill="url(#b)"/>`,
    lin('b', [[0, '#FFFFFF', 0], [0.15, '#FFFFFF', 0.9], [0.85, '#FFFFFF', 0.9], [1, '#FFFFFF', 0]], 0, 0, 0, 1)),
  cloud: () => svg(96, 64, `<path d="M20 52 C6 52 4 34 18 32 C18 16 38 10 46 22 C54 6 80 10 80 28 C94 28 94 52 80 52 Z" fill="#FFFFFF"/>`),
  grain: () => svg(24, 24, `<circle cx="12" cy="12" r="9" fill="#FFE8A3" stroke="#C99A3E" stroke-width="2"/>`),
  confetti: () => svg(24, 40, `<rect x="2" y="2" width="20" height="36" rx="5" fill="#FFFFFF"/>`),
  smoke: () => svg(64, 64, `<circle cx="32" cy="32" r="30" fill="url(#s)"/>`, rad('s', [[0, '#FFFFFF', 0.9], [1, '#FFFFFF', 0]])),
  crack: () => svg(128, 128, `<path d="M64 6 L56 40 L74 58 L50 86 L62 122 M74 58 L110 68 M56 40 L22 30" stroke="#FFFFFF" stroke-width="7" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`),
  swirl: () => svg(128, 128, `<g filter="url(#g)"><path d="M64 64 m0 -8 a8 8 0 1 1 -8 8 a18 18 0 0 1 18 -18 a28 28 0 0 1 28 28 a38 38 0 0 1 -38 38 a46 46 0 0 1 -44 -32" stroke="#FFFFFF" stroke-width="10" fill="none" stroke-linecap="round"/></g>`, glowFilter('g', 2)),
  question: () => svg(64, 64, `<text x="32" y="50" text-anchor="middle" font-family="Fredoka" font-size="52" fill="#FFFFFF" stroke="#3A2B94" stroke-width="5" paint-order="stroke">?</text>`),
  exclaim: () => svg(64, 64, `<text x="32" y="52" text-anchor="middle" font-family="Fredoka" font-size="56" fill="#FFD36A" stroke="#8A4F00" stroke-width="5" paint-order="stroke">!</text>`),
  heart: () => svg(64, 64, `<path d="M32 56 C10 40 4 28 10 18 C16 8 28 10 32 20 C36 10 48 8 54 18 C60 28 54 40 32 56 Z" fill="#FF75C9" stroke="#FFFFFF" stroke-width="3"/>`),
};
