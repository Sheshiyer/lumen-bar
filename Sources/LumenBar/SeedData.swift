import Foundation

enum SeedData {
    static func defaultPauseRules() -> [AppPauseRule] {
        [
            AppPauseRule(appName: "Adobe Photoshop", bundleID: "com.adobe.Photoshop", category: "Photo & Color Grading", isEnabled: true),
            AppPauseRule(appName: "DaVinci Resolve", bundleID: "com.blackmagic-design.DaVinciResolve", category: "Color Grading", isEnabled: true),
            AppPauseRule(appName: "Figma", bundleID: "com.figma.Desktop", category: "UI & Brand Design", isEnabled: true),
            AppPauseRule(appName: "Final Cut Pro", bundleID: "com.apple.FinalCut", category: "Video Mastering", isEnabled: true),
            AppPauseRule(appName: "Apple Photos", bundleID: "com.apple.Photos", category: "Photography", isEnabled: false),
            AppPauseRule(appName: "Blender", bundleID: "org.blenderfoundation.blender", category: "3D Rendering", isEnabled: false)
        ]
    }
}
