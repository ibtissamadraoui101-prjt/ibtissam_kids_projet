"""
LinguaKids — Générateur de sons
Exécute ce script UNE SEULE FOIS depuis la racine de ton projet :
    python3 generate_sounds.py

Il génère de vrais fichiers WAV dans assets/sounds/sfx/ et assets/sounds/music/
(Flutter accepte les WAV même avec l'extension .mp3)
"""
import struct, math, os, random

def write_wav(filename, samples, sample_rate=44100):
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    num_samples = len(samples)
    with open(filename, 'wb') as f:
        f.write(b'RIFF')
        f.write(struct.pack('<I', 36 + num_samples * 2))
        f.write(b'WAVE')
        f.write(b'fmt ')
        f.write(struct.pack('<I', 16))
        f.write(struct.pack('<H', 1))
        f.write(struct.pack('<H', 1))
        f.write(struct.pack('<I', sample_rate))
        f.write(struct.pack('<I', sample_rate * 2))
        f.write(struct.pack('<H', 2))
        f.write(struct.pack('<H', 16))
        f.write(b'data')
        f.write(struct.pack('<I', num_samples * 2))
        for s in samples:
            s = max(-32767, min(32767, int(s * 32767)))
            f.write(struct.pack('<h', s))

SR = 44100

def sine(freq, dur, vol=0.5, fade=0.015):
    n = int(SR * dur)
    fade_n = int(SR * fade)
    out = []
    for i in range(n):
        t = i / SR
        s = vol * math.sin(2 * math.pi * freq * t)
        if i < fade_n:
            s *= i / fade_n
        elif i > n - fade_n:
            s *= (n - i) / fade_n
        out.append(s)
    return out

def seq(freqs, durs, vol=0.4):
    out = []
    for f, d in zip(freqs, durs):
        out += sine(f, d, vol)
        out += [0] * int(SR * 0.015)
    return out

def noise(dur, vol=0.25):
    n = int(SR * dur)
    return [vol * (random.random()*2-1) * min(i, n-i)/(n*0.1+1) for i in range(n)]

def music_loop(base, dur=6.0, vol=0.12):
    ratios = [1, 1.25, 1.5, 2, 1.5, 1.25, 1]
    note = dur / len(ratios) / 2
    out = []
    target = int(SR * dur)
    while len(out) < target:
        for r in ratios:
            out += sine(base * r, note, vol)
    return out[:target]

sounds_sfx = {
    'click':        seq([800, 1000],            [0.04, 0.03],               0.30),
    'pop':          seq([600, 900],             [0.05, 0.05],               0.28),
    'woosh':        noise(0.12,                                             0.22),
    'correct':      seq([523, 659, 784, 1047],  [0.08,0.08,0.08,0.18],     0.42),
    'wrong':        seq([440, 350],             [0.12, 0.20],               0.22),  # doux
    'soft_wrong':   seq([380, 320],             [0.10, 0.18],               0.16),  # très doux
    'try_again':    seq([330, 294],             [0.10, 0.16],               0.20),  # doux
    'timeout':      seq([440, 415, 392],        [0.15,0.15,0.30],           0.28),
    'card_flip':    noise(0.07,                                             0.18),
    'match':        seq([523,659,784,1047,1319],[0.07,0.07,0.07,0.07,0.22], 0.40),
    'combo':        seq([523,659,784,988,1175,1319],[0.06]*5+[0.22],        0.40),
    'bingo':        seq([523,659,784,988,1319,1047,1319],[0.08]*6+[0.38],   0.45),
    'star':         seq([1047,1319,1568,2093],  [0.08,0.08,0.08,0.28],     0.38),
    'level_done':   seq([523,659,784,988,1319,784,988,1319],[0.10]*7+[0.42],0.45),
    'unlock':       seq([523,784,1047,1319],    [0.10,0.10,0.10,0.32],     0.38),
    'island_enter': seq([392,494,587,784,988],  [0.10]*4+[0.32],           0.38),
    'game_start':   seq([392,494,587,784],      [0.10,0.10,0.10,0.22],     0.38),
    'bravo':        seq([784,988,1175,1319],    [0.10,0.10,0.10,0.28],     0.40),
}

sounds_music = {
    'world_map':    music_loop(261.63, 6.0, 0.11),
    'memory':       music_loop(329.63, 5.0, 0.11),
    'quiz':         music_loop(349.23, 5.0, 0.11),
    'bingo':        music_loop(392.00, 5.0, 0.11),
    'celebration':  music_loop(523.25, 5.0, 0.14),
    'welcome':      music_loop(293.66, 6.0, 0.11),
}

print("🎵 Génération des sons LinguaKids...\n")

for name, samples in sounds_sfx.items():
    path = f'assets/sounds/sfx/{name}.mp3'
    write_wav(path, samples)
    ms = int(len(samples) / SR * 1000)
    print(f'  ✅ sfx/{name}.mp3  ({ms}ms)')

for name, samples in sounds_music.items():
    path = f'assets/sounds/music/{name}.mp3'
    write_wav(path, samples)
    sec = len(samples) // SR
    print(f'  ✅ music/{name}.mp3  ({sec}s)')

print("\n✅ Tous les sons générés ! Lance maintenant : flutter run -d chrome")