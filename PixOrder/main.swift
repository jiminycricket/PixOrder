import Cocoa
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Color Tokens
extension Color {
    // Brand Color Palette
    static let brandFeldgrau = Color(hex: "3C493F")        // Primary dark - headers, emphasis
    static let brandBattleship = Color(hex: "7E8D85")      // Secondary - buttons, accents
    static let brandAshGray = Color(hex: "B3BFB8")         // Tertiary - borders, dividers
    static let brandMintCream = Color(hex: "F0F7F4")       // Background - cards, surfaces
    static let brandCeladon = Color(hex: "A2E3C4")         // Accent - success, highlights
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - AppState ObservableObject
class AppState: ObservableObject {
    @Published var selectedFolderURL: URL? = nil
    @Published var targetFolderURL: URL? = nil
    @Published var operationMode: Int = 1
    @Published var includeSubfolders: Bool = false
    @Published var isProcessing: Bool = false
    @Published var isPaused: Bool = false
    @Published var isCancelled: Bool = false
    @Published var progress: Double = 0.0
    @Published var statusText: String = ""
    @Published var logMessages: [String] = []
    @Published var showLogView: Bool = false
}

// MARK: - SwiftUI Views
struct PixOrderSwiftUIView: View {
    @ObservedObject var appState: AppState
    
    let onSelectFolder: () -> Void
    let onSelectTargetFolder: () -> Void
    let onStartSorting: () -> Void
    let onPauseResume: () -> Void
    let onCancel: () -> Void
    
    // Computed properties for dynamic button states
    private var buttonText: String {
        if !appState.isProcessing {
            return "Start"
        } else if appState.isPaused {
            return "Resume"
        } else {
            return "Pause"
        }
    }
    
    private var buttonIcon: String {
        if !appState.isProcessing {
            return "play.fill"
        } else if appState.isPaused {
            return "play.fill"
        } else {
            return "pause.fill"
        }
    }
    
    private var buttonColor: Color {
        if !appState.isProcessing {
            return .brandCeladon
        } else if appState.isPaused {
            return .brandCeladon
        } else {
            return .brandFeldgrau
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 5) {
                Text("PixOrder")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(.brandMintCream)
                
                Text("Media File Organizer")
                    .font(.system(size: 13, weight: .ultraLight))
                    .foregroundColor(.brandCeladon)
            }
            
            // Selection and Operation
            VStack(spacing: 12) {
                    // Source Folder
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "folder")
                                .font(.system(size: 13))
                                .foregroundColor(.brandMintCream)
                            Text("Source Folder")
                                .font(.system(size: 13, weight: .ultraLight))
                                .foregroundColor(.brandMintCream)

                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.selectedFolderURL?.lastPathComponent ?? "Select source folder")
                                    .font(.system(size: 14, weight: .ultraLight))
                                    .foregroundColor(appState.selectedFolderURL != nil ? .primary : .secondary)
                                    .lineLimit(1)
                                
                                if let url = appState.selectedFolderURL {
                                    Text(url.path)
                                        .font(.system(size: 10, weight: .ultraLight))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: onSelectFolder) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(DisableableButtonStyle(color: .brandFeldgrau, isDisabled: appState.isProcessing))
                            .disabled(appState.isProcessing)
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Target Folder (Optional)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 13))
                                .foregroundColor(.brandMintCream)
                            Text("Target Folder (Optional)")
                                .font(.system(size: 13, weight: .ultraLight))
                                .foregroundColor(.brandMintCream)
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(appState.targetFolderURL?.lastPathComponent ?? "Same as source")
                                    .font(.system(size: 14, weight: .ultraLight))
                                    .foregroundColor(appState.targetFolderURL != nil ? .primary : .secondary)
                                    .lineLimit(1)
                                
                                Text("Leave empty to use source folder location")
                                    .font(.system(size: 10, weight: .ultraLight))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                if appState.targetFolderURL != nil {
                                    Button(action: {
                                        appState.targetFolderURL = nil
                                    }) {
                                        Image(systemName: "xmark.circle")
                                            .font(.system(size: 14))
                                    }
                                    .buttonStyle(DisableableButtonStyle(color: .brandFeldgrau, isDisabled: appState.isProcessing))
                                    .disabled(appState.isProcessing)
                                    .onHover { hovering in
                                        if hovering {
                                            NSCursor.pointingHand.push()
                                        } else {
                                            NSCursor.pop()
                                        }
                                    }
                                }
                                
                                Button(action: onSelectTargetFolder) {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 14))
                                }
                                .buttonStyle(DisableableButtonStyle(color: .brandFeldgrau, isDisabled: appState.isProcessing))
                                .disabled(appState.isProcessing)
                                .onHover { hovering in
                                    if hovering {
                                        NSCursor.pointingHand.push()
                                    } else {
                                        NSCursor.pop()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Operation Mode
                    HStack(spacing: 8) {
                        Image(systemName: "gear")
                            .font(.system(size: 13))
                            .foregroundColor(.brandMintCream)
                        Text("Mode")
                            .font(.system(size: 13, weight: .ultraLight))
                            .foregroundColor(.brandMintCream)
                        
                        Spacer()
                        
                        Picker("", selection: $appState.operationMode) {
                            Text("Copy").tag(0)
                            Text("Move").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 120)
                        .disabled(appState.isProcessing)
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Subfolders Toggle
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill.badge.questionmark")
                            .font(.system(size: 13))
                            .foregroundColor(.brandMintCream)
                        Text("Include Subfolders")
                            .font(.system(size: 13, weight: .ultraLight))
                            .foregroundColor(.brandMintCream)
                        
                        Spacer()
                        
                        Toggle("", isOn: $appState.includeSubfolders)
                            .toggleStyle(CustomToggleStyle())
                            .disabled(appState.isProcessing)
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                    }
                    .padding(.vertical, 4)
                    
                    Divider()
                        .overlay(Color.brandAshGray)
                        .padding(.vertical, 4)
                }
            
            // Action and Progress
            VStack(spacing: 15) {
                    HStack(spacing: 10) {
                        Spacer()
                        
                        // Cancel button (only show when processing)
                        if appState.isProcessing {
                            Button(action: onCancel) {
                                HStack {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 15))
                                    Text("Cancel")
                                        .font(.system(size: 15, weight: .ultraLight))
                                }
                            }
                            .buttonStyle(FlatButtonStyle(color: .brandFeldgrau))
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                        
                        // Main action button (Start/Pause/Resume) - always on the right
                        Button(action: appState.isProcessing ? onPauseResume : onStartSorting) {
                            HStack {
                                Image(systemName: buttonIcon)
                                    .font(.system(size: 15))
                                Text(buttonText)
                                    .font(.system(size: 15, weight: .ultraLight))
                            }
                        }
                        .buttonStyle(FlatButtonStyle(color: buttonColor))
                        .disabled(appState.selectedFolderURL == nil && !appState.isProcessing)
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    }
                    
                    VStack(spacing: 8) {
                        ProgressView(value: appState.progress, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: .brandCeladon))
                            .frame(height: 8)
                            .opacity(appState.isProcessing ? 1.0 : 0.3)
                        
                        HStack {
                            Spacer()
                            Text(appState.statusText.isEmpty ? "Ready to organize" : appState.statusText)
                                .font(.system(size: 13, weight: .ultraLight))
                                .foregroundColor(.brandMintCream)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                .padding(.vertical, 4)
            
            // Features or Logs
            if appState.showLogView {
                LogView(logMessages: appState.logMessages)
            } else {
                VStack(spacing: 10) {
                    SectionHeader("Smart Organization Features", fontSize: 15, weight: .ultraLight)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13))
                                .foregroundColor(.brandAshGray)
                            Text("Automatic organization by aspect ratio")
                        }
                        HStack {
                            Image(systemName: "camera")
                                .font(.system(size: 13))
                                .foregroundColor(.brandAshGray)
                            Text("Supports JPEG, PNG, HEIF, MOV, MP4 and more")
                        }
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 13))
                                .foregroundColor(.brandAshGray)
                            Text("Safe copy or move operations")
                        }
                        HStack {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 13))
                                .foregroundColor(.brandAshGray)
                            Text("Real-time progress tracking")
                        }
                        HStack {
                            Image(systemName: "target")
                                .font(.system(size: 13))
                                .foregroundColor(.brandAshGray)
                            Text("Smart conflict resolution")
                        }
                    }
                    .font(.system(size: 13, weight: .ultraLight))
                    .foregroundColor(.brandAshGray)
                }
            }
        }
        .padding(30)
        .background(Color(hex: "2d2d2d"))
    }
}

// MARK: - Shared UI Components

struct LogView: View {
    let logMessages: [String]
    
    var body: some View {
        VStack(spacing: 10) {
            SectionHeader("Processing Log", fontSize: 15, weight: .ultraLight)
            
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(logMessages.enumerated()), id: \.offset) { index, message in
                            Text(message)
                                .font(.system(size: 11, weight: .ultraLight, design: .monospaced))
                                .foregroundColor(.brandMintCream)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .onChange(of: logMessages.count) { newCount in
                        if newCount > 0 {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(newCount - 1, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .frame(height: 100)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.brandAshGray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct CardContainer<Content: View>: View {
    let content: Content
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let showShadow: Bool
    
    init(
        cornerRadius: CGFloat = 10,
        horizontalPadding: CGFloat = 25,
        verticalPadding: CGFloat = 25,
        showShadow: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.showShadow = showShadow
    }
    
    var body: some View {
        VStack {
            content
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(Color.brandFeldgrau)
        .cornerRadius(cornerRadius)
        .shadow(color: showShadow ? Color.brandFeldgrau.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
    }
}

struct SectionHeader: View {
    let title: String
    let fontSize: CGFloat
    let weight: Font.Weight
    
    init(_ title: String, fontSize: CGFloat = 14, weight: Font.Weight = .ultraLight) {
        self.title = title
        self.fontSize = fontSize
        self.weight = weight
    }
    
    var body: some View {
        Text(title)
            .font(.system(size: fontSize, weight: weight))
            .foregroundColor(.brandMintCream)
    }
}

struct FlatButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.brandCeladon)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.brandCeladon, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .contentShape(Rectangle())
    }
}

struct DisableableButtonStyle: ButtonStyle {
    let color: Color
    let isDisabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isDisabled ? Color.gray : .brandCeladon)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isDisabled ? Color.gray : Color.brandCeladon, lineWidth: 0.5)
            )
            .scaleEffect(configuration.isPressed && !isDisabled ? 0.95 : 1.0)
            .opacity((configuration.isPressed && !isDisabled) ? 0.7 : 1.0)
            .contentShape(Rectangle())
    }
}

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(configuration.isOn ? Color.brandFeldgrau : Color.gray.opacity(0.3))
            .frame(width: 48, height: 28)
            .overlay(
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
            )
            .onTapGesture {
                configuration.isOn.toggle()
            }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let appState = AppState()
    
    var classifier: Classifier!
    var logger: Logger!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize classifier
        logger = Logger()
        logger.delegate = self
        classifier = Classifier(logger: logger)
        classifier.delegate = self
        
        setupWindow()
        setupSwiftUI()
    }
    
    func setupWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 720),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "PixOrder - Media File Organizer"
        window.backgroundColor = NSColor(Color.brandFeldgrau)
        window.isRestorable = false
        // 禁止用戶調整大小
        window.center()
    }
    
    func setupSwiftUI() {
        let swiftUIView = PixOrderSwiftUIView(
            appState: appState,
            onSelectFolder: { [weak self] in
                self?.selectFolder()
            },
            onSelectTargetFolder: { [weak self] in
                self?.selectTargetFolder()
            },
            onStartSorting: { [weak self] in
                self?.startSorting()
            },
            onPauseResume: { [weak self] in
                self?.pauseResume()
            },
            onCancel: { [weak self] in
                self?.cancelOperation()
            }
        )
        
        let hostingView = NSHostingView(rootView: swiftUIView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        guard let contentView = window.contentView else { return }
        contentView.addSubview(hostingView)
        
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Actions
    
    
    func selectFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.title = "Select Source Folder to Organize"
        
        if openPanel.runModal() == .OK {
            appState.selectedFolderURL = openPanel.url
        }
    }
    
    func selectTargetFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.title = "Select Target Folder for Organized Files"
        openPanel.message = "Choose where to save the organized files. Leave empty to use the same location as source folder."
        
        if openPanel.runModal() == .OK {
            appState.targetFolderURL = openPanel.url
        }
    }
    
    func startSorting() {
        guard let folderURL = appState.selectedFolderURL else { return }
        
        Task { @MainActor in
            appState.isCancelled = false
            appState.isPaused = false
            appState.logMessages.removeAll()
            appState.showLogView = true
            classifier.resetControlState()
            
            await performSorting(in: folderURL)
        }
    }
    
    func pauseResume() {
        Task { @MainActor in
            appState.isPaused.toggle()
            
            if appState.isPaused {
                classifier.pause()
                appState.statusText = "Operation paused"
            } else {
                classifier.resume()
                appState.statusText = "Resuming operation..."
            }
        }
    }
    
    func cancelOperation() {
        Task { @MainActor in
            appState.isCancelled = true
            appState.isPaused = false
            classifier.cancel()
            resetUI()
            appState.statusText = "Operation cancelled"
        }
    }
    
    func performSorting(in folderURL: URL) async {
        // Read operation mode, subfolder setting, and target folder on main thread first
        let (selectedMode, includeSubfolders, targetFolder) = await MainActor.run {
            let mode = appState.operationMode == 0 ? ClassificationMode.copy : ClassificationMode.move
            return (mode, appState.includeSubfolders, appState.targetFolderURL)
        }
        
        await MainActor.run {
            self.appState.isProcessing = true
            self.appState.progress = 0
            self.appState.statusText = includeSubfolders ? "Scanning media files in folder and subfolders..." : "Scanning media files in selected folder..."
        }
        
        do {
            // Scan media files
            let scanner = MediaScanner()
            print("Starting to scan folder: \(folderURL.path) (includeSubfolders: \(includeSubfolders))")
            let mediaFiles = try await scanner.scanFolder(at: folderURL, includeSubfolders: includeSubfolders)
            print("Found \(mediaFiles.count) media files")
            
            if mediaFiles.isEmpty {
                await MainActor.run {
                    self.showAlert(title: "No Media Files Found", message: "No supported image or video files were found in the selected folder.\n\nSupported formats: JPEG, PNG, HEIF, MOV, MP4, etc.")
                    self.resetUI()
                }
                return
            }
            
            // Use default rules for classification
            let ruleSet = RuleSet(rules: RuleSet.defaultRules)
            let options = ClassificationOptions(mode: selectedMode, conflictResolution: .rename)
            
            // Use target folder if specified, otherwise use source folder
            let destinationFolder = targetFolder ?? folderURL
            
            let summary = try await classifier.classify(
                mediaFiles: mediaFiles,
                using: ruleSet,
                in: destinationFolder,
                options: options
            )
            
            await MainActor.run {
                self.showCompletionAlert(summary: summary, mode: selectedMode)
                self.resetUI()
            }
            
        } catch {
            await MainActor.run {
                self.showAlert(title: "Organization Failed", message: "An error occurred during organization: \(error.localizedDescription)")
                self.resetUI()
            }
        }
    }
    
    @MainActor
    func resetUI() {
        appState.isProcessing = false
        appState.progress = 0
        appState.statusText = ""
        // Keep showLogView and logMessages visible after processing
    }
    
    @MainActor
    func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @MainActor
    func showCompletionAlert(summary: ClassificationSummary, mode: ClassificationMode) {
        let alert = NSAlert()
        
        if summary.successfulFiles > 0 {
            alert.messageText = "Organization Complete!"
            alert.informativeText = """
            Total processed: \(summary.totalFiles) files
            Successfully organized: \(summary.successfulFiles) files
            Failed: \(summary.failedFiles) files
            
            Processing time: \(String(format: "%.1f", summary.endTime.timeIntervalSince(summary.startTime))) seconds
            
            Files have been \(mode == .copy ? "copied" : "moved") to appropriate subfolders by aspect ratio!
            """
            alert.addButton(withTitle: "Great!")
        } else {
            alert.messageText = "Organization Issues"
            alert.informativeText = """
            Total scanned: \(summary.totalFiles) files
            Successfully organized: \(summary.successfulFiles) files
            Processing failed: \(summary.failedFiles) files
            
            Possible causes:
            • Insufficient file permissions
            • Unable to create target folders
            • Files are being used by other applications
            
            Suggestion: Try selecting a different folder or check file permissions
            """
            alert.addButton(withTitle: "Understood")
        }
        
        alert.runModal()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Execute when application is about to terminate
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        return true
    }
}

// MARK: - ClassifierDelegate
extension AppDelegate: ClassifierDelegate {
    func classifier(_ classifier: Classifier, didStartProcessing totalFiles: Int) {
        Task { @MainActor in
            self.appState.statusText = "Starting to process \(totalFiles) files..."
        }
    }
    
    func classifier(_ classifier: Classifier, didProcessFile fileIndex: Int, totalFiles: Int, result: ClassificationResult) {
        Task { @MainActor in
            self.appState.progress = Double(fileIndex) / Double(totalFiles) * 100
            self.appState.statusText = "Processing... (\(fileIndex)/\(totalFiles))"
        }
    }
    
    func classifier(_ classifier: Classifier, didCompleteWith summary: ClassificationSummary) {
        Task { @MainActor in
            self.appState.progress = 100
            self.appState.statusText = "Organization complete!"
        }
    }
}

// MARK: - LoggerDelegate
extension AppDelegate: LoggerDelegate {
    func logger(_ logger: Logger, didLogMessage message: String, level: LogLevel) {
        Task { @MainActor in
            self.appState.logMessages.append(message)
        }
    }
}

// Create application instance and run
let app = NSApplication.shared
let delegate: AppDelegate = AppDelegate()
app.delegate = delegate
app.run()