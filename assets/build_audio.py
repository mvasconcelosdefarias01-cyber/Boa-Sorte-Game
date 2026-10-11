"""Synthesize short, original PCM sound effects for the scenario 01 prototype."""
from __future__ import annotations

import json
import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "audio"
OUT.mkdir(exist_ok=True)
RATE = 22050


def render(name, duration, voice):
    random.seed(2401 + sum(map(ord, name)))
    samples = []
    prev_noise = 0.0
    count = int(RATE * duration)
    for i in range(count):
        t = i / RATE
        u = i / count
        noise = random.uniform(-1, 1)
        prev_noise = 0.75 * prev_noise + 0.25 * noise
        if voice == "wood":
            sig = (0.65 * noise + 0.3 * math.sin(2*math.pi*120*t)) * math.exp(-24*u)
            sig += 0.13 * math.sin(2*math.pi*60*t) * math.exp(-5*u)
        elif voice == "metal":
            sig = 0.32*noise*math.exp(-35*u)
            sig += (0.35*math.sin(2*math.pi*860*t)+0.18*math.sin(2*math.pi*1350*t))*math.exp(-5*u)
        elif voice == "earth":
            sig = 0.52*prev_noise*math.exp(-7*u)+0.11*noise*math.exp(-30*u)
        elif voice == "swoosh":
            env = math.sin(math.pi*u)**2
            sig = 0.42*noise*env+0.18*math.sin(2*math.pi*(260+500*u)*t)*env
        elif voice == "water":
            sig = 0.18*noise*math.sin(2*math.pi*8*t)**2
            sig += 0.1*math.sin(2*math.pi*(450+600*u)*t)*math.exp(-3*u)
        elif voice == "click":
            sig = 0.32*noise*math.exp(-35*u)+0.22*math.sin(2*math.pi*730*t)*math.exp(-20*u)
        elif voice == "chime":
            sig = (0.27*math.sin(2*math.pi*740*t)+0.19*math.sin(2*math.pi*1110*t))*math.exp(-5*u)
        elif voice == "crunch":
            sig = 0.3*noise*(math.sin(2*math.pi*10*t)**2)*math.exp(-4*u)
        else:
            sig = 0.2*prev_noise*math.exp(-11*u)
        # Short linear taper prevents clicks at the WAV boundary.
        taper = min(1.0, i/100, (count-i-1)/150)
        samples.append(max(-1, min(1, sig * max(0, taper))))
    path = OUT / (name + ".wav")
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(b"".join(struct.pack("<h", int(x*25000)) for x in samples))
    return {"path": f"res://assets/audio/{name}.wav", "duration_ms": round(duration*1000),
            "sample_rate": RATE, "channels": 1, "format": "PCM16"}


specs = {
    "tool_axe": (0.22, "wood"), "tool_pick": (0.34, "metal"),
    "tool_hoe": (0.25, "earth"), "tool_scythe": (0.28, "swoosh"),
    "tool_water": (0.45, "water"), "tool_hammer": (0.2, "wood"),
    "collect": (0.27, "chime"), "eat": (0.3, "crunch"),
    "ui_confirm": (0.1, "click"), "step_sand": (0.12, "earth"),
}
audio = {name: render(name, *spec) for name, spec in specs.items()}
(ROOT / "audio_manifest.json").write_text(json.dumps(audio, indent=2)+"\n", encoding="utf-8")
manifest_path = ROOT / "manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
manifest["audio"] = audio
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
print(f"Exported {len(audio)} WAV effects")
