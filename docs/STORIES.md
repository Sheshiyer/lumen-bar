# User Stories (`LumenBar`)

Built from `docs/BRIEF.md` and `docs/research/blue-light-filter-research.md` following the BAMA `user-stories` workflow.

## Milestone 1: Core Gamma LUT & Preset Engine (`M1`)

### S-001 Apply exact 101-step Iris Kelvin LUT and PWM-free brightness
As the user, I select a color temperature (`0K–10000K`) and brightness (`10%–120%`) so my display's blue/green light and luminance update smoothly via CoreGraphics gamma tables.
Screens: `presets-light.png`, `presets-dark.png`
Acceptance:
- [unit] `KelvinLUT.rgb(forKelvin:)` matches the exact 101-step float table extracted from `Iris.app` (`0x100be0d50`), returning `(1.0, 0.0, 0.0)` at `0K`, `(1.0, 0.774, 0.520)` at `3400K`, and `(1.0, 1.0, 1.0)` at `6500K`.
- [unit] `GammaRampBuilder.buildTables(...)` generates 256-entry `(R, G, B)` float tables with `pow(brightness * ramp * channel, 1.0 / gammaFixer)` and supports `120%` Movie gamma boost and `1.0 - ramp` hardware LUT inversion.
- [self] Calling `DisplayGammaEngine.apply(...)` succeeds or cleanly records simulated tables in headless/snapshot mode and restores neutral tables on pause/quit.
Status: done

### S-002 Switch between Automatic, Manual, and Paused automation modes
As the user, I switch between `Automatic`, `Manual`, and `Paused` modes (or pause for 1 hour) from the window or menu bar.
Screens: `presets-light.png`, `presets-dark.png`
Depends: S-001
Acceptance:
- [unit] In `Automatic` mode, `CircadianScheduler` interpolates Day, Night, and Sleep temperature/brightness values across configurable transition windows.
- [unit] In `Manual` mode, the manual Kelvin/Brightness overrides or active preset's night target apply immediately regardless of clock time.
- [unit] In `Paused` mode, effective output returns to `6500K / 100%` with all overlays hidden.
- [snap] The top mode bar and live status card display active mode, phase (`Day`, `Night`, `Sleep`), Kelvin, and Brightness.
Status: done

### S-003 Select any of the 11 Iris Preset Types (Standard & Pro profiles)
As the user, I click any of the 11 preset cards (`Health`, `Sleep`, `Reading`, `Programming`, `Biohacker`, `Sunglasses`, `Dark`, `Movie`, `Overlay`, `Gaming`, `Custom`) and toggle between **Iris Pro** and **Iris Standard** presets.
Screens: `presets-light.png`, `presets-dark.png`
Depends: S-001, S-002
Acceptance:
- [unit] Every `FilterPresetType` provides exact Day, Night, and Sleep Kelvin/Brightness targets for both `.pro` and `.standard` tiers matching `iristech.co/type-dropdown-help/`.
- [unit] `Programming` and `Biohacker` enable gamma LUT inversion; `Reading` enables E-Ink Grayscale; `Dark` enables the radial vignette spotlight; `Movie` sets `6500K / 120%`; `Overlay` enables the Color Therapy overlay.
- [snap] All 11 preset cards render with icon, specialty badge, Day/Night/Sleep specs, and active selection ring.
Status: done

## Milestone 2: Schedule, Overlay & Eye Health (`M2`)

### S-004 Configure Day, Night, and Sleep curves & 24-hour circadian preview
As the user, I customize Day, Night, and Sleep temperatures, brightness levels, and transition times on the `Light & Schedule` page and preview the 24-hour solar curve.
Screens: `schedule-light.png`, `schedule-dark.png`
Depends: S-002
Acceptance:
- [snap] The `Light & Schedule` page renders sliders for Day, Night, and Sleep Kelvin (`0K–10000K`) and Brightness (`10%–120%`), plus an interactive 24-hour circadian curve chart and transition preview slider.
- [self] Dragging the transition preview or changing schedule hours updates the interpolated Kelvin/Brightness readout.
Status: done

### S-005 Customize Color Therapy Overlays, Dark Vignette, and Screen Effects
As the user, I configure the 12 Iris Color Therapy overlay pigments, Dark mode radial vignette radius/opacity, E-Ink grayscale, and Gamma Fixer on the `Overlay & Effects` page.
Screens: `effects-light.png`, `effects-dark.png`
Depends: S-003
Acceptance:
- [unit] All 12 `OverlayPigment` cases match the exact RGB values decompiled from `OverlayScreen::get_color_values` (`0x10005a880`) scaled by `(100 - dim) / 100`.
- [snap] The `Overlay & Effects` page shows the 12 color therapy swatches, vignette radius/opacity sliders, and effect toggles.
Status: done

### S-006 Manage 20-20-20 Eye Rest Timer and Color-Critical App Pausers
As the user, I configure the eye rest reminder timer and specify apps (such as Photoshop, Figma, Blender, Final Cut Pro) that automatically pause blue-light filtering when active.
Screens: `eyerest-light.png`, `eyerest-dark.png`
Depends: S-002
Acceptance:
- [unit] `AppPauserMonitor` detects when a frontmost bundle ID matches an enabled `AppPauseRule` and temporarily suspends filtering.
- [unit] `RestTimerEngine` tracks work and rest intervals and triggers break reminders.
- [snap] The `Eye Rest & Pausers` page displays the timer ring, quick start/reset controls, and the app pauser list.
Status: done

### S-007 Inspect live LUT curves, multi-display status, and REA binary provenance
As the user, I open the `REA & Diagnostics` page to inspect the live 256-entry RGB gamma curves, connected displays, URL/CLI automation commands, and REA reverse-engineering evidence from `Iris.app`.
Screens: `diagnostics-light.png`, `diagnostics-dark.png`
Depends: S-001
Acceptance:
- [snap] The `REA & Diagnostics` page renders the live R/G/B transfer curves, per-display status, global shortcut cheatsheet, and REA Evidence table.
Status: done

## Dropped
- Paid license keys and trial expiration timers (all Pro presets and features are free and local).
