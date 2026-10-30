# LumenBar

A native macOS blue-light filter, PWM-free brightness controller, and circadian display suite featuring all 3 Iris automation modes and all 11 preset types.

## Replaces
Iris / Iris Pro (macOS), f.lux, and macOS Night Shift.

## Main jobs
1. **Switch Modes & Presets Instantly**: Toggle between `Automatic`, `Manual`, and `Paused` modes and choose any of the 11 Iris preset types (`Health`, `Sleep`, `Reading`, `Programming`, `Biohacker`, `Sunglasses`, `Dark`, `Movie`, `Overlay`, `Gaming`, `Custom`) in either **Iris Pro** or **Iris Standard** intensity profiles.
2. **Fine-Tune Day, Night & Sleep Display Curves**: Adjust Color Temperature (`0K` pure red to `10000K` cool blue), PWM-free Brightness (`10%` to `120%` Movie gamma boost), Color Therapy Overlay pigments (12 tints), Dark mode radial vignette spotlight, and screen effects (Inversion, E-Ink Grayscale).
3. **Protect Eyes Automatically All Day**: Run a 20-20-20 Eye Rest Timer, auto-pause when color-critical apps (Photoshop, Figma, Blender, Final Cut Pro) are frontmost, and control per-monitor filtering from the menu bar or global keyboard shortcuts.

## Data
- `FilterProfile`: Active `AutomationMode` (`automatic`, `manual`, `paused`), active `FilterPresetType` (11 presets), `IrisTier` (`pro`, `standard`), Day/Night/Sleep temperature (`0–10000K`) and brightness (`10–120%`), schedule hours, transition duration, overlay pigment (`12` tints), vignette opacity/radius, gamma fixer exponent, and inversion/grayscale flags.
- `AppPauseRule`: Bundle identifier, app name, and enabled state for automatic color-critical app pausing.
- `RestTimerState`: Work interval (minutes), break duration (seconds), enabled flag, and countdown status.

## Shape
Sidebar window (`Presets & Modes`, `Light & Schedule`, `Overlay & Effects`, `Eye Rest & Pausers`, `REA & Diagnostics`) + Menu Bar Extra popover, macOS 26 or later (compatible down to macOS 15+).
Local data. Works offline. No accounts.

## System hooks
- Global shortcuts (`Control+Option+Command+P` pause/resume, `Control+Option+Command+M` cycle preset, `Control+Option+Command+Up/Down` brightness, `Control+Option+Command+Left/Right` temperature)
- Menu bar item (`MenuBarExtra` with live Kelvin & Brightness badge + quick controls)
- URL scheme (`lumenbar://mode/<name>`, `lumenbar://preset/<name>`, `lumenbar://toggle-pause`)
- In-app CLI / self-test (`--self-test`) and snapshot runner (`APP_SNAPSHOT`)

## Reference
Iris Pro v1.2.2 for macOS (`https://iristech.co/free-blue-light-filter-app/`), reverse-engineered with REA (`https://github.com/morluto/rea`) and architected with BAMA (`https://github.com/daveebbelaar/bama`).

## Look
Native macOS SwiftUI design with warm amber circadian accents, a live interactive display preview card, 24-hour circadian solar curve visualizer, and instant one-click preset cards.

## Not in version one
- Cloud accounts, telemetry, or license-key paywalls (all Iris Pro features are unlocked locally for free)
- Hardware webcam blink-rate recording
- Windows / Linux builds
