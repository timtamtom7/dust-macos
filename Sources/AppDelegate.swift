import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var mainWindow: NSWindow?
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        setupMainWindow()
        setupEventMonitor()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "broom.fill", accessibilityDescription: "Dust")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 320)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverView())
    }

    private func setupMainWindow() {
        let contentView = ContentView()
        let hostingController = NSHostingController(rootView: contentView)

        mainWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        mainWindow?.title = "Dust"
        mainWindow?.contentViewController = hostingController
        mainWindow?.center()
        mainWindow?.isReleasedWhenClosed = false
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func openMainWindow() {
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Popover View
struct PopoverView: View {
    @StateObject private var scanStore = ScanStore()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "broom.fill")
                    .font(.largeTitle)
                    .foregroundColor(Theme.accent)
                VStack(alignment: .leading) {
                    Text("Dust")
                        .font(.headline)
                    Text("Duplicate File Finder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.top, 16)

            if scanStore.isScanning {
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Scanning...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let progress = scanStore.progressMessage {
                        Text(progress)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    Button(action: { scanStore.quickScan(.downloads) }) {
                        Label("Scan Downloads", systemImage: "arrow.down.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)

                    Button(action: { scanStore.quickScan(.desktop) }) {
                        Label("Scan Desktop", systemImage: "desktopcomputer")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: { scanStore.quickScan(.documents) }) {
                        Label("Scan Documents", systemImage: "doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 16)
            }

            Spacer()

            HStack {
                if let lastScan = scanStore.lastScanDate {
                    Text("Last scan: \(lastScan, formatter: RelativeDateTimeFormatter())")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Open DUST") {
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.openMainWindow()
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 400, height: 320)
    }
}

// MARK: - Quick Scan Presets
enum ScanPreset {
    case downloads, desktop, documents

    var url: URL? {
        switch self {
        case .downloads: return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        case .desktop: return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        case .documents: return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        }
    }
}

// MARK: - DustState

@MainActor
final class DustState {
    static let shared = DustState()

    var viewModel: MainViewModel?
    var history: [ScanResult] = []

    private init() {}

    func configure(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: - ScanResult

struct ScanResult: Codable {
    let duplicateGroups: [DuplicateGroup]
    let totalWastedSpace: Int64
    let totalFilesScanned: Int
    let scanDuration: TimeInterval
}

