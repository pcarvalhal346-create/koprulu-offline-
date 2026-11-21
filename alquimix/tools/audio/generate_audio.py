"""Procedural, original sound effects and music for Alquimix.

Everything is synthesised from sine/noise oscillators with numpy (no samples),
then encoded to OGG Vorbis with ffmpeg. Usage (project root):

    python3 tools/audio/generate_audio.py
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 44100
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "audio")
rng = np.random.default_rng(1234)


def t(d):
    return np.arange(int(SR * d)) / SR


def env(n, a=0.005, d=0.1, s=0.0, r=0.05, total=None):
    """ADSR envelope of n samples (times in seconds)."""
    total = n
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    s_n = max(0, total - a_n - d_n - r_n)
    e = np.concatenate([
        np.linspace(0, 1, max(a_n, 1)),
        np.linspace(1, s, max(d_n, 1)),
        np.full(s_n, s),
        np.linspace(s, 0, max(r_n, 1)),
    ])
    return e[:total] if len(e) >= total else np.pad(e, (0, total - len(e)))


def expdecay(n, k):
    return np.exp(-np.arange(n) / SR * k)


def bell(freq, d, k=6.0, bright=1.0):
    x = t(d)
    s = (np.sin(2 * np.pi * freq * x) + 0.5 * bright * np.sin(2 * np.pi * freq * 2.76 * x)
         + 0.25 * bright * np.sin(2 * np.pi * freq * 5.4 * x) * expdecay(len(x), k * 2))
    return s * expdecay(len(x), k) * env(len(x), 0.002, 0.0, 1.0, 0.02)


def pluck(freq, d, k=9.0):
    x = t(d)
    s = np.sin(2 * np.pi * freq * x) + 0.3 * np.sin(2 * np.pi * 2 * freq * x) + 0.1 * np.sin(2 * np.pi * 3 * freq * x)
    return s * expdecay(len(x), k) * env(len(x), 0.003, 0, 1, 0.01)


def sweep(f0, f1, d, shape="sin"):
    x = t(d)
    f = np.geomspace(f0, f1, len(x))
    ph = 2 * np.pi * np.cumsum(f) / SR
    if shape == "tri":
        return 2 / np.pi * np.arcsin(np.sin(ph))
    return np.sin(ph)


def noise(d):
    return rng.uniform(-1, 1, int(SR * d))


def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def lowpass_fast(x, cutoff):
    # simple moving-average approximation (fast enough for long buffers)
    n = max(1, int(SR / cutoff / 2))
    k = np.ones(n) / n
    return np.convolve(x, k, mode="same")


def highpass(x, cutoff):
    return x - lowpass_fast(x, cutoff)


def mix(*parts):
    n = max(len(p[1]) + int(p[0] * SR) for p in parts)
    out = np.zeros(n)
    for start, sig, *g in parts:
        s = int(start * SR)
        out[s:s + len(sig)] += sig * (g[0] if g else 1.0)
    return out


def layer(*xs):
    """Sum signals of different lengths (zero padded)."""
    n = max(len(x) for x in xs)
    out = np.zeros(n)
    for x in xs:
        out[:len(x)] += x
    return out


def note(n):
    """MIDI note -> Hz"""
    return 440.0 * 2 ** ((n - 69) / 12)


def normalize(x, peak=0.85):
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def save(name, x, peak=0.85, stereo=False):
    x = normalize(x, peak)
    fade = min(len(x), int(0.01 * SR))
    x[-fade:] *= np.linspace(1, 0, fade)
    data = (x * 32767).astype(np.int16)
    os.makedirs(OUT, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        path = tmp.name
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    dst = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-c:a", "libvorbis", "-q:a", "4", dst], check=True)
    os.unlink(path)
    return dst


# ------------------------------------------------------------------ effects --
def sfx():
    save("select", pluck(note(88), 0.12, 30) + 0.4 * pluck(note(95), 0.12, 30))
    save("swap", highpass(noise(0.16), 900) * env(int(0.16 * SR), 0.03, 0.1, 0, 0.03) * 0.6 + 0.3 * sweep(500, 900, 0.16) * expdecay(int(0.16 * SR), 18))
    save("invalid", mix((0, pluck(note(55), 0.12, 20)), (0.09, pluck(note(50), 0.16, 18))))
    save("match", mix((0, bell(note(84), 0.35, 9)), (0.04, bell(note(88), 0.35, 9), 0.8), (0.08, bell(note(91), 0.4, 8), 0.7)))
    save("cascade", mix((0, bell(note(91), 0.3, 10)), (0.05, bell(note(96), 0.35, 9), 0.8)))
    sh = sweep(600, 2400, 0.45) * env(int(0.45 * SR), 0.02, 0.1, 0.6, 0.2)
    save("charge", layer(sh * 0.5, mix((0.25, bell(note(100), 0.3, 10), 0.6))))
    fm = np.sin(2 * np.pi * np.cumsum(np.geomspace(300, 1200, int(0.6 * SR)) + 200 * np.sin(2 * np.pi * 9 * t(0.6))) / SR)
    save("fusion", layer(fm * env(int(0.6 * SR), 0.05, 0.2, 0.5, 0.25) * 0.5,
                         mix((0.3, bell(note(72), 0.8, 4)), (0.3, bell(note(76), 0.8, 4), 0.8), (0.3, bell(note(79), 0.8, 4), 0.7))))
    arp = [72, 76, 79, 84, 88, 91, 96]
    save("discovery", mix(*[(i * 0.09, bell(note(n), 1.0, 3.5), 0.9) for i, n in enumerate(arp)],
                          (0.7, bell(note(84), 1.4, 2.2)), (0.7, bell(note(88), 1.4, 2.2), 0.8), (0.7, bell(note(91), 1.4, 2.2), 0.8)))
    save("button", layer(pluck(note(79), 0.08, 40), 0.3 * highpass(noise(0.03), 3000) * expdecay(int(0.03 * SR), 120)))
    save("lumi", mix(*[(i * 0.06, bell(note(n), 0.5, 6), 0.7) for i, n in enumerate([91, 96, 100, 103])]))
    save("star", mix((0, bell(note(96), 0.6, 5)), (0.0, bell(note(103), 0.6, 5), 0.5)))
    save("shuffle", highpass(noise(0.5), 1200) * np.sin(np.linspace(0, np.pi, int(0.5 * SR))) * 0.5 + 0.3 * sweep(300, 1200, 0.5, "tri") * np.sin(np.linspace(0, np.pi, int(0.5 * SR))))
    save("rock_break", lowpass_fast(noise(0.35), 500) * expdecay(int(0.35 * SR), 12) * 2 + 0.6 * sweep(120, 50, 0.35) * expdecay(int(0.35 * SR), 10))
    save("frost_break", mix(*[(i * 0.03, bell(note(100 + (i * 5) % 9), 0.25, 18), 0.6) for i in range(5)]))
    save("vine_cut", layer(highpass(noise(0.12), 2500) * expdecay(int(0.12 * SR), 30), 0.5 * pluck(note(60), 0.15, 25)))
    save("victory", mix(*[(i * 0.12, bell(note(n), 0.6, 4), 0.9) for i, n in enumerate([72, 76, 79, 84])],
                        (0.55, bell(note(84), 1.6, 1.8)), (0.55, bell(note(88), 1.6, 1.8), 0.9), (0.55, bell(note(91), 1.6, 1.8), 0.9),
                        (0.55, bell(note(96), 1.6, 1.8), 0.7)))
    save("defeat", mix(*[(i * 0.25, pluck(note(n), 0.7, 4), 0.9) for i, n in enumerate([67, 64, 60, 55])]))

    # compound powers -------------------------------------------------------
    d = 0.7
    n = int(d * SR)
    save("power_steam", highpass(noise(d), 1500) * env(n, 0.05, 0.2, 0.6, 0.3) + 0.3 * sweep(200, 800, d) * env(n, 0.05, 0.2, 0.4, 0.3))
    save("power_lava", lowpass_fast(noise(d), 300) * expdecay(n, 5) * 2 + sweep(90, 35, d) * expdecay(n, 4))
    zap = np.sign(np.sin(2 * np.pi * np.cumsum(np.geomspace(1800, 200, n)) / SR)) * expdecay(n, 6)
    save("power_plasma", 0.4 * zap + 0.4 * sweep(2000, 300, d) * expdecay(n, 5))
    save("power_life", mix(*[(i * 0.07, pluck(note(n0), 0.5, 6), 0.8) for i, n0 in enumerate([60, 64, 67, 72, 76])]))
    save("power_ice", mix(*[(i * 0.04, bell(note(96 + (i * 7) % 12), 0.4, 10), 0.6) for i in range(8)]))
    save("power_dust", highpass(noise(d), 600) * np.sin(np.linspace(0, np.pi, n)) * 0.6 + 0.2 * lowpass_fast(noise(d), 200))
    thunder = layer(lowpass_fast(noise(1.0), 250) * expdecay(int(SR), 3) * 2.5, highpass(noise(1.0), 3000) * expdecay(int(SR), 30))
    save("power_storm", thunder)
    save("power_obsidian", mix((0, sweep(110, 40, 0.8) * expdecay(int(0.8 * SR), 4)),
                               *[(0.1 + i * 0.05, bell(note(80 + i * 3), 0.4, 12), 0.5) for i in range(6)]))
    save("power_forest", mix(*[(i * 0.06, pluck(note(n0), 0.35, 10), 0.8) for i, n0 in enumerate([55, 59, 62, 67, 71, 74, 79])]))
    save("power_crystal", mix(*[(i * 0.05, bell(note(84 + i * 2), 0.8, 4), 0.6) for i in range(10)]))


# -------------------------------------------------------------------- music --
def music(name, bpm, progression, melody, seed, bars_per_chord=1, swing=0.0):
    r = np.random.default_rng(seed)
    beat = 60.0 / bpm
    bar = beat * 4
    total = bar * len(progression) * bars_per_chord
    n = int(total * SR)
    out = np.zeros(n + SR * 2)

    def put(start, sig, g=1.0):
        s = int(start * SR)
        out[s:s + len(sig)] += sig[: max(0, len(out) - s)] * g

    for i, chord in enumerate(progression):
        t0 = i * bar * bars_per_chord
        dur = bar * bars_per_chord
        # warm pad: detuned sines with slow attack
        for k, nn in enumerate(chord):
            x = t(dur + 0.4)
            f = note(nn)
            pad = (np.sin(2 * np.pi * f * x) + 0.6 * np.sin(2 * np.pi * f * 1.003 * x) + 0.3 * np.sin(2 * np.pi * 2 * f * x))
            put(t0, pad * env(len(x), 0.4, 0.2, 0.7, 0.4), 0.05)
        # bass
        for b in range(4 * bars_per_chord):
            if b % 2 == 0:
                put(t0 + b * beat, pluck(note(chord[0] - 12), beat * 1.6, 5), 0.22)
        # arpeggio bells
        for s in range(8 * bars_per_chord):
            nn = chord[(s + (s // 4)) % len(chord)] + 12
            st = t0 + s * beat / 2 + (swing * beat / 2 if s % 2 else 0)
            put(st, bell(note(nn), 0.5, 7), 0.09)
        # soft shaker + kick
        for b in range(4 * bars_per_chord):
            st = t0 + b * beat
            put(st + beat / 2, highpass(r.uniform(-1, 1, int(0.06 * SR)), 5000) * expdecay(int(0.06 * SR), 60), 0.05)
            if b % 2 == 0:
                put(st, sweep(120, 45, 0.18) * expdecay(int(0.18 * SR), 18), 0.25)
    # melody (8th-note grid, None = rest)
    step = beat / 2
    for i, m in enumerate(melody):
        if m is not None:
            put(i * step, bell(note(m), step * 2.5, 4.5, 0.6), 0.16)
    out = out[:n]
    # loop-friendly: crossfade the tail into the head
    tail = int(0.3 * SR)
    out[:tail] = out[:tail] * np.linspace(0.3, 1, tail)
    out[-tail:] *= np.linspace(1, 0.3, tail)
    save(name, out, 0.7)


def make_music():
    C, Am, F, G, Em, Dm = [60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62], [52, 55, 59], [50, 53, 57]
    prog = [C, Am, F, G, C, Em, F, G, Am, F, C, G, F, G, C, C]
    mel = []
    phrase = [76, None, 79, 81, 79, None, 76, 74, 72, None, 74, 76, 74, None, None, None]
    phrase2 = [72, 74, 76, None, 79, None, 81, 79, 76, None, 74, None, 72, None, None, None]
    for k in range(len(prog) // 2):
        mel += phrase if k % 2 == 0 else phrase2
    music("music_menu", 92, prog, mel, 7)
    prog2 = [Am, F, C, G, Am, F, Dm, G, F, G, Em, Am, F, G, C, G]
    p3 = [69, None, 72, 74, 76, 74, 72, None, 74, None, 76, 79, 76, None, 74, None]
    p4 = [72, 74, 72, None, 69, None, 67, 69, 72, None, 71, None, 72, None, None, None]
    mel2 = []
    for k in range(len(prog2) // 2):
        mel2 += p3 if k % 2 == 0 else p4
    music("music_game", 112, prog2, mel2, 9, swing=0.12)


if __name__ == "__main__":
    sfx()
    make_music()
    print("\n".join(sorted(os.listdir(OUT))))
