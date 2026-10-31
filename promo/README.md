# LumenBar promo films

Two narrated product films built with [HyperFrames](https://github.com/heygen-com/hyperframes)
(HTML + GSAP, rendered frame by frame to MP4). The narration comes from macOS `say`. The music
bed is synthesized with FFmpeg. FFmpeg also mixes and muxes the audio.

| Film | Folder | Length | Size |
|---|---|---|---|
| Onboarding walkthrough | `onboarding/` | 39.9 s | 1920×1080, 30 fps |
| Marketing explainer | `explainer/` | 69.6 s | 1920×1080, 30 fps |

## Build outputs (git-ignored, regenerate them)

- `out/lumenbar-onboarding.mp4`
- `out/lumenbar-explainer.mp4`
- `out/poster-explainer.png`: the end card at 67 s

`build/` holds the intermediates: voice lines (`.aiff`/`.wav`), `vo.wav`, `music.wav`, `mix.wav`,
`timing.json`, and the silent HyperFrames renders.

## Requirements

- Node 22+ and FFmpeg/ffprobe on `PATH` (`/opt/homebrew/bin`)
- macOS `say` with the voice **Samantha (English (US))**
- Python 3 (standard library only)

The HyperFrames CLI runs through `npx` and is pinned to `hyperframes@0.8.223`. No global install
is needed. The first render downloads a headless Chrome into `~/.cache/hyperframes`.

## Commands

```bash
cd promo

# 1. Narration + music + mix, and scene timing (build/<film>/timing.json)
python3 scripts/make_films.py

# 2. Lint + runtime/layout/contrast checks for both films
npm run check

# 3. Render both films, mux audio, write the poster
zsh scripts/render.sh            # same as: npm run render
```

Preview one film in the browser editor:

```bash
cd promo/onboarding && npx --yes hyperframes@0.8.223 preview
```

Pull still frames to review:

```bash
cd promo/onboarding && npx --yes hyperframes@0.8.223 snapshot --at 1,8,18,26,35
```

## Timing

The voice drives the timing. `scripts/make_films.py` places each line 0.45 s after the last one
and prints the schedule. Each scene starts 0.35 s before its line. The `data-start` and
`data-duration` values in each `index.html` come from that schedule. If you change a line, run
the script again and copy the new scene starts into the HTML.

## Audio

- Voice: `say -v "Samantha (English (US))" -r 185`, converted to 48 kHz WAV. No Premium or
  Enhanced English voice is installed on this Mac, so Samantha was the cleanest option. To use a
  different voice, install one under System Settings → Accessibility → Spoken Content and change
  `VOICE` in `scripts/make_films.py`.
- Music: an A-minor-9 pad made of slowly beating sine pairs, high-passed at 70 Hz, low-passed at
  900 Hz, with a sine-shaped fade in and out. It sits at −20 dB under the voice.
- Measured loudness of both finals: about −16.6 LUFS integrated. Nobody listened to the mix on
  speakers.

## Script

### Onboarding

1. **Hello.** Welcome to LumenBar. Tonight, your Mac stops blasting blue light.
2. **Modes.** LumenBar is a native blue-light filter. Three modes: automatic, manual, or paused,
   with a timed pause of fifteen minutes, one hour, or until morning.
3. **Presets.** Pick one of eleven presets. Health, Sleep, Reading, Programming, and more, in Max
   or Gentle intensity.
4. **Displays.** Every display can follow the main look, turn off, or keep its own Kelvin and
   brightness. Plug a monitor in, and LumenBar re-applies.
5. **You're set.** The twenty-twenty-twenty timer covers the screen when it is time to look away,
   with a quiet sound cue. You are set. Everything stays on this Mac.

### Explainer

1. **Problem.** At night, a bright screen is still noon. Blue light keeps you awake.
2. **Fix.** LumenBar warms your display on a hardware gamma curve, from ten thousand Kelvin
   toward deep amber, with smooth cross-fades.
3. **Modes.** Three modes. Automatic follows a day, night, and sleep curve. Manual holds your
   look. Paused returns to neutral, for fifteen minutes, an hour, or until morning.
4. **Presets.** Eleven presets, from Health and Sleep to Reading, Programming, Gaming, and
   Custom. Each in Max or Gentle.
5. **Schedule and effects.** The schedule previews your whole day, with a solar estimate and no
   location permission. Add a tint, a vignette, or E-Ink grayscale.
6. **Multi-monitor (new).** New: a multi-monitor desk. Each display can follow the main look,
   turn off, or keep its own Kelvin and brightness. Plug one in, and LumenBar re-applies.
7. **Eye rest.** A twenty-twenty-twenty timer covers the screen for a real break, with quiet
   sound cues. Color-critical apps auto-pause the filter.
8. **Menu bar.** Live Kelvin in the menu bar. Control-option-command-P pauses.
   Control-option-command-M cycles presets.
9. **Privacy + CTA.** No account. No cloud. No telemetry. LumenBar for macOS.

## Notes

- Product shots are copies of `docs/screenshots/*-dark.png` in each film's `assets/shots/`.
  Each film folder is a standalone HyperFrames project, because the renderer serves only files
  inside the project directory.
- None of the screenshots shows the new multi-monitor controls. The explainer's multi-monitor
  beat uses the existing Display & Advanced screen, which shows one connected display. The
  onboarding beat uses three simple display cards. When `tools/snap.sh` captures the new
  per-display UI, swap that screenshot in.
- No vertical (1080×1920) cut was made. These layouts are side-by-side 16:9 designs, so a
  vertical cut needs its own layout. Changing the render flag alone won't do it.
