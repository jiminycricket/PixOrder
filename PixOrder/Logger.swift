import Foundation
import os.log

public protocol LoggerDelegate: AnyObject {
    func logger(_ logger: Logger, didLogMessage message: String, level: LogLevel)
}

public enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}

public class Logger {
    public weak var delegate: LoggerDelegate?
    private let osLog = os.Logger(subsystem: "com.pixorder.mediacore", category: "classification")
    private let logFileURL: URL?
    
    public init(logToFile: Bool = false, logDirectory: URL? = nil) {
        if logToFile {
            let directory = logDirectory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let filename = "pixorder_\(formatter.string(from: Date())).log"
            logFileURL = directory.appendingPathComponent(filename)
        } else {
            logFileURL = nil
        }
    }
    
    public func log(_ message: String, level: LogLevel = .info) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.rawValue)] \(message)"
        
        // Log to system log
        osLog.log(level: level.osLogType, "\(message)")
        
        // Log to file if configured
        if logFileURL != nil {
            writeToFile(logMessage)
        }
        
        // Notify delegate
        delegate?.logger(self, didLogMessage: logMessage, level: level)
    }
    
    public func logClassificationStart(totalFiles: Int, sourceDirectory: URL) {
        log("Starting classification of \(totalFiles) files from \(sourceDirectory.path)")
    }
    
    public func logClassificationResult(_ result: ClassificationResult) {
        if result.success {
            let ruleName = result.matchedRule?.name ?? "No matching rule"
            log("✓ \(result.originalURL.lastPathComponent) (\(result.aspectRatio)) → \(ruleName)")
        } else {
            let errorMsg = result.error?.localizedDescription ?? "Unknown error"
            log("✗ \(result.originalURL.lastPathComponent): \(errorMsg)", level: .error)
        }
    }
    
    public func logClassificationSummary(_ summary: ClassificationSummary) {
        log("Classification completed in \(String(format: "%.2f", summary.duration))s")
        log("Results: \(summary.successfulFiles)/\(summary.totalFiles) files processed successfully")
        
        if summary.failedFiles > 0 {
            log("Failed to process \(summary.failedFiles) files", level: .warning)
        }
        
        // Log distribution by rule
        let ruleDistribution = Dictionary(grouping: summary.results.compactMap { $0.matchedRule }) { $0.name }
        for (ruleName, rules) in ruleDistribution {
            log("  \(ruleName): \(rules.count) files")
        }
    }
    
    private func writeToFile(_ message: String) {
        guard let logFileURL = logFileURL else { return }
        
        let messageWithNewline = message + "\n"
        if let data = messageWithNewline.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }
}

private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}