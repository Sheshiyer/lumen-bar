import AppKit
import Carbon
import CoreGraphics
import Foundation
import LumenBarKit
import SwiftUI

// MARK: - 1. Connected Display Descriptor

struct DisplayDescriptor: Identifiable, Equatable {
    let id: CGDirectDisplayID
    let name: String
    let resolution: String
    let isMain: Bool
    let gammaCapacity: Int
}

// MARK: - 2. CoreGraphics Gamma Engine (REA `MacGamma::set_temperature_for_display` @ `0x10011ab50`)

@MainActor
final class DisplayGammaEngine {
    static let shared = DisplayGammaEngine()

    private(set) var lastTables: GammaTransferTables = GammaRampBuilder.buildTables(kelvin: 6500, brightnessPercent: 100)
    private(set) var lastAppliedStatus: String = "Calibrated (6500K / 100%)"
    private(set) var connectedDisplays: [DisplayDescriptor] = []

    /// Avoid mutating the real hardware gamma table while running automated UI snapshots or self-tests.
    var isSimulationMode: Bool {
        let env = ProcessInfo.processInfo.environment
        return env["APP_SNAPSHOT"] != nil || CommandLine.arguments.contains("--selftest")
    }

    private init() {
        refreshDisplays()
    }

    func refreshDisplays() {
        var displayCount: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &displayCount)
        let maxDisplays = Int(max(1, displayCount))
        var activeIDs = [CGDirectDisplayID](repeating: 0, count: maxDisplays)
        CGGetActiveDisplayList(UInt32(maxDisplays), &activeIDs, &displayCount)

        var list: [DisplayDescriptor] = []
        let screensByID: [CGDirectDisplayID: NSScreen] = Dictionary(
            uniqueKeysWithValues: NSScreen.screens.compactMap { screen in
                guard let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                    return nil
                }
                return (CGDirectDisplayID(num.uint32Value), screen)
            }
        )

        for idx in 0..<Int(displayCount) {
            let id = activeIDs[idx]
            let screen = screensByID[id]
            let name = screen?.localizedName ?? "Display \(idx + 1)"
            let width = CGDisplayPixelsWide(id)
            let height = CGDisplayPixelsHigh(id)
            let cap = Int(CGDisplayGammaTableCapacity(id))
            list.append(
                DisplayDescriptor(
                    id: id,
                    name: name,
                    resolution: "\(width)×\(height)",
                    isMain: CGDisplayIsMain(id) != 0,
                    gammaCapacity: max(256, cap)
                )
            )
        }

        if list.isEmpty {
            list.append(
                DisplayDescriptor(
                    id: CGMainDisplayID(),
                    name: "Built-in Liquid Retina XDR Display",
                    resolution: "3024×1964",
                    isMain: true,
                    gammaCapacity: 256
                )
            )
        }
        connectedDisplays = list
    }

    func apply(state: EffectiveDisplayState, excludedDisplayIDs: Set<CGDirectDisplayID>) {
        refreshDisplays()

        if state.isEffectivelyPaused {
            lastTables = GammaRampBuilder.buildTables(kelvin: 6500, brightnessPercent: 100)
            if !isSimulationMode {
                CGDisplayRestoreColorSyncSettings()
            }
            if let app = state.pausingAppName {
                lastAppliedStatus = "Auto-Paused for \(app) (6500K / 100%)"
            } else {
                lastAppliedStatus = "Paused — Calibrated 6500K / 100%"
            }
            DisplayOverlayController.shared.updateOverlays(state: state, excludedDisplayIDs: excludedDisplayIDs)
            return
        }

        let tables = GammaRampBuilder.buildTables(
            kelvin: state.kelvin,
            brightnessPercent: state.brightnessPercent,
            inverted: state.invertsColors,
            grayscalePaper: state.usesGrayscale,
            gammaFixer: state.gammaFixer,
            capacity: 256
        )
        lastTables = tables

        if !isSimulationMode {
            let neutral = GammaRampBuilder.buildTables(kelvin: 6500, brightnessPercent: 100, capacity: 256)
            for display in connectedDisplays {
                let useTable = excludedDisplayIDs.contains(display.id) ? neutral : tables
                var r = useTable.red
                var g = useTable.green
                var b = useTable.blue
                _ = CGSetDisplayTransferByTable(display.id, UInt32(useTable.capacity), &r, &g, &b)
            }
        }

        lastAppliedStatus = "\(state.preset.title) (\(state.phase.title)) · \(state.kelvin)K · \(state.brightnessPercent)%"
        DisplayOverlayController.shared.updateOverlays(state: state, excludedDisplayIDs: excludedDisplayIDs)
    }

    func restoreSystemCalibration() {
        if !isSimulationMode {
            CGDisplayRestoreColorSyncSettings()
        }
        DisplayOverlayController.shared.hideAll()
    }
}

// MARK: - 3. Click-Through Overlay Window Controller (REA `set_always_on_top` @ `0x10000b540` & `can_join_all_spaces` @ `0x10000b610`)

@MainActor
final class DisplayOverlayController {
    static let shared = DisplayOverlayController()

    private var windowsByDisplay: [CGDirectDisplayID: NSWindow] = [:]

    private init() {}

    func updateOverlays(state: EffectiveDisplayState, excludedDisplayIDs: Set<CGDirectDisplayID>) {
        // Never cover the screen during automated window snapshots or self-tests.
        if DisplayGammaEngine.shared.isSimulationMode || state.isEffectivelyPaused {
            hideAll()
            return
        }

        let needsOverlay = state.usesOverlayTint || state.usesDarkVignette || state.usesGrayscale
        guard needsOverlay else {
            hideAll()
            return
        }

        for screen in NSScreen.screens {
            guard let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                continue
            }
            let displayID = CGDirectDisplayID(num.uint32Value)
            if excludedDisplayIDs.contains(displayID) {
                windowsByDisplay[displayID]?.orderOut(nil)
                continue
            }

            let window = windowsByDisplay[displayID] ?? makeOverlayWindow(for: screen)
            windowsByDisplay[displayID] = window
            window.setFrame(screen.frame, display: true)
            window.contentView = NSHostingView(rootView: ScreenOverlayCanvas(state: state))
            window.orderFrontRegardless()
        }
    }

    func hideAll() {
        for window in windowsByDisplay.values {
            window.orderOut(nil)
        }
    }

    private func makeOverlayWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        // Exact click-through overlay attributes decompiled via REA (`0x10000b540` & `0x10000b610`)
        window.ignoresMouseEvents = true
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.overlayWindow)))
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hidesOnDeactivate = false
        window.canHide = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        return window
    }
}

private struct ScreenOverlayCanvas: View {
    let state: EffectiveDisplayState

    var body: some View {
        ZStack {
            if state.usesOverlayTint {
                let rgb = state.overlayPigment.dimmedRGB255(screenDimPercent: state.overlayDimPercent)
                Color(
                    red: Double(rgb.r) / 255.0,
                    green: Double(rgb.g) / 255.0,
                    blue: Double(rgb.b) / 255.0
                )
                .opacity(Double(state.overlayOpacityPercent) / 100.0)
            }

            if state.usesGrayscale {
                // Warm E-Ink reading wash reducing subpixel contrast harshness
                Color(red: 0.96, green: 0.93, blue: 0.86)
                    .opacity(0.14)
                    .blendMode(.saturation)
            }

            if state.usesDarkVignette {
                GeometryReader { geo in
                    let minDim = min(geo.size.width, geo.size.height)
                    let innerRadius = minDim * (Double(state.vignetteRadiusPercent) / 100.0)
                    let outerRadius = max(geo.size.width, geo.size.height) * 0.78
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black.opacity(Double(state.vignetteOpacityPercent) / 100.0 * 0.65), location: 0.55),
                            .init(color: .black.opacity(Double(state.vignetteOpacityPercent) / 100.0), location: 1.0)
                        ]),
                        center: .center,
                        startRadius: innerRadius,
                        endRadius: outerRadius
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 4. Global Carbon Hotkey Manager (BAMA `os-integrations` skill)

@MainActor
final class GlobalHotkeyCenter {
    static let shared = GlobalHotkeyCenter()

    enum Action: UInt32 {
        case togglePause = 1
        case cyclePreset = 2
        case tempWarmer = 3
        case tempCooler = 4
        case brightnessUp = 5
        case brightnessDown = 6
    }

    var onAction: ((Action) -> Void)?
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var eventHandlerRef: EventHandlerRef?

    private init() {}

    func registerDefaultShortcuts() {
        guard hotKeyRefs.isEmpty else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                var hotKeyID = EventHotKeyID()
                let err = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                if err == noErr, let action = GlobalHotkeyCenter.Action(rawValue: hotKeyID.id) {
                    Task { @MainActor in
                        GlobalHotkeyCenter.shared.onAction?(action)
                    }
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )
        guard status == noErr else { return }

        let mods = UInt32(controlKey | optionKey | cmdKey)
        register(id: .togglePause, keyCode: UInt32(kVK_ANSI_P), modifiers: mods)
        register(id: .cyclePreset, keyCode: UInt32(kVK_ANSI_M), modifiers: mods)
        register(id: .tempWarmer, keyCode: UInt32(kVK_LeftArrow), modifiers: mods)
        register(id: .tempCooler, keyCode: UInt32(kVK_RightArrow), modifiers: mods)
        register(id: .brightnessUp, keyCode: UInt32(kVK_UpArrow), modifiers: mods)
        register(id: .brightnessDown, keyCode: UInt32(kVK_DownArrow), modifiers: mods)
    }

    private func register(id: Action, keyCode: UInt32, modifiers: UInt32) {
        var ref: EventHotKeyRef?
        let hkID = EventHotKeyID(signature: OSType(0x4C4D4252), id: id.rawValue) // 'LMBR'
        let err = RegisterEventHotKey(keyCode, modifiers, hkID, GetApplicationEventTarget(), 0, &ref)
        if err == noErr {
            hotKeyRefs.append(ref)
        }
    }
}
