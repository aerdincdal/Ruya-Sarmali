import AVFoundation
import UIKit
import CoreImage

/// Utility to add watermark text to video files
struct VideoWatermarkProcessor {
    
    static let watermarkText = "Rüya Sarmalı ile Rüyalarını Sevdiklerinle Paylaş"
    
    /// Add watermark to video and return new URL
    /// Note: Skips watermark on simulator due to AVVideoCompositionCoreAnimationTool issues
    static func addWatermark(to inputURL: URL) async throws -> URL {
        // Skip watermark on simulator - AVVideoCompositionCoreAnimationTool has issues
        #if targetEnvironment(simulator)
        print("⚠️ Watermark skipped on simulator")
        return inputURL
        #else
        return try await addWatermarkReal(to: inputURL)
        #endif
    }
    
    private static func addWatermarkReal(to inputURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: inputURL)
        
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw NSError(domain: "VideoWatermark", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video track bulunamadı"])
        }
        
        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        
        // Determine correct video size after transform
        let videoSize = naturalSize.applying(preferredTransform)
        let correctedSize = CGSize(width: abs(videoSize.width), height: abs(videoSize.height))
        
        // Create composition
        let composition = AVMutableComposition()
        
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw NSError(domain: "VideoWatermark", code: -2, userInfo: [NSLocalizedDescriptionKey: "Video track oluşturulamadı"])
        }
        
        let duration = try await asset.load(.duration)
        try compositionVideoTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: videoTrack,
            at: .zero
        )
        compositionVideoTrack.preferredTransform = preferredTransform
        
        // Add audio if exists
        if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(
               withMediaType: .audio,
               preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            try compositionAudioTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                of: audioTrack,
                at: .zero
            )
        }
        
        // Create layers on main thread for thread safety
        let (parentLayer, videoLayer) = await MainActor.run {
            let watermarkLayer = createWatermarkLayer(size: correctedSize)
            let videoLayer = CALayer()
            videoLayer.frame = CGRect(origin: .zero, size: correctedSize)
            
            let parentLayer = CALayer()
            parentLayer.frame = CGRect(origin: .zero, size: correctedSize)
            parentLayer.addSublayer(videoLayer)
            parentLayer.addSublayer(watermarkLayer)
            
            return (parentLayer, videoLayer)
        }
        
        // Create video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = correctedSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        layerInstruction.setTransform(preferredTransform, at: .zero)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        // Export
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("watermarked_\(UUID().uuidString).mp4")
        
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw NSError(domain: "VideoWatermark", code: -3, userInfo: [NSLocalizedDescriptionKey: "Export session oluşturulamadı"])
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        
        await exportSession.export()
        
        if let error = exportSession.error {
            throw error
        }
        
        guard exportSession.status == .completed else {
            throw NSError(domain: "VideoWatermark", code: -4, userInfo: [NSLocalizedDescriptionKey: "Video export başarısız: \(exportSession.status.rawValue)"])
        }
        
        print("✅ Watermark added successfully to video")
        return outputURL
    }
    
    private static func createWatermarkLayer(size: CGSize) -> CALayer {
        let watermarkLayer = CATextLayer()
        
        // Calculate font size proportional to video width
        let fontSize = min(size.width, size.height) * 0.025
        
        watermarkLayer.string = watermarkText
        watermarkLayer.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        watermarkLayer.fontSize = fontSize
        watermarkLayer.foregroundColor = UIColor.white.withAlphaComponent(0.85).cgColor
        watermarkLayer.backgroundColor = UIColor.black.withAlphaComponent(0.4).cgColor
        watermarkLayer.alignmentMode = .right
        watermarkLayer.contentsScale = UIScreen.main.scale
        watermarkLayer.cornerRadius = 6
        
        // Calculate size based on text
        let textSize = (watermarkText as NSString).size(withAttributes: [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        ])
        
        let padding: CGFloat = 12
        let margin: CGFloat = 16
        
        watermarkLayer.frame = CGRect(
            x: size.width - textSize.width - (padding * 2) - margin,
            y: margin,  // Bottom-right (CoreAnimation y is flipped)
            width: textSize.width + (padding * 2),
            height: textSize.height + (padding)
        )
        
        return watermarkLayer
    }
}
