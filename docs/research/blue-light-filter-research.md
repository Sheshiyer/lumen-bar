# Blue Light Filter & Circadian Display Research (`LumenBar`)

Research for `LumenBar`. Done 2026-10-31.
`[V]` verified in a primary source or shipped binary (with URL or REA Evidence ID), `[K]` from domain knowledge, `[U]` unverified, test first.

## 1. Executive Summary: BAMA + IrisTech + REA Synthesis

This research combines three pillars requested for `LumenBar`:
1. **[daveebbelaar/bama](https://github.com/daveebbelaar/bama) (Build Any Mac App)**: A 21-skill native macOS engineering framework targeting **macOS 26+**, **Swift 6.2 (`MainActor` default isolation)**, **SwiftData**, zero Xcode GUI (`Package.swift` + `build.sh`), 4 pt layout grid (`Grid.swift`), `MenuBarExtra` + main window + global Carbon hotkeys + URL scheme (`lumenbar://`), unit testing (`LumenBarKitTests`), and automated light/dark window snapshots (`APP_SNAPSHOT`). `[V](https://github.com/daveebbelaar/bama)`
2. **[IrisTech](https://iristech.co/free-blue-light-filter-app/) (`Iris` & `Iris Pro` v1.2.2)**: Comprehensive product & clinical feature analysis of Iris's **3 Automation Modes** (`Automatic`, `Manual`, `Paused`), **9 Canonical Preset Types** (`Health`, `Sleep`, `Reading`, `Programming`, `Biohacker`, `Sunglasses`, `Dark`, `Movie`, `Overlay`) plus **2 Bonus v1.1.0+ Types** (`Gaming`, `Custom`), **PWM-free software brightness dimming**, **12 Color Therapy Overlay pigments**, **Eye Rest / 20-20-20 Timer**, and **App Color Pausers**. `[V](https://iristech.co/type-dropdown-help/)`
3. **[morluto/rea](https://github.com/morluto/rea) (Reverse Engineer Anything)**: Direct static binary reverse engineering of the official macOS `Iris.app` (`Iris-1.2.2-OSX.zip`, Mach-O `x86_64` SHA-256 `8b8dd0534defc40b619abe3a004e59c54b9177c2cfd59fa4c79fd4b0f3936d4e`) using Hopper via the REA MCP server. Every gamma equation, LUT table, overlay window flag, and color-effect mechanism below is tied to a cryptographic REA Evidence ID.

---

## 2. REA Binary Reverse-Engineering Ledger (`Iris.app` v1.2.2 for macOS)

| Subsystem | Symbol / Address in `Iris.app` | REA Evidence ID | Verified Mechanism in Shipped Binary |
| --- | --- | --- | --- |
| **Binary Identity** | `Iris.app/Contents/MacOS/Iris` (`x86_64`, UUID `71B60B14-0D8D-3286-8F7C-0DE8C8907CC3`) | `ev_aa414dc1177daa2746ee14124be5910f2fae3144bb9e0e625be534d053a38823` | Qt5 C++ binary linking `CoreGraphics`, `AppKit`, `IOKit`, `OpenGL`. |
| **CoreGraphics Gamma Transfer** | `MacGamma::set_temperature_for_display(int, ColorSettings const*)` @ `0x10011ab50` | `ev_dca6679a56500255bb4840677dab3774467188d5eca1f93ee75609f5e7dfdb10` | Allocates 3 float arrays (`r12 = capacity` from `CGDisplayGammaTableCapacity`, typically 256). Initializes normalized ramp `i / N` (or inverted `1.0 - (i / N)` when `is_gamma_inverted` is true at offset `0x18`), fills via `ColorRamp::color_ramp_fill_float`, and calls `CGSetDisplayTransferByTable(displayID, capacity, redTable, greenTable, blueTable)`. |
| **Multi-Monitor Dispatch** | `MacGamma::set_temperature(...)` @ `0x10011a980` | `ev_5d060bce77695c2e5e7d85bb00ad9a2c09858388c7588a283631c1d8d947c48c` | Iterates active displays, skips excluded monitors in per-monitor settings list (restoring them to `6500K / 100%`), and calls `set_temperature_for_display`. |
| **Kelvin-to-RGB Power Law** | `ColorRamp::color_ramp_fill_float(...)` @ `0x10011bde0` & `ColorRamp::interpolate_color(...)` @ `0x10011bae0` | `ev_b3a5fa95eb6683bed54d00dd66d05b5f43ef01ea0bbf05e4f4e63d277ee2d733`, `ev_10610aa1b02a372f68be76e6cc4c3a3c99672e4ff8630e6efb7975d63daaac56` | Computes `step = K / 100`, `frac = (K % 100) / 100.0`, linearly interpolates `(R_k, G_k, B_k)` between `table[step]` and `table[step + 1]`, and applies per-entry gamma power law: `table[i] = pow(brightness * ramp[i] * channelMultiplier, 1.0 / gammaFixer)`. |
| **101-Step Kelvin LUT (0K–10000K)** | `ColorRamp` static float table @ `0x100be0d50` (1,212 bytes = `101 * 3 * sizeof(float)`) | `ev_d2dfdacae728857e071e49420542833a310bd6b3a96de1e6cfc2f3a05a7659f3` | Exact 101-entry `(R, G, B)` float triplets from `0K` (`1.0, 0.0, 0.0` pure red—zero blue and zero green) through `1900K` (`1.0, 0.519, 0.0` candle), `3400K` (`1.0, 0.774, 0.520` Iris Pro Night), `5000K` (`1.0, 0.908, 0.814` Iris Pro Day), `6500K` (`1.0, 1.0, 1.0` neutral daylight) up to `10000K` (`0.790, 0.865, 1.0`). |
| **Screen Effects & Grayscale / Inversion** | `MacColorEffects::set_fullscreen_color_effect(int)` @ `0x100024080` | `ev_87db88b3822628d096de40da67fe2aced8b022304aecda6890ac3ba11aa687d2` | Effect `1` (Inversion: `Programming` / `Biohacker`) inverts the gamma ramp `1.0 - (i / N)` in `MacGamma`; Effect `2` (Grayscale: `Reading`) invokes `CGDisplayForceToGray` or luminance-equalized LUT/overlay; Effect `5` (Negative Grayscale) combines both. |
| **Overlay Window & Spaces Behavior** | `set_always_on_top(unsigned long long)` @ `0x10000b540` & `can_join_all_spaces` @ `0x10000b610` | `ev_a643d0754e9b8cf94b56cb485903ef92d5e78a4df87b65609f6ff4c624c43954`, `ev_248c0a6e78fdf2ca9a7424f96d1fea49ab2c969fa44f09678efd9bac41e95a36` | Sets `[window setIgnoresMouseEvents:YES]`, `[window setLevel:CGWindowLevelForKey(kCGOverlayWindowLevelKey)]` (`0x13`), `[window setStyleMask:0]`, `[window setOpaque:NO]`, `[window setHidesOnDeactivate:NO]`, `[window setCanHide:NO]`, and `[window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces]`. |
| **12 Color Therapy Overlay Pigments** | `OverlayScreen::get_color_values(int*, int*, int*, int)` @ `0x10005a880` | `ev_397c88d4527b5ec76c55bb42196ec38a80810654e9d3281097d73cbf8e652301` | Switch table over 12 color therapy tints scaled by `(100 - screenDim) / 100`: Green (`#00FF00`), Turquoise (`#40E0D0`), Blue (`#0000FF`), Indigo (`#4B0082`), Violet (`#EE82EE`), Purple (`#800080`), Magenta (`#FF00FF`), Scarlet (`#FF2400`), Red (`#FF0000`), Orange (`#FFA500`), Yellow (`#FFFF00`), Lemon (`#FFF44F`). |

---

## 3. Market & User Sentiment Analysis

| App | Price & Platform | People Like | People Dislike | Sources |
| --- | --- | --- | --- | --- |
| **Iris / Iris Pro** | Free trial / $15 lifetime (macOS, Windows, Linux) | 9+ specialized presets (`Health`, `Sleep`, `Reading`, `Programming`, `Biohacker`, `Sunglasses`, `Dark`, `Movie`, `Overlay`), goes down to `0K` pure red (cuts green as well as blue), PWM-free software brightness, 20-20-20 rest timer. | Older Qt UI feels non-native on macOS; activation/licensing friction; Intel `x86_64` binary requires Rosetta on Apple Silicon. | `[V](https://iristech.co/type-dropdown-help/)`, `[V](https://iristech.co/iris-changelog/)` |
| **f.lux** | Free (macOS, Windows) | Set-and-forget solar curve, Bedtime mode, app-specific disable list. | Fewer specialized modes (no E-ink Reading, Dark vignette, or Color Therapy overlay); weaker green-channel suppression at night compared to Iris `Sleep`/`Biohacker`. | `[V](https://iristech.co/iris/)`, `[V](https://iristech.co/type-dropdown-help/#comments)` |
| **Night Shift (macOS built-in)** | Built-in (macOS) | Zero install, native TCC integration. | Very mild warm shift (minimum ~4100K); no brightness control, no grayscale/inversion, no menu bar slider for Kelvin, no app auto-pause. | `[K]` |
| **Lunar** | Freemium / $23 (macOS) | Native SwiftUI look, hardware DDC + software gamma dimming, multi-display support. | Focused primarily on hardware brightness rather than circadian blue-light presets and color-therapy overlays. | `[K]` |

---

## 4. Complete Mode & Preset Matrix for `LumenBar`

### 4.1 The 3 Automation Modes (`AutomationMode`)
1. **Automatic (`automatic`)**: Detects time of day (`Day`, `Night`, `Sleep` phases) with configurable schedule or solar curve and smoothly interpolates Color Temperature (K) and Brightness (%) across transitions. `[V](https://iristech.co/welcome-to-iris/)`
2. **Manual (`manual`)**: Locks a single user-chosen or preset-driven Color Temperature, Brightness, and Screen Effect all day and night. `[V](https://iristech.co/welcome-to-iris/)`
3. **Paused (`paused`)**: Temporarily suspends all gamma LUT and overlay changes (or pauses for 1 hour / until tomorrow / while a color-critical app is frontmost) and restores the display's calibrated `6500K / 100%` state. `[V](https://iristech.co/welcome-to-iris/)`

### 4.2 All 11 Preset Types (`FilterPresetType` — 9 Canonical Iris Types + 2 v1.1.0 Types, with both Standard & Pro Profiles)

| # | Preset Type | Specialty | Iris Standard (Day / Night / Sleep) | Iris Pro (Day / Night / Sleep) | Special Effect / Render Pipeline |
| --- | --- | --- | --- | --- | --- |
| 1 | **Health** | General Eye Health & Circadian Balance | `6000K 100%` / `4400K 85%` / `3700K 80%` | `5000K 100%` / `3400K 80%` / `2700K 75%` | Exact Iris Kelvin LUT + PWM-free software brightness |
| 2 | **Sleep** | Zero Blue & Green Light (Max Melatonin) | `0K 100%` / `0K 85%` / `0K 80%` | `0K 100%` / `0K 80%` / `0K 75%` | `0K` pure red (`R=1.0, G=0.0, B=0.0`) removes 100% of blue & green light |
| 3 | **Reading** | E-Ink Grayscale + Warm Filter | `6000K 100%` / `4400K 85%` / `3700K 80%` | `5000K 100%` / `3400K 80%` / `2700K 75%` | Warm LUT + E-Ink Grayscale effect (reduces subpixel flicker) |
| 4 | **Programming** | High-Contrast Dark Inversion | `6000K 100%` / `4400K 85%` / `3700K 80%` | `5000K 100%` / `3400K 80%` / `2700K 75%` | Inverted gamma ramp `1.0 - (i / N)` + warm blue-light cut |
| 5 | **Biohacker** | Sleep (`0K` Red) + Programming Inversion | `0K 100%` / `0K 85%` / `0K 80%` | `0K 100%` / `0K 80%` / `0K 75%` | Inverted gamma ramp + `0K` pure red channel (black background with deep red text) |
| 6 | **Sunglasses** | Flicker-Free Dimming for Blue-Blocker Glasses | `6500K 100%` / `6500K 75%` / `6500K 65%` | `6500K 100%` / `6500K 75%` / `6500K 65%` | Preserves true `6500K` colors while dimming brightness without hardware PWM |
| 7 | **Dark** | Radial Vignette Spotlight + Health Filter | `6000K 100%` / `4400K 85%` / `3700K 80%` | `5000K 100%` / `3400K 80%` / `2700K 75%` | Health LUT + click-through radial vignette overlay (`30%` opacity, `30%` radius, customizable center/cursor-follow) |
| 8 | **Movie** | Shadow Gamma Boost (`120%` Brightness) | `6500K 120%` / `6500K 120%` / `6500K 120%` | `6500K 120%` / `6500K 120%` / `6500K 120%` | Pauses warm shift (`6500K`) and applies gamma curve boost (`120%` effective luminance) to reveal dark movie scenes |
| 9 | **Overlay** | Color Therapy & USB/Docking Display Filter | `5% opacity / 0% dim` (Day) · `40% opacity / 10% dim` (Night & Sleep) | `5% opacity / 0% dim` (Day) · `40% opacity / 10% dim` (Night & Sleep) | Click-through `NSWindow` at `kCGOverlayWindowLevelKey` across all Spaces with all 12 Iris Color Therapy pigments |
| 10 | **Gaming** | Fast-Response Warm Contrast (v1.1.0+) | `6500K 100%` / `3600K 93%` / `3400K 90%` | `5500K 100%` / `3600K 93%` / `3200K 88%` | Low-latency hardware gamma LUT (`3600K / 93%`) with zero overlay compositing overhead |
| 11 | **Custom** | User-Defined Day / Night / Sleep Curve | User configurable (`0K–10000K`, `10%–120%`) | User configurable (`0K–10000K`, `10%–120%`) | Full manual control over Kelvin, Brightness, Gamma Fixer, Inversion, Vignette, and Color Therapy tint |

---

## 5. Architectural Decisions

1. **Embed the Exact 101-Step Kelvin LUT from `Iris.app` (`0x100be0d50`)**: Rather than approximating with Tanner Helland's formula, `LumenBarKit` embeds the exact 101-row float table extracted via REA (`ev_d2dfdacae728857e071e49420542833a310bd6b3a96de1e6cfc2f3a05a7659f3`) and implements `ColorRamp::color_ramp_fill_float` (`ev_b3a5fa95eb6683bed54d00dd66d05b5f43ef01ea0bbf05e4f4e63d277ee2d733`) so `0K` through `10000K` matches Iris pixel-for-pixel.
2. **Dual-Engine Display Pipeline (Hardware Gamma LUT + Click-Through `NSWindow` Overlay)**:
   - **Primary Engine (`DisplayGammaEngine`)**: Uses `CGSetDisplayTransferByTable` and `CGDisplayRestoreColorSyncSettings` per display, supporting instant `0K–10000K` color temperature, `10%–120%` brightness/gamma boost, and hardware LUT inversion (`1.0 - ramp[i]`) for `Programming` and `Biohacker` modes without screen-capture CPU overhead.
   - **Secondary Engine (`DisplayOverlayWindowController`)**: Uses click-through borderless `NSWindow`s (`ignoresMouseEvents = true`, `.canJoinAllSpaces`, `.fullScreenAuxiliary`, level `CGWindowLevelForKey(.overlayWindow)`) for `Overlay` mode (12 Color Therapy tints), `Dark` mode (radial vignette spotlight), `Reading` mode (E-ink paper grain & monochrome desaturation tint), and USB/DisplayLink monitors.
3. **BAMA Architecture & Verification**: Built as a pure Swift 6.2 package (`LumenBar` executable + `LumenBarKit` library + `LumenBarKitTests`), supporting `--self-test`, `APP_SNAPSHOT` (light/dark PNG generation of all pages), `MenuBarExtra` quick popover, Carbon global hotkeys, and `lumenbar://` URL commands.
