import Foundation
import ImageIO
import AVFoundation
import CoreGraphics

public struct MediaDimensions {
    public let width: CGFloat
    public let height: CGFloat
    
    public init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
}

public struct MetadataReader {
    public init() {}
    
    public func getDimensions(for mediaURL: URL) async throws -> MediaDimensions {
        let resourceValues = try mediaURL.resourceValues(forKeys: [.contentTypeKey])
        guard let contentType = resourceValues.contentType else {
            throw MetadataReaderError.unsupportedFileType
        }
        
        if contentType.conforms(to: .image) {
            return try await getImageDimensions(from: mediaURL)
        } else if contentType.conforms(to: .movie) {
            return try await getVideoDimensions(from: mediaURL)
        } else {
            throw MetadataReaderError.unsupportedFileType
        }
    }
    
    private func getImageDimensions(from url: URL) async throws -> MediaDimensions {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw MetadataReaderError.cannotReadFile
        }
        
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            throw MetadataReaderError.cannotReadMetadata
        }
        
        guard let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            throw MetadataReaderError.cannotReadDimensions
        }
        
        // Check EXIF orientation to determine if image is rotated
        let orientation = getImageOrientation(from: properties)
        
        // If orientation indicates the image is rotated 90° or 270°, swap width and height
        let finalDimensions: MediaDimensions
        if shouldSwapDimensions(for: orientation) {
            finalDimensions = MediaDimensions(width: height, height: width)
        } else {
            finalDimensions = MediaDimensions(width: width, height: height)
        }
        
        return finalDimensions
    }
    
    private func getImageOrientation(from properties: [CFString: Any]) -> Int {
        // Check for root level orientation first (most common location)
        if let orientation = properties[kCGImagePropertyOrientation] as? Int {
            return orientation
        }
        
        // Check for TIFF orientation (fallback)
        if let tiffDict = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any],
           let orientation = tiffDict[kCGImagePropertyTIFFOrientation] as? Int {
            return orientation
        }
        
        return 1 // Default orientation (no rotation)
    }
    
    private func shouldSwapDimensions(for orientation: Int) -> Bool {
        // EXIF orientation values:
        // 1 = Normal (0°)
        // 2 = Flip horizontal
        // 3 = Rotate 180°
        // 4 = Flip vertical
        // 5 = Rotate 90° CW + flip horizontal
        // 6 = Rotate 90° CW
        // 7 = Rotate 90° CCW + flip horizontal  
        // 8 = Rotate 90° CCW
        
        switch orientation {
        case 5, 6, 7, 8:
            return true // 90° or 270° rotation
        default:
            return false // No rotation or 180° rotation
        }
    }
    
    private func getVideoDimensions(from url: URL) async throws -> MediaDimensions {
        let asset = AVURLAsset(url: url)
        
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = tracks.first else {
            throw MetadataReaderError.noVideoTrack
        }
        
        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        
        let transformedSize = naturalSize.applying(preferredTransform)
        let width = abs(transformedSize.width)
        let height = abs(transformedSize.height)
        
        return MediaDimensions(width: width, height: height)
    }
}

public enum MetadataReaderError: Error, LocalizedError {
    case unsupportedFileType
    case cannotReadFile
    case cannotReadMetadata
    case cannotReadDimensions
    case noVideoTrack
    
    public var errorDescription: String? {
        switch self {
        case .unsupportedFileType:
            return "Unsupported file type"
        case .cannotReadFile:
            return "Cannot read file"
        case .cannotReadMetadata:
            return "Cannot read file metadata"
        case .cannotReadDimensions:
            return "Cannot read file dimensions"
        case .noVideoTrack:
            return "Video file has no video track"
        }
    }
}