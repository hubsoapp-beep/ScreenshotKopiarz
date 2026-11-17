import Cocoa
import CoreServices
import UserNotifications
import UniformTypeIdentifiers

let defaults = UserDefaults.standard

enum Keys {
    static let enabled = "autoCopyEnabled"
    static let copyAsPath = "copyAsPath"
    static let onlyScreenshots = "onlyScreenshots"
    static let extraFolders = "extraFolders"
    static let startAtLogin = "startAtLogin"
}

let appBundleID = "pl.milosz.screenshotkopiarz"

final class ScreenshotMonitor {
    var onChange: ((URL) -> Void)?

    private var stream: FSEventStreamRef?
    private var watchedPaths: [String] = []

    var paths: [String] {
        get { watchedPaths }
        set {
            stop()
            watchedPaths = newValue
            start()
        }
    }

    func start() {
        guard !watchedPaths.isEmpty else { return }
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { _, info, _, eventPaths, _, _ in
            guard let info else { return }
            let monitor = Unmanaged<ScreenshotMonitor>.fromOpaque(info).takeUnretainedValue()
            let pathsArray = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as? [String] ?? []
            monitor.handleEvents(paths: pathsArray)
        }

        let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            watchedPaths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )

        guard let stream else { return }
        self.stream = stream
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.global(qos: .utility))
        FSEventStreamStart(stream)
    }

    func stop() {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            self.stream = nil
        }
    }

    private func handleEvents(paths: [String]) {
        for path in paths {
            guard isCandidate(path) else { continue }
            let url = URL(fileURLWithPath: path)
            scheduleCopy(url: url)
        }
    }

    private var pendingDebounces: [String: DispatchWorkItem] = [:]

    private func scheduleCopy(url: URL) {
        let key = url.path
        let item = DispatchWorkItem { [weak self] in
            self?.pendingDebounces.removeValue(forKey: key)
            self?.verifyAndDeliver(url: url)
        }
        pendingDebounces[key]?.cancel()
        pendingDebounces[key] = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: item)
    }

    private func verifyAndDeliver(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        guard !isDir.boolValue else { return }
        guard let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size]) as? NSNumber, size.intValue > 0 else { return }
        onChange?(url)
    }

    private func isCandidate(_ path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        let ext = url.pathExtension.lowercased()
        let imageExts = ["png", "jpg", "jpeg", "heic", "gif", "webp", "tiff", "bmp"]
        guard imageExts.contains(ext) else { return false }
        if defaults.bool(forKey: Keys.onlyScreenshots) {
            let name = url.lastPathComponent
            let upper = name.uppercased()
            let patterns = ["SCREENSHOT", "ZRZUT EKRANU", "SCREEN SHOT", "BILDSCHIRMFOTO", "CAPTURA DE PANTALLA"]
            let looksLikeScreenshot = patterns.contains { upper.contains($0) } || name.range(of: #"^\d{4}-\d{2}-\d{2}"#, options: .regularExpression) != nil
            guard looksLikeScreenshot else { return false }
        }
        return true
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem!
    private let monitor = ScreenshotMonitor()
    private var lastCopied: URL?
    private var lastCopiedLabel: NSMenuItem?
    private var autoCopyItem: NSMenuItem?
    private var copyAsPathItem: NSMenuItem?
    private var onlyScreenshotsItem: NSMenuItem?
    private var startAtLoginItem: NSMenuItem?
    private var currentFileSize: Int = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupDefaults()
        setupStatusItem()
        setupNotificationCenter()
        monitor.onChange = { [weak self] url in
            self?.copyImage(url: url)
        }
        rebuildWatchedFolders()
    }

    private func setupDefaults() {
        if defaults.object(forKey: Keys.enabled) == nil { defaults.set(true, forKey: Keys.enabled) }
        if defaults.object(forKey: Keys.copyAsPath) == nil { defaults.set(true, forKey: Keys.copyAsPath) }
        if defaults.object(forKey: Keys.onlyScreenshots) == nil { defaults.set(true, forKey: Keys.onlyScreenshots) }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "photo.on.rectangle.angled", accessibilityDescription: "ScreenshotKopiarz")
            button.image?.isTemplate = true
        }
        statusItem.menu = buildMenu()
    }

    private func setupNotificationCenter() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        let statusLabel = NSMenuItem(title: "ScreenshotKopiarz", action: nil, keyEquivalent: "")
        statusLabel.isEnabled = false
        menu.addItem(statusLabel)
        lastCopiedLabel = NSMenuItem(title: "Nic jeszcze nie skopiowano", action: nil, keyEquivalent: "")
        lastCopiedLabel?.isEnabled = false
        menu.addItem(lastCopiedLabel!)

        menu.addItem(.separator())

        autoCopyItem = NSMenuItem(title: "Automatyczne kopiowanie", action: #selector(toggleAutoCopy), keyEquivalent: "")
        autoCopyItem?.target = self
        menu.addItem(autoCopyItem!)

        copyAsPathItem = NSMenuItem(title: "Kopiuj jako ścieżkę do pliku", action: #selector(toggleCopyAsPath), keyEquivalent: "")
        copyAsPathItem?.target = self
        menu.addItem(copyAsPathItem!)

        onlyScreenshotsItem = NSMenuItem(title: "Kopiuj tylko zrzuty ekranu", action: #selector(toggleOnlyScreenshots), keyEquivalent: "")
        onlyScreenshotsItem?.target = self
        menu.addItem(onlyScreenshotsItem!)

        menu.addItem(.separator())

        let foldersTitle = NSMenuItem(title: "Obserwowane foldery", action: nil, keyEquivalent: "")
        foldersTitle.isEnabled = false
        menu.addItem(foldersTitle)

        menu.addItem(NSMenuItem(title: "Pulpit", action: #selector(toggleFolder(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Pobrane", action: #selector(toggleFolder(_:)), keyEquivalent: ""))

        let addFolder = NSMenuItem(title: "Dodaj folder...", action: #selector(addFolder), keyEquivalent: "")
        addFolder.target = self
        menu.addItem(addFolder)

        let removeFolder = NSMenuItem(title: "Usuń niestandardowy folder...", action: #selector(removeFolder), keyEquivalent: "")
        removeFolder.target = self
        menu.addItem(removeFolder)

        menu.addItem(.separator())

        startAtLoginItem = NSMenuItem(title: "Uruchamiaj przy logowaniu", action: #selector(toggleStartAtLogin), keyEquivalent: "")
        startAtLoginItem?.target = self
        menu.addItem(startAtLoginItem!)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Zakończ", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApplication.shared
        menu.addItem(quit)

        return menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateMenuState()
    }

    private func updateMenuState() {
        autoCopyItem?.state = defaults.bool(forKey: Keys.enabled) ? .on : .off
        copyAsPathItem?.state = defaults.bool(forKey: Keys.copyAsPath) ? .on : .off
        onlyScreenshotsItem?.state = defaults.bool(forKey: Keys.onlyScreenshots) ? .on : .off
        startAtLoginItem?.state = AppDelegate.launchAgentInstalled() ? .on : .off

        let folders = defaultFolders() + (defaults.stringArray(forKey: Keys.extraFolders) ?? [])
        for item in statusItem.menu?.items ?? [] {
            if let path = folderPath(for: item.title), folders.contains(path) {
                item.state = .on
                item.target = self
            } else if item.title == "Dodaj folder..." || item.title == "Usuń niestandardowy folder..." {
                item.target = self
            }
        }

        if let last = lastCopied {
            let name = last.lastPathComponent
            lastCopiedLabel?.title = "Ostatnio: \(name)"
        }
    }

    private func folderPath(for title: String) -> String? {
        switch title {
        case "Pulpit": return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.path
        case "Pobrane": return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path
        default: return nil
        }
    }

    private func defaultFolders() -> [String] {
        let fm = FileManager.default
        return [
            fm.urls(for: .desktopDirectory, in: .userDomainMask).first?.path,
            fm.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path
        ].compactMap { $0 }
    }

    private func rebuildWatchedFolders() {
        var folders = defaultFolders()
        folders += defaults.stringArray(forKey: Keys.extraFolders) ?? []
        monitor.paths = folders
    }

    @objc private func toggleAutoCopy() {
        defaults.set(!defaults.bool(forKey: Keys.enabled), forKey: Keys.enabled)
        updateMenuState()
    }

    @objc private func toggleCopyAsPath() {
        defaults.set(!defaults.bool(forKey: Keys.copyAsPath), forKey: Keys.copyAsPath)
        updateMenuState()
    }

    @objc private func toggleOnlyScreenshots() {
        defaults.set(!defaults.bool(forKey: Keys.onlyScreenshots), forKey: Keys.onlyScreenshots)
        updateMenuState()
    }

    @objc private func toggleFolder(_ sender: NSMenuItem) {
        guard let path = folderPath(for: sender.title) else { return }
        var folders = defaultFolders() + (defaults.stringArray(forKey: Keys.extraFolders) ?? [])
        if folders.contains(path) {
            folders.removeAll { $0 == path }
        } else {
            folders.append(path)
        }
        let extras = folders.filter { !defaultFolders().contains($0) }
        defaults.set(extras, forKey: Keys.extraFolders)
        rebuildWatchedFolders()
        updateMenuState()
    }

    @objc private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Dodaj"
        if panel.runModal() == .OK {
            var extras = defaults.stringArray(forKey: Keys.extraFolders) ?? []
            for url in panel.urls {
                if !extras.contains(url.path) { extras.append(url.path) }
            }
            defaults.set(extras, forKey: Keys.extraFolders)
            rebuildWatchedFolders()
            updateMenuState()
        }
    }

    @objc private func removeFolder() {
        var extras = defaults.stringArray(forKey: Keys.extraFolders) ?? []
        guard !extras.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "Brak niestandardowych folderów"
            alert.informativeText = "Nie dodano żadnych dodatkowych folderów do obserwowania."
            alert.runModal()
            return
        }
        let alert = NSAlert()
        alert.messageText = "Usuń folder z obserwacji"
        alert.informativeText = "Który folder chcesz przestać obserwować?"
        for f in extras {
            alert.addButton(withTitle: (f as NSString).lastPathComponent)
        }
        alert.addButton(withTitle: "Anuluj")
        let resp = alert.runModal()
        let index = resp.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
        if index >= 0 && index < extras.count {
            extras.remove(at: index)
            defaults.set(extras, forKey: Keys.extraFolders)
            rebuildWatchedFolders()
            updateMenuState()
        }
    }

    @objc private func toggleStartAtLogin() {
        if AppDelegate.launchAgentInstalled() {
            AppDelegate.uninstallLaunchAgent()
        } else {
            AppDelegate.installLaunchAgent()
        }
        updateMenuState()
    }

    // MARK: - Copy

    private func copyImage(url: URL) {
        guard defaults.bool(forKey: Keys.enabled) else { return }

        // Wait a tiny bit more so the file is fully flushed, then copy.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.performCopy(url: url)
        }
    }

    private func performCopy(url: URL) {
        let pb = NSPasteboard.general

        // Path mode: plain text path (what terminal chats and Claude Code accept everywhere).
        if defaults.bool(forKey: Keys.copyAsPath) {
            pb.clearContents()
            pb.setString(url.path, forType: .string)
            lastCopied = url
            flashStatusItem()
            notifyCopied(name: url.lastPathComponent)
            updateMenuState()
            return
        }

        guard let image = NSImage(contentsOf: url) else { return }
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }

        // PNG first, file URL second — terminals (Ghostty, Orca, Claude Code) read the image,
        // Finder still gets the file. No eager TIFF: for a photo it doubled the payload
        // (~36 MB next to an 18 MB PNG) and made paste in terminals slow or fail.
        // The pasteboard server derives TIFF from the PNG on demand.
        let item = NSPasteboardItem()
        item.setData(png, forType: .png)
        item.setString(url.absoluteString, forType: .fileURL)

        pb.clearContents()
        pb.writeObjects([item])

        lastCopied = url
        flashStatusItem()
        notifyCopied(name: url.lastPathComponent)
        updateMenuState()
    }

    private func flashStatusItem() {
        guard let button = statusItem.button else { return }
        let original = button.image
        button.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "skopiowano")
        button.image?.isTemplate = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            button.image = original
        }
    }

    private func notifyCopied(name: String) {
        let content = UNMutableNotificationContent()
        content.title = "Skopiowano do schowka"
        content.body = name
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // MARK: - LaunchAgent

    static func launchAgentURL() -> URL {
        let dir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("LaunchAgents/\(appBundleID).plist")
    }

    static func installLaunchAgent() {
        let agentURL = launchAgentURL()
        let appURL = Bundle.main.bundleURL
        let plist: [String: Any] = [
            "Label": appBundleID,
            "ProgramArguments": [appURL.appendingPathComponent("Contents/MacOS/ScreenshotKopiarz").path],
            "RunAtLoad": true,
            "KeepAlive": true
        ]
        try? FileManager.default.createDirectory(at: agentURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: agentURL)
            _ = try? Shell.run("/bin/launchctl", ["load", agentURL.path])
        } catch {
            NSLog("Nie udało się zainstalować LaunchAgenta: \(error)")
        }
    }

    static func uninstallLaunchAgent() {
        let agentURL = launchAgentURL()
        _ = try? Shell.run("/bin/launchctl", ["unload", agentURL.path])
        try? FileManager.default.removeItem(at: agentURL)
    }

    static func launchAgentInstalled() -> Bool {
        FileManager.default.fileExists(atPath: launchAgentURL().path)
    }
}

enum Shell {
    @discardableResult
    static func run(_ path: String, _ args: [String]) throws -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        try p.run()
        p.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
