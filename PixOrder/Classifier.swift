import Foundation

// MARK: - Result Types

public struct ClassificationResult {
    public let originalURL: URL
    public let destinationURL: URL?
    public let aspectRatio: AspectRatio
    public let matchedRule: Rule?
    public let success: Bool
    public let error: Error?
    
    public init(
        originalURL: URL,
        destinationURL: URL? = nil,
        aspectRatio: AspectRatio,
        matchedRule: Rule? = nil,
        success: Bool,
        error: Error? = nil
    ) {
        self.originalURL = originalURL
        self.destinationURL = destinationURL
        self.aspectRatio = aspectRatio
        self.matchedRule = matchedRule
        self.success = success
        self.error = error
    }
}

public struct ClassificationSummary {
    public let startTime: Date
    public let endTime: Date
    public let totalFiles: Int
    public let successfulFiles: Int
    public let failedFiles: Int
    public let results: [ClassificationResult]
    
    public init(
        startTime: Date,
        endTime: Date,
        totalFiles: Int,
        successfulFiles: Int,
        failedFiles: Int,
        results: [ClassificationResult]
    ) {
        self.startTime = startTime
        self.endTime = endTime
        self.totalFiles = totalFiles
        self.successfulFiles = successfulFiles
        self.failedFiles = failedFiles
        self.results = results
    }
    
    public var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    public var successRate: Double {
        guard totalFiles > 0 else { return 0 }
        return Double(successfulFiles) / Double(totalFiles)
    }
}

// MARK: - Delegate Protocol

public protocol ClassifierDelegate: AnyObject {
    func classifier(_ classifier: Classifier, didStartProcessing totalFiles: Int)
    func classifier(_ classifier: Classifier, didProcessFile fileIndex: Int, totalFiles: Int, result: ClassificationResult)
    func classifier(_ classifier: Classifier, didCompleteWith summary: ClassificationSummary)
}

public enum ClassificationMode {
    case move
    case copy
    case dryRun
}

public enum ConflictResolution {
    case skip
    case rename
    case overwrite
}

public struct ClassificationOptions {
    public let mode: ClassificationMode
    public let conflictResolution: ConflictResolution
    public let createSubfolders: Bool
    public let defaultFolderName: String
    
    public init(
        mode: ClassificationMode = .move,
        conflictResolution: ConflictResolution = .rename,
        createSubfolders: Bool = true,
        defaultFolderName: String = "Other"
    ) {
        self.mode = mode
        self.conflictResolution = conflictResolution
        self.createSubfolders = createSubfolders
        self.defaultFolderName = defaultFolderName
    }
}

public class Classifier {
    public weak var delegate: ClassifierDelegate?
    
    private let metadataReader = MetadataReader()
    private let ratioCalculator = RatioCalculator()
    private let logger: Logger
    private let fileManager = FileManager.default
    
    // Control state for pause/resume/cancel
    private var isPaused: Bool = false
    private var isCancelled: Bool = false
    
    public init(logger: Logger = Logger()) {
        self.logger = logger
    }
    
    // Public methods to control the classification process
    public func pause() {
        isPaused = true
    }
    
    public func resume() {
        isPaused = false
    }
    
    public func cancel() {
        isCancelled = true
        isPaused = false
    }
    
    public func resetControlState() {
        isPaused = false
        isCancelled = false
    }
    
    public func classify(
        mediaFiles: [URL],
        using ruleSet: RuleSet,
        in baseDirectory: URL,
        options: ClassificationOptions = ClassificationOptions()
    ) async throws -> ClassificationSummary {
        let startTime = Date()
        
        logger.logClassificationStart(totalFiles: mediaFiles.count, sourceDirectory: baseDirectory)
        delegate?.classifier(self, didStartProcessing: mediaFiles.count)
        
        var results: [ClassificationResult] = []
        var successCount = 0
        
        for (index, mediaFile) in mediaFiles.enumerated() {
            // Check for cancellation
            if isCancelled {
                logger.log("Classification cancelled by user", level: .info)
                break
            }
            
            // Check for pause and wait
            while isPaused && !isCancelled {
                try await Task.sleep(nanoseconds: 100_000_000) // Sleep for 0.1 seconds
            }
            
            // Check again for cancellation after pause
            if isCancelled {
                logger.log("Classification cancelled by user", level: .info)
                break
            }
            
            let result = await processFile(
                mediaFile,
                using: ruleSet,
                in: baseDirectory,
                options: options
            )
            
            results.append(result)
            if result.success {
                successCount += 1
            }
            
            logger.logClassificationResult(result)
            delegate?.classifier(self, didProcessFile: index + 1, totalFiles: mediaFiles.count, result: result)
        }
        
        let endTime = Date()
        let summary = ClassificationSummary(
            startTime: startTime,
            endTime: endTime,
            totalFiles: mediaFiles.count,
            successfulFiles: successCount,
            failedFiles: mediaFiles.count - successCount,
            results: results
        )
        
        logger.logClassificationSummary(summary)
        delegate?.classifier(self, didCompleteWith: summary)
        
        return summary
    }
    
    private func processFile(
        _ mediaFile: URL,
        using ruleSet: RuleSet,
        in baseDirectory: URL,
        options: ClassificationOptions
    ) async -> ClassificationResult {
        do {
            // Get file dimensions
            let dimensions = try await metadataReader.getDimensions(for: mediaFile)
            let aspectRatio = ratioCalculator.calculateRatio(from: dimensions)
            
            // Find matching rule
            let matchedRule = ruleSet.findMatchingRule(for: aspectRatio)
            let targetFolderName = matchedRule?.destinationPath ?? options.defaultFolderName
            
            // Determine destination
            let destinationFolder = baseDirectory.appendingPathComponent(targetFolderName)
            let destinationURL = destinationFolder.appendingPathComponent(mediaFile.lastPathComponent)
            
            // Create destination folder if needed
            if options.createSubfolders && options.mode != .dryRun {
                try fileManager.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
            }
            
            // Handle the file operation
            if options.mode != .dryRun {
                let finalDestination = try await handleFileOperation(
                    from: mediaFile,
                    to: destinationURL,
                    mode: options.mode,
                    conflictResolution: options.conflictResolution
                )
                
                return ClassificationResult(
                    originalURL: mediaFile,
                    destinationURL: finalDestination,
                    aspectRatio: aspectRatio,
                    matchedRule: matchedRule,
                    success: true
                )
            } else {
                return ClassificationResult(
                    originalURL: mediaFile,
                    destinationURL: destinationURL,
                    aspectRatio: aspectRatio,
                    matchedRule: matchedRule,
                    success: true
                )
            }
            
        } catch {
            return ClassificationResult(
                originalURL: mediaFile,
                aspectRatio: AspectRatio(ratio: 0),
                success: false,
                error: error
            )
        }
    }
    
    private func handleFileOperation(
        from source: URL,
        to destination: URL,
        mode: ClassificationMode,
        conflictResolution: ConflictResolution
    ) async throws -> URL {
        var finalDestination = destination
        
        // Handle conflicts
        if fileManager.fileExists(atPath: destination.path) {
            switch conflictResolution {
            case .skip:
                throw ClassifierError.fileSkipped
            case .overwrite:
                try fileManager.removeItem(at: destination)
            case .rename:
                finalDestination = generateUniqueFilename(for: destination)
            }
        }
        
        // Perform the operation
        switch mode {
        case .move:
            try fileManager.moveItem(at: source, to: finalDestination)
        case .copy:
            try fileManager.copyItem(at: source, to: finalDestination)
        case .dryRun:
            break // Already handled above
        }
        
        return finalDestination
    }
    
    private func generateUniqueFilename(for url: URL) -> URL {
        let directory = url.deletingLastPathComponent()
        let filename = url.deletingPathExtension().lastPathComponent
        let pathExtension = url.pathExtension
        
        var counter = 1
        var newURL: URL
        
        repeat {
            let newFilename = "\(filename)_\(counter).\(pathExtension)"
            newURL = directory.appendingPathComponent(newFilename)
            counter += 1
        } while fileManager.fileExists(atPath: newURL.path)
        
        return newURL
    }
}

public enum ClassifierError: Error, LocalizedError {
    case fileSkipped
    case cannotCreateDirectory
    case fileOperationFailed
    
    public var errorDescription: String? {
        switch self {
        case .fileSkipped:
            return "File was skipped due to conflict"
        case .cannotCreateDirectory:
            return "Cannot create destination directory"
        case .fileOperationFailed:
            return "File operation failed"
        }
    }
}