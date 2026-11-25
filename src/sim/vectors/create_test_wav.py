#!/usr/bin/env python3
"""Genera WAV PCM mono signed 16-bit deterministas para pruebas futuras."""

import argparse
import math
import struct
import wave
from pathlib import Path


def pcm16(value: float) -> int:
    value = max(-1.0, min(1.0, value))
    if value < 0:
        return int(value * 32768)
    return int(value * 32767)


def write_wave(path: Path, sample_rate: int, seconds: float, tone_hz: float,
               pattern: str, amplitude: float) -> None:
    frame_count = int(sample_rate * seconds)
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(sample_rate)

        frames = bytearray()
        for n in range(frame_count):
            t = n / sample_rate
            if pattern == "sine":
                sample = amplitude * math.sin(2.0 * math.pi * tone_hz * t)
            elif pattern == "square":
                sample = amplitude if math.sin(2.0 * math.pi * tone_hz * t) >= 0 else -amplitude
            elif pattern == "impulse":
                sample = amplitude if n == sample_rate // 100 else 0.0
            elif pattern == "silence":
                sample = 0.0
            elif pattern == "extremes":
                values = (32767, -32768, 32767, -32768)
                sample = values[n % len(values)] / 32768.0
            else:
                raise ValueError(f"patron no soportado: {pattern}")

            if pattern == "extremes":
                value = int(sample * 32768)
            else:
                value = pcm16(sample)
            frames.extend(struct.pack("<h", value))

        wav.writeframes(frames)


def main() -> None:
    parser = argparse.ArgumentParser(description="Genera WAVs PCM 16-bit para pruebas de audio")
    parser.add_argument("--out", type=Path, default=Path("test_vectors"))
    parser.add_argument("--seconds", type=float, default=2.0)
    parser.add_argument("--tone-hz", type=float, default=440.0)
    parser.add_argument("--amplitude", type=float, default=0.5)
    parser.add_argument("--pattern", choices=("sine", "square", "impulse", "silence", "extremes"),
                        default="sine")
    parser.add_argument("--rate", action="append", type=int,
                        choices=(8000, 16000, 44100, 48000),
                        default=None)
    args = parser.parse_args()

    rates = args.rate or [8000, 16000, 44100]
    args.out.mkdir(parents=True, exist_ok=True)

    for rate in rates:
        path = args.out / f"pcm16_{args.pattern}_{rate}hz.wav"
        write_wave(path, rate, args.seconds, args.tone_hz, args.pattern, args.amplitude)
        print(path)


if __name__ == "__main__":
    main()
