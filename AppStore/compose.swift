// Renders App Store marketing images from the raw simulator captures in AppStore/raw.
// Run from the repo root:  swift AppStore/compose.swift
// Output: AppStore/screenshots/{iphone-6.9,ipad-13}/*.png and AppStore/header/*.png
// Files are true PNGs, 8-bit sRGB with NO alpha channel; App Store Connect rejects images
// with transparency, and checks the real file type (renaming .jpg to .png does not convert it).

import AppKit
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("AppStore")

// MARK: - Brand

let brand = Color(red: 0x0F / 255, green: 0x9D / 255, blue: 0x8A / 255)
let brandDeep = Color(red: 0x0A / 255, green: 0x6E / 255, blue: 0x61 / 255)
let brandGlow = Color(red: 0x2D / 255, green: 0xD4 / 255, blue: 0xBF / 255)

struct Caption {
    let file: String
    let title: String
    let subtitle: String
}

let captions: [Caption] = [
    .init(file: "1_today_good", title: "Catch the slouch\nas it happens", subtitle: "Live posture tracking with your iPhone's motion sensors."),
    .init(file: "2_today_alert", title: "A gentle nudge\nbefore it hurts", subtitle: "A haptic and a reminder when you lean too long."),
    .init(file: "3_insights", title: "Watch your posture\nimprove", subtitle: "Daily scores, streaks and weekly trends."),
    .init(file: "4_calibrate", title: "Calibrated to\nyour body", subtitle: "Set your own upright baseline in seconds."),
    .init(file: "5_settings", title: "Smart enough\nto pause", subtitle: "No nags while your phone is pocketed, locked or on a table."),
    .init(file: "6_welcome", title: "Private by design", subtitle: "All posture data stays on your device."),
]

// MARK: - Views

struct Background: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [brand, brandDeep], startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [brandGlow.opacity(0.45), .clear], center: .init(x: 0.85, y: 0.05), startRadius: 0, endRadius: 1400)
        }
    }
}

/// Screenshot inside a simple device-style bezel.
struct DeviceFrame: View {
    let image: NSImage
    let width: CGFloat
    let cornerRatio: CGFloat

    var body: some View {
        let height = width * image.size.height / image.size.width
        let radius = width * cornerRatio
        let bezel = width * 0.022
        Image(nsImage: image)
            .resizable()
            .interpolation(.high)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .padding(bezel)
            .background(
                RoundedRectangle(cornerRadius: radius + bezel, style: .continuous)
                    .fill(Color(white: 0.08))
            )
            .shadow(color: .black.opacity(0.35), radius: width * 0.05, y: width * 0.03)
    }
}

struct ScreenshotPoster: View {
    let caption: Caption
    let image: NSImage
    let size: CGSize
    let isPad: Bool

    var body: some View {
        let titleSize: CGFloat = isPad ? 132 : 112
        let subtitleSize: CGFloat = isPad ? 54 : 50
        let deviceWidth = size.width * (isPad ? 0.74 : 0.80)
        ZStack(alignment: .top) {
            Background()
            VStack(spacing: isPad ? 34 : 30) {
                Text(caption.title)
                    .font(.system(size: titleSize, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                Text(caption.subtitle)
                    .font(.system(size: subtitleSize, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .opacity(0.85)
                    .frame(maxWidth: size.width * 0.82)
            }
            .foregroundStyle(.white)
            .padding(.top, size.height * 0.07)

            DeviceFrame(image: image, width: deviceWidth, cornerRatio: isPad ? 0.035 : 0.11)
                .offset(y: size.height * (isPad ? 0.30 : 0.29))
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

struct HeaderArt: View {
    let size: CGSize
    let phone: NSImage
    let phone2: NSImage
    let icon: NSImage

    var body: some View {
        // Key content sits in the central ~55% so it survives every crop App Store applies.
        let unit = size.height / 1646
        ZStack {
            Background()
            HStack(spacing: 150 * unit) {
                VStack(alignment: .leading, spacing: 44 * unit) {
                    HStack(spacing: 30 * unit) {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 150 * unit, height: 150 * unit)
                            .clipShape(RoundedRectangle(cornerRadius: 34 * unit, style: .continuous))
                            .shadow(color: .black.opacity(0.25), radius: 20 * unit, y: 10 * unit)
                        Text("Posture Help")
                            .font(.system(size: 64 * unit, weight: .semibold, design: .rounded))
                            .opacity(0.9)
                    }
                    Text("Sit up straight,\nwithout thinking\nabout it.")
                        .font(.system(size: 132 * unit, weight: .bold, design: .rounded))
                        .lineSpacing(6 * unit)
                    Text("Gentle, private posture nudges for your iPhone.")
                        .font(.system(size: 52 * unit, weight: .medium, design: .rounded))
                        .opacity(0.85)
                }
                .foregroundStyle(.white)
                .frame(width: 1250 * unit, alignment: .leading)

                ZStack {
                    DeviceFrame(image: phone2, width: 520 * unit, cornerRatio: 0.11)
                        .rotationEffect(.degrees(-7))
                        .offset(x: -230 * unit, y: 120 * unit)
                        .opacity(0.95)
                    DeviceFrame(image: phone, width: 600 * unit, cornerRatio: 0.11)
                        .rotationEffect(.degrees(4))
                        .offset(x: 170 * unit, y: 40 * unit)
                }
                .frame(width: 1000 * unit, height: size.height)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

// MARK: - Rendering

@MainActor
func render<V: View>(_ view: V, size: CGSize, to url: URL) throws {
    let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height).environment(\.colorScheme, .light))
    renderer.scale = 1
    renderer.isOpaque = true
    guard let rendered = renderer.cgImage else { throw NSError(domain: "compose", code: 1) }

    // Redraw into an opaque 8-bit sRGB context so the PNG is written without an alpha channel.
    let width = rendered.width, height = rendered.height
    guard let space = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        throw NSError(domain: "compose", code: 2)
    }
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.draw(rendered, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let cgImage = context.makeImage() else { throw NSError(domain: "compose", code: 3) }

    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw NSError(domain: "compose", code: 4)
    }
    CGImageDestinationAddImage(destination, cgImage, [kCGImagePropertyDPIWidth: 72, kCGImagePropertyDPIHeight: 72] as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { throw NSError(domain: "compose", code: 5) }
    print("wrote \(url.path.replacingOccurrences(of: root.deletingLastPathComponent().path + "/", with: "")) \(cgImage.width)x\(cgImage.height)")
}

func load(_ name: String) -> NSImage {
    guard let image = NSImage(contentsOf: root.appendingPathComponent("raw/\(name).png")) else {
        fatalError("Missing raw capture \(name).png")
    }
    return image
}

@MainActor
func main() throws {
    let targets: [(prefix: String, folder: String, size: CGSize, isPad: Bool)] = [
        ("iphone", "iphone-6.9", CGSize(width: 1320, height: 2868), false),
        ("ipad", "ipad-13", CGSize(width: 2064, height: 2752), true),
    ]
    for target in targets {
        for (index, caption) in captions.enumerated() {
            let image = load("\(target.prefix)_\(caption.file)")
            let name = caption.file.drop(while: { $0.isNumber || $0 == "_" }).replacingOccurrences(of: "_", with: "-")
            let out = root.appendingPathComponent("screenshots/\(target.folder)/\(String(format: "%02d", index + 1))-\(name).png")
            try render(ScreenshotPoster(caption: caption, image: image, size: target.size, isPad: target.isPad), size: target.size, to: out)
        }
    }

    let iconURL = root.deletingLastPathComponent().appendingPathComponent("Sources/PostureIcon/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
    guard let icon = NSImage(contentsOf: iconURL) else { fatalError("Missing app icon at \(iconURL.path)") }
    let phone = load("iphone_1_today_good")
    let phone2 = load("iphone_3_insights")
    for size in [CGSize(width: 3840, height: 1646), CGSize(width: 5244, height: 2950)] {
        let out = root.appendingPathComponent("header/header-\(Int(size.width))x\(Int(size.height)).png")
        try render(HeaderArt(size: size, phone: phone, phone2: phone2, icon: icon), size: size, to: out)
    }
}

try MainActor.assumeIsolated { try main() }
