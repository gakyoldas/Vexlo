#!/usr/bin/env python3
import math
import random
import struct
import wave
from pathlib import Path


SAMPLE_RATE = 48000


def clamp(value, low, high):
    return max(low, min(high, value))


def sine(freq, t):
    return math.sin(2.0 * math.pi * freq * t)


def smoothstep(x):
    x = clamp(x, 0.0, 1.0)
    return x * x * (3.0 - 2.0 * x)


def make_env(length, attack_ms, hold_ms, decay_ms):
    attack = max(1, int(SAMPLE_RATE * attack_ms / 1000.0))
    hold = max(0, int(SAMPLE_RATE * hold_ms / 1000.0))
    decay = max(1, int(SAMPLE_RATE * decay_ms / 1000.0))
    env = [0.0] * length
    for i in range(length):
        if i < attack:
            env[i] = smoothstep(float(i) / attack)
        elif i < attack + hold:
            env[i] = 1.0
        else:
            d = i - attack - hold
            env[i] = clamp(1.0 - float(d) / decay, 0.0, 1.0)
    return env


def make_exp_env(length, attack_ms, decay_ms, curve):
    attack = max(1, int(SAMPLE_RATE * attack_ms / 1000.0))
    decay = max(1, int(SAMPLE_RATE * decay_ms / 1000.0))
    env = [0.0] * length
    for i in range(length):
        if i < attack:
            env[i] = smoothstep(float(i) / attack)
        else:
            d = clamp(float(i - attack) / decay, 0.0, 1.0)
            env[i] = math.pow(max(0.0, 1.0 - d), curve)
    return env


def lowpass(samples, cutoff_hz):
    if cutoff_hz <= 0:
        return samples[:]
    dt = 1.0 / SAMPLE_RATE
    rc = 1.0 / (2.0 * math.pi * cutoff_hz)
    alpha = dt / (rc + dt)
    out = []
    prev = 0.0
    for sample in samples:
        prev = prev + alpha * (sample - prev)
        out.append(prev)
    return out


def highpass(samples, cutoff_hz):
    if cutoff_hz <= 0:
        return samples[:]
    dt = 1.0 / SAMPLE_RATE
    rc = 1.0 / (2.0 * math.pi * cutoff_hz)
    alpha = rc / (rc + dt)
    out = []
    prev_out = 0.0
    prev_in = 0.0
    for sample in samples:
        current = alpha * (prev_out + sample - prev_in)
        out.append(current)
        prev_out = current
        prev_in = sample
    return out


def apply_fade(samples, fade_out_ms):
    fade_frames = int(SAMPLE_RATE * fade_out_ms / 1000.0)
    fade_frames = min(fade_frames, len(samples))
    for i in range(fade_frames):
        idx = len(samples) - fade_frames + i
        gain = 1.0 - smoothstep(float(i) / max(1, fade_frames - 1))
        samples[idx] *= gain
    return samples


def mix(layers):
    length = max(len(layer) for layer in layers)
    out = [0.0] * length
    for layer in layers:
        for i, sample in enumerate(layer):
            out[i] += sample
    return out


def normalize(samples, peak=0.9):
    current = max(abs(sample) for sample in samples) or 1.0
    gain = peak / current
    return [clamp(sample * gain, -1.0, 1.0) for sample in samples]


def soft_clip(samples, drive):
    norm = math.tanh(drive)
    return [math.tanh(sample * drive) / norm for sample in samples]


def tonal_layer(duration_ms, freq_a, freq_b, attack_ms, hold_ms, decay_ms, gain, vibrato_hz=0.0, vibrato_depth=0.0):
    length = int(SAMPLE_RATE * duration_ms / 1000.0)
    env = make_env(length, attack_ms, hold_ms, decay_ms)
    out = []
    for i in range(length):
        t = float(i) / SAMPLE_RATE
        slide = float(i) / max(1, length - 1)
        freq = freq_a + (freq_b - freq_a) * slide
        if vibrato_hz > 0.0 and vibrato_depth > 0.0:
            freq *= 1.0 + vibrato_depth * sine(vibrato_hz, t)
        sample = (
            0.70 * sine(freq, t) +
            0.22 * sine(freq * 2.0, t) +
            0.08 * sine(freq * 3.0, t)
        )
        out.append(sample * env[i] * gain)
    return out


def bloom_layer(duration_ms, freq, attack_ms, decay_ms, gain):
    length = int(SAMPLE_RATE * duration_ms / 1000.0)
    env = make_exp_env(length, attack_ms, decay_ms, 1.9)
    out = []
    for i in range(length):
        t = float(i) / SAMPLE_RATE
        sample = (
            0.82 * sine(freq, t) +
            0.12 * sine(freq * 1.5, t) +
            0.06 * sine(freq * 2.0, t)
        )
        out.append(sample * env[i] * gain)
    return lowpass(out, 2600)


def thump_layer(duration_ms, freq, gain):
    length = int(SAMPLE_RATE * duration_ms / 1000.0)
    env = make_exp_env(length, 1.5, duration_ms * 0.75, 2.4)
    out = []
    for i in range(length):
        t = float(i) / SAMPLE_RATE
        pitch = freq * (1.16 - 0.16 * (float(i) / max(1, length - 1)))
        out.append(sine(pitch, t) * env[i] * gain)
    return lowpass(out, 900)


def air_layer(duration_ms, gain, seed):
    rng = random.Random(seed)
    length = int(SAMPLE_RATE * duration_ms / 1000.0)
    env = make_exp_env(length, 1.5, duration_ms * 0.6, 2.2)
    noise = [(rng.uniform(-1.0, 1.0)) * env[i] * gain for i in range(length)]
    noise = lowpass(noise, 1800)
    noise = highpass(noise, 300)
    return noise


def render_event(spec):
    layers = []
    if spec.get("thump"):
        layers.append(thump_layer(spec["duration_ms"], spec["thump"]["freq"], spec["thump"]["gain"]))
    layers.append(
        tonal_layer(
            spec["duration_ms"],
            spec["tone"]["freq_a"],
            spec["tone"]["freq_b"],
            spec["tone"]["attack_ms"],
            spec["tone"]["hold_ms"],
            spec["tone"]["decay_ms"],
            spec["tone"]["gain"],
            spec["tone"].get("vibrato_hz", 0.0),
            spec["tone"].get("vibrato_depth", 0.0),
        )
    )
    if spec.get("bloom"):
        layers.append(
            bloom_layer(
                spec["duration_ms"] + spec["bloom"].get("tail_extra_ms", 0),
                spec["bloom"]["freq"],
                spec["bloom"]["attack_ms"],
                spec["bloom"]["decay_ms"],
                spec["bloom"]["gain"],
            )
        )
    if spec.get("air"):
        layers.append(air_layer(spec["duration_ms"], spec["air"]["gain"], spec["air"]["seed"]))

    samples = mix(layers)
    samples = lowpass(samples, spec.get("master_lowpass_hz", 4200))
    samples = highpass(samples, spec.get("master_highpass_hz", 90))
    samples = soft_clip(samples, spec.get("drive", 1.25))
    samples = apply_fade(samples, spec.get("fade_out_ms", 18))
    samples = normalize(samples, spec.get("peak", 0.9))
    return samples


def write_wav(path, samples):
    path.parent.mkdir(parents=True, exist_ok=True)
    ints = [int(round(clamp(sample, -1.0, 1.0) * 32767.0)) for sample in samples]
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SAMPLE_RATE)
        handle.writeframes(struct.pack("<%dh" % len(ints), *ints))


EVENTS = {
    "sfx_piece_place.wav": {
        "duration_ms": 240,
        "thump": {"freq": 180, "gain": 0.18},
        "tone": {"freq_a": 420, "freq_b": 360, "attack_ms": 2, "hold_ms": 16, "decay_ms": 180, "gain": 0.38},
        "bloom": {"freq": 740, "attack_ms": 5, "decay_ms": 120, "gain": 0.08},
        "air": {"gain": 0.012, "seed": 11},
        "master_lowpass_hz": 3100,
        "master_highpass_hz": 100,
        "drive": 1.18
    },
    "sfx_invalid.wav": {
        "duration_ms": 190,
        "tone": {"freq_a": 340, "freq_b": 290, "attack_ms": 2, "hold_ms": 12, "decay_ms": 140, "gain": 0.34},
        "bloom": {"freq": 520, "attack_ms": 4, "decay_ms": 90, "gain": 0.05},
        "air": {"gain": 0.01, "seed": 13},
        "master_lowpass_hz": 2600,
        "master_highpass_hz": 120,
        "drive": 1.12,
        "peak": 0.82
    },
    "sfx_line_clear.wav": {
        "duration_ms": 310,
        "thump": {"freq": 150, "gain": 0.16},
        "tone": {"freq_a": 460, "freq_b": 560, "attack_ms": 2, "hold_ms": 20, "decay_ms": 200, "gain": 0.34},
        "bloom": {"freq": 860, "attack_ms": 6, "decay_ms": 180, "gain": 0.10},
        "air": {"gain": 0.012, "seed": 17},
        "master_lowpass_hz": 3600,
        "master_highpass_hz": 90,
        "drive": 1.2
    },
    "sfx_combo_x2.wav": {
        "duration_ms": 360,
        "thump": {"freq": 165, "gain": 0.18},
        "tone": {"freq_a": 480, "freq_b": 660, "attack_ms": 2, "hold_ms": 20, "decay_ms": 230, "gain": 0.33},
        "bloom": {"freq": 980, "attack_ms": 8, "decay_ms": 220, "gain": 0.12},
        "air": {"gain": 0.014, "seed": 19},
        "master_lowpass_hz": 3900,
        "master_highpass_hz": 90,
        "drive": 1.22
    },
    "sfx_combo_x3_plus.wav": {
        "duration_ms": 430,
        "thump": {"freq": 160, "gain": 0.16},
        "tone": {"freq_a": 520, "freq_b": 760, "attack_ms": 2, "hold_ms": 28, "decay_ms": 270, "gain": 0.34},
        "bloom": {"freq": 1120, "attack_ms": 10, "decay_ms": 260, "gain": 0.14},
        "air": {"gain": 0.014, "seed": 23},
        "master_lowpass_hz": 4100,
        "master_highpass_hz": 90,
        "drive": 1.24
    },
    "sfx_new_best.wav": {
        "duration_ms": 520,
        "thump": {"freq": 145, "gain": 0.14},
        "tone": {"freq_a": 420, "freq_b": 620, "attack_ms": 3, "hold_ms": 30, "decay_ms": 320, "gain": 0.30},
        "bloom": {"freq": 940, "attack_ms": 12, "decay_ms": 340, "gain": 0.12, "tail_extra_ms": 40},
        "air": {"gain": 0.012, "seed": 29},
        "master_lowpass_hz": 3600,
        "master_highpass_hz": 80,
        "drive": 1.18
    },
    "sfx_daily_complete.wav": {
        "duration_ms": 640,
        "thump": {"freq": 140, "gain": 0.12},
        "tone": {"freq_a": 400, "freq_b": 560, "attack_ms": 3, "hold_ms": 36, "decay_ms": 420, "gain": 0.27},
        "bloom": {"freq": 820, "attack_ms": 14, "decay_ms": 420, "gain": 0.13, "tail_extra_ms": 90},
        "air": {"gain": 0.012, "seed": 31},
        "master_lowpass_hz": 3400,
        "master_highpass_hz": 80,
        "drive": 1.16
    },
    "sfx_game_over.wav": {
        "duration_ms": 360,
        "thump": {"freq": 135, "gain": 0.13},
        "tone": {"freq_a": 390, "freq_b": 320, "attack_ms": 3, "hold_ms": 20, "decay_ms": 240, "gain": 0.28},
        "bloom": {"freq": 620, "attack_ms": 10, "decay_ms": 220, "gain": 0.08},
        "air": {"gain": 0.01, "seed": 37},
        "master_lowpass_hz": 3000,
        "master_highpass_hz": 80,
        "drive": 1.14,
        "peak": 0.84
    },
    "sfx_utility_open.wav": {
        "duration_ms": 150,
        "tone": {"freq_a": 540, "freq_b": 700, "attack_ms": 2, "hold_ms": 8, "decay_ms": 110, "gain": 0.26},
        "bloom": {"freq": 980, "attack_ms": 4, "decay_ms": 80, "gain": 0.05},
        "air": {"gain": 0.008, "seed": 41},
        "master_lowpass_hz": 4200,
        "master_highpass_hz": 140,
        "drive": 1.1,
        "peak": 0.78
    },
    "sfx_utility_close.wav": {
        "duration_ms": 140,
        "tone": {"freq_a": 500, "freq_b": 380, "attack_ms": 2, "hold_ms": 8, "decay_ms": 100, "gain": 0.24},
        "bloom": {"freq": 720, "attack_ms": 4, "decay_ms": 70, "gain": 0.04},
        "air": {"gain": 0.008, "seed": 43},
        "master_lowpass_hz": 3600,
        "master_highpass_hz": 140,
        "drive": 1.08,
        "peak": 0.76
    },
    "sfx_share.wav": {
        "duration_ms": 160,
        "tone": {"freq_a": 520, "freq_b": 640, "attack_ms": 2, "hold_ms": 8, "decay_ms": 110, "gain": 0.25},
        "bloom": {"freq": 860, "attack_ms": 5, "decay_ms": 90, "gain": 0.05},
        "air": {"gain": 0.008, "seed": 47},
        "master_lowpass_hz": 3800,
        "master_highpass_hz": 140,
        "drive": 1.1,
        "peak": 0.78
    },
    "sfx_new_run.wav": {
        "duration_ms": 220,
        "tone": {"freq_a": 420, "freq_b": 560, "attack_ms": 2, "hold_ms": 12, "decay_ms": 160, "gain": 0.29},
        "bloom": {"freq": 760, "attack_ms": 5, "decay_ms": 110, "gain": 0.06},
        "air": {"gain": 0.01, "seed": 53},
        "master_lowpass_hz": 3400,
        "master_highpass_hz": 120,
        "drive": 1.12,
        "peak": 0.82
    },
    "sfx_continue.wav": {
        "duration_ms": 360,
        "tone": {"freq_a": 380, "freq_b": 520, "attack_ms": 3, "hold_ms": 20, "decay_ms": 240, "gain": 0.28},
        "bloom": {"freq": 740, "attack_ms": 8, "decay_ms": 180, "gain": 0.09},
        "air": {"gain": 0.01, "seed": 59},
        "master_lowpass_hz": 3200,
        "master_highpass_hz": 100,
        "drive": 1.12,
        "peak": 0.84
    }
}


def main():
    output_dir = Path("Tools/audio/final_synth")
    for filename, spec in EVENTS.items():
        samples = render_event(spec)
        write_wav(output_dir / filename, samples)
        print("[done] wrote %s" % (output_dir / filename))


if __name__ == "__main__":
    main()
