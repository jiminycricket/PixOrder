# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **PixOrder** - a macOS media file classification application built with Swift, SwiftUI, and AppKit. The application provides a modern GUI interface for organizing media files by aspect ratio with real-time progress tracking and smart conflict resolution.

## Project Structure

```
PixOrder.xcodeproj/              # Xcode project file
PixOrder/                        # Main application source code
├── main.swift                   # Main GUI application with AppDelegate
├── Classifier.swift             # Core media classification engine
├── Logger.swift                 # Logging functionality
├── MediaScanner.swift           # File system scanning for media files
├── MetadataReader.swift         # Image/video metadata extraction
├── RatioCalculator.swift        # Aspect ratio calculation utilities
├── Rule.swift                   # Classification rules and data structures
├── Info.plist                   # Application configuration
└── PixOrder.entitlements        # App sandbox entitlements
```

## Architecture

- **Framework**: Native macOS app using AppKit with SwiftUI integration
- **Language**: Swift 5.0+
- **UI**: SwiftUI views embedded in NSHostingView within NSWindow
- **Deployment Target**: macOS 13.0+
- **App Structure**: Single-target macOS application with modern GUI interface
- **Concurrency**: Uses async/await for file operations and Task/MainActor for UI updates

### Core Components

1. **SwiftUI Interface**: Modern, declarative UI with real-time progress updates
2. **AppDelegate**: NSApplication delegate managing window lifecycle and coordination
3. **Media Classification Engine**: Core logic for scanning, analyzing, and organizing files
4. **Delegate Pattern**: Progress reporting through ClassifierDelegate protocol

## Key Features

### Media Classification
- **Supported Formats**: JPEG, PNG, HEIF, MOV, MP4, and more
- **Aspect Ratio Detection**: Automatically detects and classifies by aspect ratios
- **EXIF Orientation Support**: Correctly handles rotated photos from cameras/phones
- **Default Classification Rules**:
  - Square (1:1) → Square folder
  - Landscape 16:9 → Landscape_16-9 folder
  - Landscape 4:3 → Landscape_4-3 folder
  - Portrait 9:16 → Portrait_9-16 folder
  - Portrait 3:4 → Portrait_3-4 folder
  - Other ratios → Other folder

### Application Features
- **GUI Application**: Interactive interface with folder selection, progress bars, and detailed feedback
- **Operation Modes**: Copy or Move files to organized folders
- **Conflict Resolution**: Automatic file renaming when duplicates exist
- **Safety Features**: Preview mode before actual file operations

## Development Commands

### Build and Run
```bash
# Open in Xcode
open PixOrder.xcodeproj

# Build for development (Debug configuration)
xcodebuild -project PixOrder.xcodeproj -scheme PixOrder -configuration Debug build

# Build for release
xcodebuild -project PixOrder.xcodeproj -scheme PixOrder -configuration Release build

# Run directly from command line
xcodebuild -project PixOrder.xcodeproj -scheme PixOrder -configuration Debug build && open build/Debug/PixOrder.app
```

### Distribution
```bash
# Create DMG for distribution
hdiutil create -volname "PixOrder" -srcfolder build/Release/PixOrder.app -ov -format UDZO PixOrder.dmg
```

## Usage Instructions

### Main Application
1. Launch PixOrder.app
2. Click "選擇資料夾" to select a folder containing media files
3. Choose operation mode (Copy or Move)
4. Click "開始分類" to classify files by aspect ratio
5. Monitor progress and view completion summary

## Development Notes

### Code Architecture
- **Modular Design**: Core logic separated from UI for reusability
- **SwiftUI + AppKit**: Modern SwiftUI interface wrapped in NSHostingView
- **Async/Await**: Modern Swift concurrency for file operations with proper MainActor usage
- **Delegate Pattern**: Progress reporting through ClassifierDelegate protocol
- **Error Handling**: Comprehensive error handling with user-friendly alert dialogs

### Key Implementation Details
- **UI Threading**: UI updates are performed on MainActor, file operations on background tasks
- **Progress Tracking**: Real-time progress updates with percentage and file counts
- **Conflict Resolution**: Automatic handling of duplicate filenames with rename strategy
- **Metadata Reading**: Uses ImageIO/AVFoundation for efficient metadata extraction
- **Operation Modes**: Support for both copy and move operations with user selection

### File Organization Structure
```
main.swift:147-419        # AppDelegate class with SwiftUI integration
main.swift:1-146          # SwiftUI views and UI components
main.swift:393-413        # ClassifierDelegate implementation
Classifier.swift          # Core classification engine and result types
MediaScanner.swift        # File system scanning for media files
MetadataReader.swift      # Image/video metadata extraction
RatioCalculator.swift     # Aspect ratio calculation utilities
Rule.swift               # Classification rules and data structures
Logger.swift             # Logging functionality
```

## Important Notes

- App sandbox is enabled for Mac App Store compatibility
- No testing framework is currently implemented
- File operations require user consent through NSOpenPanel folder selection
- All media classification logic is self-contained within the main application target