import AppKit
import Carbon
import CoreGraphics
import Foundation
import IOKit
import LumenBarKit
import SwiftUI

// MARK: - 1. Connected Display Descriptor

struct DisplayDescriptor: Identifiable, Equatable {
    let id: CGDirectDisplayID
    /// Stable across launches and plug cycles. Display IDs are not.
    let key: String
    let name: String
    let resolution: String
    let isMain: Bool
    let isBuiltin: Bool
    let gammaCapacity: Int
    /// Position on the desk, in points, for the desk map.
    let frame: CGRect

    /// A short label for the desk map, such as "Built-in" or "LG HDR".
    var shortName: String {
        let trimmed = name
            .replacingOccurrences(of: "Display", with: "")
            .trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "Display" : trimmed
    }
}

/// A monitor identity that survives relaunch. macOS display IDs do not.
enum DisplayIdentity {
    static func key(for id: CGDirectDisplayID, screen: NSScreen?) -> String {
        if let uuid = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() {
            return CFUUIDCreateString(kCFAllocatorDefault, uuid) as String
        }
        if let vendor = ioInt(id, kDisplayVendorID), let product = ioInt(id, kDisplayProductID) {
            let serial = ioInt(id, kDisplaySerialNumber) ?? 0
            return String(format: "vp-%08X-%08X-%08X", vendor, product, serial)
        }
        let name = screen?.localizedName ?? "display"
        let width = CGDisplayPixelsWide(id)
        let height = CGDisplayPixelsHigh(id)
        return "fallback-\(name)-\(width)x\(height)"
    }

    private static func ioInt(_ id: CGDirectDisplayID, _ key: String) -> Int? {
        guard let service = CGDisplayIOServicePortShim(id) else { return nil }
        let info = IODisplayCreateInfoDictionary(service, IOOptionBits(kIODisplayNoProductName)).takeRetainedValue() as NSDictionary
        return (info[key] as? NSNumber)?.intValue
    }

    /// `CGDisplayIOServicePort` left the SDK but the symbol is still there.
    private static func CGDisplayIOServicePortShim(_ id: CGDirectDisplayID) -> io_service_t? {
        let handle = dlopen(nil, RTLD_NOW)
        defer { dlclose(handle) }
        guard let symbol = dlsym(handle, "CGDisplayIOServicePort") else { return nil }
        typealias Fn = @convention(c) (UInt32) -> io_service_t
        let port = unsafeBitCast(symbol, to: Fn.self)(id)
        return port == 0 ? nil : port
    }
}

// MARK: - 2. CoreGraphics Gamma Engine (REA `MacGamma::set_temperature_for_display` @ `0x10011ab50`)

@MainActor
final class DisplayGammaEngine {
    static let shared = DisplayGammaEngine()

    private(set) var lastTables: GammaTransferTables = GammaRampBuilder.buildTables(kelvin: 6500, brightnessPercent: 100)
    private(set) var lastAppliedStatus: String = "Calibrated (6500K / 100%)"
    private(set) var connectedDisplays: [DisplayDescriptor] = []
    private var crossfadeTask: Task<Void, Never>?
    private let crossfadeDuration: TimeInterval = 0.6

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
                    key: DisplayIdentity.key(for: id, screen: screen),
                    name: name,
                    resolution: "\(width)×\(height)",
                    isMain: CGDisplayIsMain(id) != 0,
                    isBuiltin: CGDisplayIsBuiltin(id) != 0,
                    gammaCapacity: max(256, cap),
                    frame: screen?.frame ?? .zero
                )
            )
        }

        if list.isEmpty {
            let id = CGMainDisplayID()
            list.append(
                DisplayDescriptor(
                    id: id,
                    key: DisplayIdentity.key(for: id, screen: nil),
                    name: "Built-in Display",
                    resolution: "3024×1964",
                    isMain: true,
                    isBuiltin: true,
                    gammaCapacity: 256,
                    frame: .zero
                )
            )
        }
        connectedDisplays = list
    }

    /// The gamma table one monitor should show.
    func tables(for display: DisplayDescriptor, state: EffectiveDisplayState, profiles: [String: DisplayProfile]) -> GammaTransferTables {
        let profile = profiles[display.key] ?? DisplayProfile()
        let look = profile.look(
            mainKelvin: state.kelvin,
            mainBrightnessPercent: state.brightnessPercent,
            paused: state.isEffectivelyPaused
        )
        if !look.isFiltered {
            return GammaRampBuilder.buildTables(kelvin: 6500, brightnessPercent: 100, capacity: 256)
        }
        return GammaRampBuilder.buildTables(
            kelvin: look.kelvin,
            brightnessPercent: look.brightnessPercent,
            inverted: state.invertsColors,
            grayscalePaper: state.usesGrayscale,
            gammaFixer: state.gammaFixer,
            capacity: 256
        )
    }

    func apply(state: EffectiveDisplayState, profiles: [String: DisplayProfile], animated: Bool = false) {
        refreshDisplays()

        if state.isEffectivelyPaused {
            crossfadeTask?.cancel()
            crossfadeTask = nil
            lastTables = GammaRampBuilder.buildTables(kelvin: 6500, brightnessPercent: 100)
            if !isSimulationMode {
                CGDisplayRestoreColorSyncSettings()
            }
            if let app = state.pausingAppName {
                lastAppliedStatus = "Auto-Paused for \(app) (6500K / 100%)"
            } else {
                lastAppliedStatus = "Paused — Calibrated 6500K / 100%"
            }
            DisplayOverlayController.shared.updateOverlays(state: state, profiles: profiles)
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

        if animated && !isSimulationMode {
            beginCrossfade(from: lastTables, to: tables, state: state, profiles: profiles)
            return
        }

        commitTables(tables, state: state, profiles: profiles)
    }

    private func beginCrossfade(
        from: GammaTransferTables,
        to: GammaTransferTables,
        state: EffectiveDisplayState,
        profiles: [String: DisplayProfile]
    ) {
        crossfadeTask?.cancel()
        crossfadeTask = Task { @MainActor in
            let steps = 36
            for step in 0...steps {
                if Task.isCancelled { return }
                let t = Double(step) / Double(steps)
                let eased = t * t * (3 - 2 * t)
                let blended = Self.lerpTables(from: from, to: to, amount: Float(eased))
                commitTables(
                    blended,
                    state: state,
                    profiles: profiles,
                    updateStatus: step == steps
                )
                if step < steps {
                    try? await Task.sleep(for: .milliseconds(Int(crossfadeDuration * 1000 / Double(steps))))
                }
            }
        }
    }

    private static func lerpTables(from: GammaTransferTables, to: GammaTransferTables, amount: Float) -> GammaTransferTables {
        func mix(_ a: [Float], _ b: [Float]) -> [Float] {
            zip(a, b).map { $0 + ($1 - $0) * amount }
        }
        return GammaTransferTables(
            capacity: from.capacity,
            red: mix(from.red, to.red),
            green: mix(from.green, to.green),
            blue: mix(from.blue, to.blue)
        )
    }

    private func commitTables(
        _ tables: GammaTransferTables,
        state: EffectiveDisplayState,
        profiles: [String: DisplayProfile],
        updateStatus: Bool = true
    ) {
        lastTables = tables

        if !isSimulationMode {
            for display in connectedDisplays {
                // The main look cross-fades. A custom monitor lands on its own table.
                let follows = (profiles[display.key]?.mode ?? .follow) == .follow
                let useTable = follows ? tables : self.tables(for: display, state: state, profiles: profiles)
                var r = useTable.red
                var g = useTable.green
                var b = useTable.blue
                _ = CGSetDisplayTransferByTable(display.id, UInt32(useTable.capacity), &r, &g, &b)
            }
        }

        if updateStatus {
            let custom = connectedDisplays.filter { (profiles[$0.key]?.mode ?? .follow) != .follow }.count
            let desk = custom == 0 ? "" : " · \(custom) custom"
            lastAppliedStatus = "\(state.preset.title) (\(state.phase.title)) · \(state.kelvin)K · \(state.brightnessPercent)%\(desk)"
        }
        DisplayOverlayController.shared.updateOverlays(state: state, profiles: profiles)
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

    func updateOverlays(state: EffectiveDisplayState, profiles: [String: DisplayProfile]) {
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
            let key = DisplayIdentity.key(for: displayID, screen: screen)
            if (profiles[key]?.mode ?? .follow) == .off {
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
