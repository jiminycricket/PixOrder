# PixOrder - Media File Organizer

[![Website](https://img.shields.io/badge/Website-PixOrder.github.io-green?style=flat-square)](https://jiminycricket.github.io/PixOrder)
[![GitHub release](https://img.shields.io/github/v/release/jiminycricket/PixOrder?style=flat-square)](https://github.com/jiminycricket/PixOrder/releases)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-13.0+-000000?style=flat-square&logo=apple)](https://www.apple.com/macos/)

PixOrder is a macOS application that automatically organizes and classifies your photos and videos based on their aspect ratios.

**🌐 [Visit Official Website →](https://jiminycricket.github.io/PixOrder)**

## Features

✨ **Smart Classification** - Automatically categorize media files by aspect ratio  
📱 **Multi-format Support** - Supports JPEG, PNG, HEIF, MOV, MP4, and more  
🔄 **Safe Operations** - Copy or move modes to ensure file safety  
📊 **Real-time Progress** - Live progress tracking with detailed logging  
🎯 **Smart Conflict Resolution** - Automatic duplicate filename handling  

## System Requirements

- macOS 13.0 or later
- Apple Silicon (M1/M2/M3) or Intel processor

## Installation

### 🌐 Visit Our Website

**[📁 PixOrder.github.io →](https://jiminycricket.github.io/PixOrder)**

Complete project information, screenshots, and direct downloads.

### For End Users

#### Option 1: From Website (Recommended)
1. Visit our [official website](https://jiminycricket.github.io/PixOrder)
2. Click the download button for your preferred format
3. Install by dragging `PixOrder.app` to your `/Applications` folder

#### Option 2: From GitHub Releases
1. Download the latest release from the [Releases](../../releases) page
2. Choose either `PixOrder.dmg` (recommended) or `PixOrder.zip`
3. Install by dragging `PixOrder.app` to your `/Applications` folder
4. Launch from Applications folder

### For Developers

#### Prerequisites
- Xcode 15.0 or later
- macOS 13.0 or later
- Swift 5.9 or later

#### Building from Source

1. **Clone the repository**:
   ```bash
   git clone https://github.com/jiminycricket/PixOrder.git
   cd PixOrder
   ```

2. **Open in Xcode**:
   ```bash
   open PixOrder.xcodeproj
   ```

3. **Configure Code Signing** (Optional):
   - For development: Xcode handles signing automatically
   - For distribution: Set up environment variable for command-line builds
   
   ```bash
   # Find your signing identity
   security find-identity -p codesigning -v
   
   # Set environment variable (add to your ~/.zshrc or ~/.bash_profile)
   export CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"
   # or
   export CODE_SIGN_IDENTITY="Apple Development: your.email@example.com (TEAM_ID)"
   ```
   - Ensure "Automatically manage signing" is checked
   - Update the Bundle Identifier if needed to match your developer account

4. **Build and Run**:
   - Press `Cmd+R` to build and run
   - Or use the menu: Product → Run

#### Code Signing Notes

This project uses automatic code signing. To build and run:

- **If you have an Apple Developer Account**: Xcode will automatically use your developer certificate for signing
- **If you don't have a developer account**: Xcode will generate a local development certificate automatically
- **For contributors**: No special setup needed - Xcode handles local development signing automatically

The `DEVELOPMENT_TEAM` in the project file is the original author's team ID. You can:
- Leave it as-is (Xcode will override with your team automatically)
- Change it to your own team ID
- Set it to empty for fully manual configuration

## Usage

1. **Select Source Folder** - Click the folder icon next to "Source Folder" to choose a folder containing media files
2. **Select Target Folder** (optional) - Click the plus icon next to "Target Folder (Optional)" to choose a different destination, or leave empty to organize within the source folder
3. **Choose Operation Mode** - Toggle between "Copy" and "Move" modes using the segmented control
4. **Configure Subfolders** - Use the "Include Subfolders" toggle to process files in subdirectories
5. **Start Classification** - Click the "Start" button to begin automatic sorting
6. **Monitor Progress** - View real-time progress with the progress bar and detailed operation logs
7. **Control Processing** - Use "Pause" and "Resume" to control the operation, or "Cancel" to stop

## Classification Rules

PixOrder automatically creates folders and sorts files based on these aspect ratio rules:

- **Square** (1:1) - Square images
- **Landscape_16-9** - 16:9 landscape images/videos  
- **Landscape_4-3** - 4:3 landscape images
- **Portrait_9-16** - 9:16 portrait images/videos
- **Portrait_3-4** - 3:4 portrait images
- **Other** - Files with other aspect ratios

## Development

### Project Structure

```
PixOrder/
├── main.swift              # Main app with SwiftUI interface
├── Classifier.swift        # Core classification engine
├── Logger.swift           # Logging functionality
├── MediaScanner.swift     # File system scanning
├── MetadataReader.swift   # Image/video metadata extraction
├── RatioCalculator.swift  # Aspect ratio calculations
├── Rule.swift             # Classification rules
├── Assets.xcassets/       # App icon and assets
├── Info.plist             # App configuration
└── PixOrder.entitlements  # Sandbox permissions
```

### Architecture

- **Framework**: Native macOS app using AppKit with SwiftUI integration
- **Language**: Swift 5.0+
- **UI**: SwiftUI views embedded in NSHostingView within NSWindow
- **Deployment Target**: macOS 13.0+
- **Concurrency**: Uses async/await for file operations with MainActor for UI updates

### Build Commands

```bash
# Build for development (Debug)
xcodebuild -project PixOrder.xcodeproj -scheme PixOrder -configuration Debug build

# Build for release
xcodebuild -project PixOrder.xcodeproj -scheme PixOrder -configuration Release build

# Create distribution package
./deploy.sh
```

### Contributing

We welcome contributions! Please see our [website](https://jiminycricket.github.io/PixOrder) for the latest information.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure your code:
- Follows Swift style conventions
- Includes appropriate comments
- Maintains the existing architecture patterns
- Handles errors appropriately

## Links

- **🌐 Official Website**: [PixOrder.github.io](https://jiminycricket.github.io/PixOrder)
- **📦 Latest Release**: [GitHub Releases](https://github.com/jiminycricket/PixOrder/releases)
- **🐛 Report Issues**: [GitHub Issues](https://github.com/jiminycricket/PixOrder/issues)
- **📖 Documentation**: [Project Wiki](https://github.com/jiminycricket/PixOrder/wiki)

## Important Notes

- First launch may show macOS security warnings - allow execution in System Preferences → Security & Privacy
- The app will request folder access permissions as required by macOS sandbox security
- Test with "Copy" mode before using "Move" mode on important files
- All file operations are logged for transparency

## Technical Details

- **Language**: Swift 5.0+
- **UI Framework**: SwiftUI + AppKit
- **Architecture**: Universal Binary (Apple Silicon + Intel)
- **Security**: App Sandbox enabled
- **Minimum OS**: macOS 13.0

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Version History

**Current Version**: 1.0.0  
**Last Updated**: 2025-08-06