import Foundation
import AVFoundation
import CoreGraphics
import UIKit

struct DreamVideoSynthesizer {
    struct Options {
        var duration: Double = 8
        var size: CGSize = CGSize(width: 720, height: 1280)
        var fps: Int32 = 30
    }

    private let options: Options

    init(options: Options = Options()) {
        self.options = options
    }

    func renderVideo(for prompt: String) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("ruya_\(UUID().uuidString).mp4")
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: options.size.width,
            AVVideoHeightKey: options.size.height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 4_000_000]
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: Int(options.size.width),
                kCVPixelBufferHeightKey as String: Int(options.size.height)
            ]
        )

        guard writer.canAdd(input) else {
            throw NSError(domain: "RuyaSarmali", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to add video input"])
        }
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let frameCount = Int(options.duration * Double(options.fps))
        let colors = DreamColorPalette(prompt: prompt)

        for frame in 0..<frameCount {
            let time = CMTime(value: CMTimeValue(frame), timescale: options.fps)
            while input.isReadyForMoreMediaData == false {
                try await Task.sleep(for: .milliseconds(5))
            }

            guard let pixelBufferPool = adaptor.pixelBufferPool else { continue }
            var pixelBufferOut: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &pixelBufferOut)
            guard let pixelBuffer = pixelBufferOut else { continue }
            CVPixelBufferLockBaseAddress(pixelBuffer, [])
            if let base = CVPixelBufferGetBaseAddress(pixelBuffer) {
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                if let cgContext = CGContext(
                    data: base,
                    width: Int(options.size.width),
                    height: Int(options.size.height),
                    bitsPerComponent: 8,
                    bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                ) {
                    drawFrame(context: cgContext, size: options.size, frameIndex: frame, frameCount: frameCount, palette: colors)
                }
            }
            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
            adaptor.append(pixelBuffer, withPresentationTime: time)
        }

        input.markAsFinished()
        await writer.finishWriting()
        return outputURL
    }

    private func drawFrame(context: CGContext, size: CGSize, frameIndex: Int, frameCount: Int, palette: DreamColorPalette) {
        context.clear(CGRect(origin: .zero, size: size))
        let progress = Double(frameIndex) / Double(max(frameCount - 1, 1))
        drawGradientBackdrop(context: context, size: size, palette: palette, progress: progress)
        drawConstellationOrbits(context: context, size: size, frameIndex: frameIndex, palette: palette)
        drawNebula(context: context, size: size, progress: progress, palette: palette)
        drawStars(context: context, size: size, palette: palette)
    }

    private func drawGradientBackdrop(context: CGContext, size: CGSize, palette: DreamColorPalette, progress: Double) {
        let shimmer = CGFloat(0.65 + 0.35 * sin(progress * Double.pi * 2))
        let linearColors = [palette.primary.cgColor, palette.secondary.cgColor, palette.accent.cgColor]
        let linear = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: linearColors as CFArray, locations: [0, 0.4, 1])
        context.saveGState()
        context.setAlpha(shimmer)
        context.drawLinearGradient(linear!, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        context.restoreGState()

        let center = CGPoint(x: size.width / 2, y: size.height * 0.35)
        let radialColors = [palette.highlight.withAlphaComponent(0.8).cgColor, palette.primary.withAlphaComponent(0).cgColor]
        if let radial = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: radialColors as CFArray, locations: [0, 1]) {
            context.drawRadialGradient(radial, startCenter: center, startRadius: 10, endCenter: center, endRadius: max(size.width, size.height), options: [])
        }
    }

    private func drawConstellationOrbits(context: CGContext, size: CGSize, frameIndex: Int, palette: DreamColorPalette) {
        for orbit in 0..<6 {
            let orbitPath = UIBezierPath()
            let radius = CGFloat(orbit + 1) * 40
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            orbitPath.addArc(withCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            context.setStrokeColor(palette.accent.withAlphaComponent(0.1).cgColor)
            context.setLineWidth(1.2)
            context.addPath(orbitPath.cgPath)
            context.strokePath()

            let angle = CGFloat(frameIndex) * 0.02 * CGFloat(orbit + 1)
            let dotPoint = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius * 1.4)
            let dotRect = CGRect(x: dotPoint.x - 6, y: dotPoint.y - 6, width: 12, height: 12)
            context.setFillColor(palette.highlight.withAlphaComponent(0.7).cgColor)
            context.fillEllipse(in: dotRect)
            if orbit % 2 == 0 {
                let ribbon = UIBezierPath()
                let wobble = CGFloat(orbit + 1) * 18
                ribbon.move(to: CGPoint(x: 0, y: size.height / 2))
                for x in stride(from: 0, through: size.width, by: 24) {
                    let y = size.height / 2 + sin((CGFloat(frameIndex) * 0.02) + x / 50) * wobble
                    ribbon.addLine(to: CGPoint(x: x, y: y))
                }
                context.setStrokeColor(palette.secondary.withAlphaComponent(0.08).cgColor)
                context.addPath(ribbon.cgPath)
                context.strokePath()
            }
        }
    }

    private func drawNebula(context: CGContext, size: CGSize, progress: Double, palette: DreamColorPalette) {
        let cloudCount = 12
        for index in 0..<cloudCount {
            let phase = progress * Double(index + 1)
            let center = CGPoint(
                x: size.width * CGFloat(0.1 + Double(index) * 0.08).truncatingRemainder(dividingBy: size.width),
                y: size.height * (0.2 + CGFloat(sin(phase * 3)) * 0.2 + CGFloat(index) * 0.04)
            )
            let rect = CGRect(x: center.x - 80, y: center.y - 80, width: 160, height: 160)
            context.setFillColor(palette.accent.withAlphaComponent(0.07).cgColor)
            context.fillEllipse(in: rect)
        }
    }

    private func drawStars(context: CGContext, size: CGSize, palette: DreamColorPalette) {
        for _ in 0..<60 {
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height)
            let alpha = CGFloat.random(in: 0.1...0.35)
            let starRect = CGRect(x: x, y: y, width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
            context.setFillColor(palette.highlight.withAlphaComponent(alpha).cgColor)
            context.fillEllipse(in: starRect)
        }
    }
}

struct DreamColorPalette {
    let primary: UIColor
    let secondary: UIColor
    let accent: UIColor
    let highlight: UIColor

    init(prompt: String) {
        let normalized = prompt.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        if let palette = DreamColorPalette.definitions.first(where: { def in
            def.keywords.contains(where: { normalized.contains($0) })
        }) {
            primary = palette.primary
            secondary = palette.secondary
            accent = palette.accent
            highlight = palette.highlight
        } else if let directColor = DreamColorPalette.colorWord(in: normalized) {
            primary = directColor.withAlpha(0.65)
            secondary = directColor.withAlpha(0.45)
            accent = directColor.withAlpha(0.85)
            highlight = UIColor.white
        } else {
            primary = UIColor(red: 0.04, green: 0.02, blue: 0.13, alpha: 1)
            secondary = UIColor(red: 0.16, green: 0.05, blue: 0.22, alpha: 1)
            accent = UIColor(red: 0.48, green: 0.12, blue: 0.42, alpha: 1)
            highlight = UIColor(red: 0.98, green: 0.71, blue: 0.98, alpha: 1)
        }
    }

    private static func colorWord(in text: String) -> UIColor? {
        let mapping: [String: UIColor] = [
            "mavi": UIColor.systemTeal,
            "blue": UIColor.systemBlue,
            "kırmızı": UIColor.systemRed,
            "red": UIColor.systemRed,
            "yeşil": UIColor.systemGreen,
            "green": UIColor.systemGreen,
            "mor": UIColor.systemPurple,
            "purple": UIColor.systemPurple,
            "turuncu": UIColor.orange,
            "orange": UIColor.orange,
            "altın": UIColor(red: 1, green: 0.82, blue: 0.39, alpha: 1),
            "gold": UIColor(red: 1, green: 0.82, blue: 0.39, alpha: 1)
        ]
        for (key, value) in mapping where text.contains(key) {
            return value
        }
        return nil
    }

    private static let definitions: [PaletteDefinition] = [
        PaletteDefinition(
            keywords: ["deniz", "ocean", "sea", "wave"],
            primary: UIColor(red: 0.02, green: 0.07, blue: 0.19, alpha: 1),
            secondary: UIColor(red: 0.04, green: 0.22, blue: 0.43, alpha: 1),
            accent: UIColor(red: 0.09, green: 0.57, blue: 0.75, alpha: 1),
            highlight: UIColor(red: 0.62, green: 0.94, blue: 0.99, alpha: 1)
        ),
        PaletteDefinition(
            keywords: ["orm", "forest", "tree", "jungle"],
            primary: UIColor(red: 0.02, green: 0.12, blue: 0.08, alpha: 1),
            secondary: UIColor(red: 0.12, green: 0.35, blue: 0.18, alpha: 1),
            accent: UIColor(red: 0.24, green: 0.75, blue: 0.44, alpha: 1),
            highlight: UIColor(red: 0.79, green: 0.97, blue: 0.66, alpha: 1)
        ),
        PaletteDefinition(
            keywords: ["ateş", "fire", "lava", "sunset", "gün batımı"],
            primary: UIColor(red: 0.20, green: 0.01, blue: 0.02, alpha: 1),
            secondary: UIColor(red: 0.45, green: 0.07, blue: 0.05, alpha: 1),
            accent: UIColor(red: 0.93, green: 0.41, blue: 0.12, alpha: 1),
            highlight: UIColor(red: 1.0, green: 0.84, blue: 0.32, alpha: 1)
        ),
        PaletteDefinition(
            keywords: ["uzay", "galaksi", "galaxy", "astro", "space"],
            primary: UIColor(red: 0.02, green: 0.03, blue: 0.13, alpha: 1),
            secondary: UIColor(red: 0.15, green: 0.07, blue: 0.26, alpha: 1),
            accent: UIColor(red: 0.37, green: 0.12, blue: 0.44, alpha: 1),
            highlight: UIColor(red: 0.94, green: 0.68, blue: 1, alpha: 1)
        ),
        PaletteDefinition(
            keywords: ["gün doğumu", "sunrise", "şafak", "dawn"],
            primary: UIColor(red: 0.10, green: 0.02, blue: 0.14, alpha: 1),
            secondary: UIColor(red: 0.36, green: 0.09, blue: 0.27, alpha: 1),
            accent: UIColor(red: 0.98, green: 0.42, blue: 0.32, alpha: 1),
            highlight: UIColor(red: 1.0, green: 0.89, blue: 0.58, alpha: 1)
        ),
        PaletteDefinition(
            keywords: ["çiçek", "flower", "bahar", "spring"],
            primary: UIColor(red: 0.12, green: 0.05, blue: 0.21, alpha: 1),
            secondary: UIColor(red: 0.28, green: 0.07, blue: 0.36, alpha: 1),
            accent: UIColor(red: 0.91, green: 0.29, blue: 0.51, alpha: 1),
            highlight: UIColor(red: 0.99, green: 0.74, blue: 0.88, alpha: 1)
        )
    ]
}

private struct PaletteDefinition {
    let keywords: [String]
    let primary: UIColor
    let secondary: UIColor
    let accent: UIColor
    let highlight: UIColor
}

private extension UIColor {
    func withAlpha(_ alpha: CGFloat) -> UIColor {
        withAlphaComponent(alpha)
    }
}
