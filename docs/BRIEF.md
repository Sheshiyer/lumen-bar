# LumenBar

A native macOS blue-light filter, PWM-free brightness controller, and circadian display suite with three automation modes and eleven preset types.

## Replaces
Third-party macOS blue-light utilities, f.lux, and macOS Night Shift for users who want local, offline control.

## Main jobs
1. **Switch modes and presets instantly**: Toggle `Automatic`, `Manual`, and `Paused` (including timed pause) and choose any of the 11 preset types (`Health`, `Sleep`, `Reading`, `Programming`, `Biohacker`, `Sunglasses`, `Dark`, `Movie`, `Overlay`, `Gaming`, `Custom`) in **LumenBar Max** or **LumenBar Gentle** intensity profiles.
2. **Fine-tune day, night, and sleep curves**: Adjust color temperature (`0K`–`10000K`), PWM-free brightness (`10%`–`120%`), color therapy overlays (12 tints), dark vignette, and screen effects (inversion, E-Ink grayscale). Optional approximate solar schedule from time zone.
3. **Protect eyes automatically**: 20-20-20 break overlay, auto-pause for color-critical apps, per-monitor filtering, menu bar and global shortcuts, smooth gamma cross-fades.

## Data
- `SavedFilterState`: mode, preset, `ProtectionTier`, manual/custom phase targets, schedule, overlay and vignette settings, rest timer, solar schedule flag, onboarding and menu bar preferences.
- `AppPauseRule`: bundle ID, app name, enabled state.
- Local JSON store under Application Support (or `APP_STORE` in `/tmp` for tests).

## Shape
Sidebar window (`Presets & Modes`, `Light & Schedule`, `Overlay & Effects`, `Eye Rest & Pausers`, `Display & Advanced`) + menu bar popover. macOS 26+ (compatible down to macOS 15+). Local data, offline, no accounts.

## System hooks
- Global shortcuts (`⌃⌥⌘P` pause, `⌃⌥⌘M` cycle preset, `⌃⌥⌘↑/↓` brightness, `⌃⌥⌘←/→` temperature)
- Menu bar extra with live Kelvin/brightness, favorites, timed pause
- URL scheme (`lumenbar://mode/…`, `lumenbar://preset/…`, `lumenbar://toggle-pause`)
- In-app self-test (`--selftest`) and snapshot runner (`APP_SNAPSHOT`)

## Reference
Display pipeline informed by REA reverse-engineering research and built with the BAMA native macOS workflow.

## Look
Premium-dark native SwiftUI: restrained neutrals, graphite default accent, `LumenSurface` cards, kelvin phase strips on preset tiles, circadian command-center homepage (status hero, recommended preset, gallery, collapsible adjust and verify), and system materials with accent used for selection and primary actions only.

## Not in version one
- Cloud accounts, telemetry, or license paywalls
- Hardware webcam blink-rate recording
- Windows / Linux builds
