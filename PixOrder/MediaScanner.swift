import Foundation
import UniformTypeIdentifiers

public enum MediaScannerError: Error, LocalizedError {
    case notADirectory
    case accessDenied
    case invalidPath
    
    public var errorDescription: String? {
        switch self {
        case .notADirectory:
            return "The specified path is not a directory"
        case .accessDenied:
            return "Access denied to the specified directory"
        case .invalidPath:
            return "The specified path is invalid"
        }
    }
}

public struct MediaScanner {
    public init() {}
    
    public func scanFolder(at url: URL, includeSubfolders: Bool = true) async throws -> [URL] {
        guard url.hasDirectoryPath else {
            throw MediaScannerError.notADirectory
        }
        
        let fileManager = FileManager.default
        var mediaFiles: [URL] = []
        
        if includeSubfolders {
            let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey, .contentTypeKey],
                options: [.skipsHiddenFiles]
            )
            
            while let fileURL = enumerator?.nextObject() as? URL {
                if try await isMediaFile(fileURL) {
                    mediaFiles.append(fileURL)
                }
            }
        } else {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey, .contentTypeKey],
                options: [.skipsHiddenFiles]
            )
            
            for fileURL in contents {
                if try await isMediaFile(fileURL) {
                    mediaFiles.append(fileURL)
                }
            }
        }
        
        return mediaFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
    
    private func isMediaFile(_ url: URL) async throws -> Bool {
        let resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey, .contentTypeKey])
        
        guard let isRegularFile = resourceValues.isRegularFile, isRegularFile else {
            return false
        }
        
        guard let contentType = resourceValues.contentType else {
            return false
        }
        
        return contentType.conforms(to: .image) || contentType.conforms(to: .movie)
    }
}