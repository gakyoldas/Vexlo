#!/usr/bin/env python3
import argparse
import json
import math
import struct
import wave
from pathlib import Path


WINDOW_MS = 10


def read_wav(path: Path) -> tuple[list[float], int]:
    with wave.open(str(path), "rb") as handle:
        channels = handle.getnchannels()
        sample_width = handle.getsampwidth()
        frame_rate = handle.getframerate()
        frame_count = handle.getnframes()
        frames = handle.readframes(frame_count)

    if sample_width != 2:
        raise SystemExit(f"{path} is not 16-bit PCM WAV.")

    integers = struct.unpack(f"<{frame_count * channels}h", frames)
    mono = []
    for index in range(0, len(integers), channels):
        frame = integers[index:index + channels]
        mono.append(sum(frame) / len(frame) / 32768.0)
    return mono, frame_rate


def write_wav(path: Path, samples: list[float], frame_rate: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    clamped = [max(-1.0, min(1.0, sample)) for sample in samples]
    integers = [int(round(sample * 32767.0)) for sample in clamped]
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(frame_rate)
        handle.writeframes(struct.pack(f"<{len(integers)}h", *integers))


def window_rms(samples: list[float], start: int, stop: int) -> float:
    chunk = samples[start:stop]
    if not chunk:
        return 0.0
    return math.sqrt(sum(sample * sample for sample in chunk) / len(chunk))


def find_bounds(samples: list[float], frame_rate: int) -> tuple[int, int]:
    total_frames = len(samples)
    window = max(1, int(frame_rate * WINDOW_MS / 1000))
    full_rms = window_rms(samples, 0, total_frames)
    threshold = max(full_rms * 0.18, 0.0025)

    start_frame = 0
    for frame in range(0, total_frames, window):
        if window_rms(samples, frame, min(total_frames, frame + window)) > threshold:
            start_frame = frame
            break

    end_frame = total_frames
    for frame in range(total_frames - window, -1, -window):
        if window_rms(samples, max(0, frame), min(total_frames, frame + window)) > threshold:
            end_frame = min(total_frames, frame + window)
            break

    return start_frame, max(start_frame + 1, end_frame)


def clamp_bounds(start_frame: int, end_frame: int, frame_rate: int, trim_range_ms: dict | None) -> tuple[int, int]:
    if trim_range_ms is None:
        return start_frame, end_frame
    min_frames = int(frame_rate * trim_range_ms["min"] / 1000)
    max_frames = int(frame_rate * trim_range_ms["max"] / 1000)
    length = end_frame - start_frame

    if length < min_frames:
        deficit = min_frames - length
        start_frame = max(0, start_frame - deficit // 2)
        end_frame = start_frame + min_frames
    if (end_frame - start_frame) > max_frames:
        end_frame = start_frame + max_frames
    return start_frame, end_frame


def ms_to_frames(ms: float, frame_rate: int) -> int:
    return max(0, int(round(frame_rate * ms / 1000.0)))


def db_to_gain(db: float) -> float:
    return math.pow(10.0, db / 20.0)


def apply_fades(samples: list[float], frame_rate: int, fade_in_ms: float, fade_out_ms: float) -> list[float]:
    output = samples[:]
    fade_in_frames = ms_to_frames(fade_in_ms, frame_rate)
    fade_out_frames = ms_to_frames(fade_out_ms, frame_rate)
    total_frames = len(output)

    for frame in range(min(fade_in_frames, total_frames)):
        gain = frame / max(1, fade_in_frames)
        output[frame] *= gain

    for offset in range(min(fade_out_frames, total_frames)):
        frame = total_frames - 1 - offset
        gain = offset / max(1, fade_out_frames)
        output[frame] *= gain

    return output


def lowpass(samples: list[float], frame_rate: int, cutoff_hz: float | None) -> list[float]:
    if not cutoff_hz or cutoff_hz <= 0:
        return samples[:]
    dt = 1.0 / frame_rate
    rc = 1.0 / (2.0 * math.pi * cutoff_hz)
    alpha = dt / (rc + dt)
    output = []
    previous = 0.0
    for sample in samples:
        previous = previous + alpha * (sample - previous)
        output.append(previous)
    return output


def highpass(samples: list[float], frame_rate: int, cutoff_hz: float | None) -> list[float]:
    if not cutoff_hz or cutoff_hz <= 0:
        return samples[:]
    dt = 1.0 / frame_rate
    rc = 1.0 / (2.0 * math.pi * cutoff_hz)
    alpha = rc / (rc + dt)
    output = []
    previous_output = 0.0
    previous_input = 0.0
    for sample in samples:
        current = alpha * (previous_output + sample - previous_input)
        output.append(current)
        previous_output = current
        previous_input = sample
    return output


def soft_clip(samples: list[float], drive: float) -> list[float]:
    if drive <= 0:
        return samples[:]
    return [math.tanh(sample * drive) / math.tanh(drive) for sample in samples]


def prepare_layer(layer: dict, frame_rate: int | None) -> tuple[list[float], int]:
    samples, source_rate = read_wav(Path(layer["source"]))
    if frame_rate is not None and source_rate != frame_rate:
        raise SystemExit(f"Mismatched sample rate in {layer['source']}: {source_rate} != {frame_rate}")

    start_frame, end_frame = find_bounds(samples, source_rate)
    start_frame += ms_to_frames(layer.get("trim_start_ms", 0), source_rate)
    end_frame -= ms_to_frames(layer.get("trim_end_ms", 0), source_rate)
    end_frame = max(start_frame + 1, end_frame)

    if "max_duration_ms" in layer:
        max_frames = ms_to_frames(layer["max_duration_ms"], source_rate)
        end_frame = min(end_frame, start_frame + max_frames)

    clipped = samples[start_frame:end_frame]
    filtered = highpass(clipped, source_rate, layer.get("highpass_hz"))
    filtered = lowpass(filtered, source_rate, layer.get("lowpass_hz"))
    gained = [sample * db_to_gain(layer.get("gain_db", 0.0)) for sample in filtered]
    faded = apply_fades(
        gained,
        source_rate,
        layer.get("fade_in_ms", 2),
        layer.get("fade_out_ms", 12),
    )
    return faded, source_rate


def compose_event(entry: dict) -> tuple[list[float], int]:
    prepared_layers: list[tuple[list[float], int, int]] = []
    frame_rate = None
    total_frames = 0

    for layer in entry["layers"]:
        samples, source_rate = prepare_layer(layer, frame_rate)
        if frame_rate is None:
            frame_rate = source_rate
        offset_frames = ms_to_frames(layer.get("offset_ms", 0), frame_rate)
        prepared_layers.append((samples, frame_rate, offset_frames))
        total_frames = max(total_frames, offset_frames + len(samples))

    if frame_rate is None:
        raise SystemExit(f"No layers configured for {entry['event']}")

    mixed = [0.0] * total_frames
    for samples, _, offset_frames in prepared_layers:
        for index, sample in enumerate(samples):
            mixed[offset_frames + index] += sample

    if "master_highpass_hz" in entry:
        mixed = highpass(mixed, frame_rate, entry["master_highpass_hz"])
    if "master_lowpass_hz" in entry:
        mixed = lowpass(mixed, frame_rate, entry["master_lowpass_hz"])

    mixed = soft_clip(mixed, entry.get("soft_clip_drive", 1.4))

    peak = max((abs(sample) for sample in mixed), default=1.0)
    target_peak = float(entry.get("target_peak", 0.92))
    if peak > 0:
        gain = target_peak / peak
        mixed = [sample * gain for sample in mixed]

    start_frame, end_frame = find_bounds(mixed, frame_rate)
    start_frame, end_frame = clamp_bounds(start_frame, end_frame, frame_rate, entry.get("trim_range_ms"))
    mixed = mixed[start_frame:end_frame]
    mixed = apply_fades(
        mixed,
        frame_rate,
        entry.get("master_fade_in_ms", 3),
        entry.get("master_fade_out_ms", 16),
    )
    return mixed, frame_rate


def main() -> int:
    parser = argparse.ArgumentParser(description="Compose layered short-form WAV SFX from generated candidates.")
    parser.add_argument(
        "--plan",
        type=Path,
        default=Path("Tools/audio/audio_compose_plan.json"),
        help="Composition plan JSON.",
    )
    parser.add_argument(
        "--event",
        action="append",
        default=[],
        help="Optional event(s) to compose.",
    )
    parser.add_argument("--force", action="store_true", help="Overwrite existing outputs.")
    args = parser.parse_args()

    plan = json.loads(args.plan.read_text(encoding="utf-8"))
    requested = set(args.event)

    for entry in plan["events"]:
        event_name = entry["event"]
        if requested and event_name not in requested:
            continue
        output_path = Path(entry["output"])
        if output_path.exists() and not args.force:
            raise SystemExit(f"Refusing to overwrite existing file: {output_path}")
        samples, frame_rate = compose_event(entry)
        write_wav(output_path, samples, frame_rate)
        duration_ms = round(len(samples) * 1000 / frame_rate, 1)
        print(f"[done] {event_name} -> {output_path} ({duration_ms} ms)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
