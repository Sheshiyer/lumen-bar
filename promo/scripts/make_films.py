#!/usr/bin/env python3
"""Rebuild narration, music, and the final mix for both films.

Voice: macOS `say`, Samantha (English (US)) at 185 wpm, converted to 48 kHz WAV.
Music: a synthesized A-minor pad (layered beating sines, lowpassed, faded).
Mix: voice full level, music at -20 dB under it.
"""
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOICE = "Samantha (English (US))"
RATE = "185"
LEAD, GAP, TAIL = 0.6, 0.45, 1.8

FILMS = {
    "onboarding": [
        ("hello", "Welcome to LumenBar. Tonight, your Mac stops blasting blue light."),
        ("modes", "LumenBar is a native blue-light filter. Three modes: automatic, manual, or paused, with a timed pause of fifteen minutes, one hour, or until morning."),
        ("presets", "Pick one of eleven presets. Health, Sleep, Reading, Programming, and more, in Max or Gentle intensity."),
        ("displays", "Every display can follow the main look, turn off, or keep its own Kelvin and brightness. Plug a monitor in, and LumenBar re-applies."),
        ("set", "The twenty-twenty-twenty timer covers the screen when it is time to look away, with a quiet sound cue. You are set. Everything stays on this Mac."),
    ],
    "explainer": [
        ("problem", "At night, a bright screen is still noon. Blue light keeps you awake."),
        ("fix", "LumenBar warms your display on a hardware gamma curve, from ten thousand Kelvin toward deep amber, with smooth cross-fades."),
        ("modes", "Three modes. Automatic follows a day, night, and sleep curve. Manual holds your look. Paused returns to neutral, for fifteen minutes, an hour, or until morning."),
        ("presets", "Eleven presets, from Health and Sleep to Reading, Programming, Gaming, and Custom. Each in Max or Gentle."),
        ("schedule", "The schedule previews your whole day, with a solar estimate and no location permission. Add a tint, a vignette, or E-Ink grayscale."),
        ("displays", "New: a multi-monitor desk. Each display can follow the main look, turn off, or keep its own Kelvin and brightness. Plug one in, and LumenBar re-applies."),
        ("rest", "A twenty-twenty-twenty timer covers the screen for a real break, with quiet sound cues. Color-critical apps auto-pause the filter."),
        ("menubar", "Live Kelvin in the menu bar. Control-option-command-P pauses. Control-option-command-M cycles presets."),
        ("privacy", "No account. No cloud. No telemetry. Download LumenBar free on GitHub."),
    ],
}


def run(cmd):
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def duration(path):
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        check=True, capture_output=True, text=True,
    ).stdout.strip()
    return float(out)


def main():
    for film, lines in FILMS.items():
        d = ROOT / "build" / film
        d.mkdir(parents=True, exist_ok=True)
        t = LEAD
        sched = []
        for i, (name, text) in enumerate(lines, 1):
            aiff, wav = d / f"{i:02d}.aiff", d / f"{i:02d}.wav"
            run(["say", "-v", VOICE, "-r", RATE, "-o", str(aiff), text])
            run(["ffmpeg", "-y", "-i", str(aiff), "-ar", "48000", "-ac", "1", str(wav)])
            dur = duration(wav)
            sched.append({"name": name, "text": text, "voice_start": round(t, 3), "voice_dur": round(dur, 3)})
            t += dur + GAP
        total = round(sched[-1]["voice_start"] + sched[-1]["voice_dur"] + TAIL, 3)
        for i, s in enumerate(sched):
            s["scene_start"] = 0.0 if i == 0 else round(s["voice_start"] - 0.35, 3)
        for i, s in enumerate(sched):
            end = sched[i + 1]["scene_start"] if i + 1 < len(sched) else total
            s["scene_dur"] = round(end - s["scene_start"], 3)
        (d / "timing.json").write_text(json.dumps({"total": total, "scenes": sched}, indent=2))

        cmd = ["ffmpeg", "-y"]
        for i in range(1, len(sched) + 1):
            cmd += ["-i", str(d / f"{i:02d}.wav")]
        parts = [f"[{i}:a]adelay={int(s['voice_start'] * 1000)}:all=1[a{i}]" for i, s in enumerate(sched)]
        mix = "".join(f"[a{i}]" for i in range(len(sched)))
        graph = ";".join(parts) + f";{mix}amix=inputs={len(sched)}:normalize=0,apad=whole_dur={total}[o]"
        run(cmd + ["-filter_complex", graph, "-map", "[o]", "-t", str(total), "-ar", "48000", "-ac", "1", str(d / "vo.wav")])

        tones = [(110, 0.30), (164.81, 0.22), (196.0, 0.18), (246.94, 0.14), (261.63, 0.10), (329.63, 0.06)]
        expr = "0.5*(" + "+".join(f"{a}*sin(2*PI*{f:.2f}*t)*sin(2*PI*{f * 1.004:.2f}*t)" for f, a in tones) + f")*pow(sin(PI*t/{total})\\,0.35)"
        run(["ffmpeg", "-y", "-f", "lavfi", "-i", f"aevalsrc='{expr}':s=48000:d={total}",
             "-af", "lowpass=f=900,highpass=f=70,alimiter=limit=0.9", str(d / "music.wav")])
        run(["ffmpeg", "-y", "-i", str(d / "vo.wav"), "-i", str(d / "music.wav"),
             "-filter_complex", "[1:a]volume=-20dB[m];[0:a][m]amix=inputs=2:normalize=0:duration=longest[o]",
             "-map", "[o]", "-ar", "48000", "-ac", "2", str(d / "mix.wav")])
        print(f"{film}: {total}s")


if __name__ == "__main__":
    main()
