import SwiftUI
import AppKit

// MARK: - ContentView (Main Window)

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var selectedGroup: DuplicateGroup?
    @State private var selectedFile: FileItem?
    @State private var selectedSmartGroup: SmartGroup?
    @State private var showSettings = false

    var body: some View {
        HSplitView {
            // Left: Smart Groups + Folders
            smartGroupsSidebar
                .frame(minWidth: 180, maxWidth: 240)

            // Center: Duplicate Groups
            duplicateGroupsSidebar
                .frame(minWidth: 280)

            // Right: File Details
            fileDetailView
                .frame(minWidth: 250)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Text("\(viewModel.totalSpaceRecovered) recovered")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(viewModel.selectedCount) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button(action: { viewModel.trashSelected() }) {
                    Label("Move to Trash", systemImage: "trash")
                }
                .disabled(viewModel.selectedCount == 0)
                .tint(Theme.destructive)
            }
        }
        .alert("Move to Trash?", isPresented: $viewModel.showTrashConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Move to Trash", role: .destructive) {
                viewModel.confirmTrash()
            }
        } message: {
            Text("Move \(viewModel.selectedCount) files to Trash?")
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }

    // MARK: - Smart Groups Sidebar

    private var smartGroupsSidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Smart Groups")
                    .font(.headline)
                Spacer()
            }
            .padding()

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(SmartGroup.allGroups) { group in
                        smartGroupRow(group)
                    }
                }
                .padding(.vertical, 8)
            }

            Divider()

            // Folder section
            HStack {
                Text("Folders")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            if viewModel.selectedFolders.isEmpty {
                VStack(spacing: 8) {
                    Button(action: { viewModel.addFolder() }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Folder")
                        }
                        .font(.system(size: 12))
                    }
                }
                .padding(.vertical, 8)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(viewModel.selectedFolders, id: \.path) { folder in
                            HStack {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.accent)
                                Text(folder.name)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                Spacer()
                                Button(action: { viewModel.removeFolder(folder) }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 3)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider()

            VStack(spacing: 8) {
                HStack {
                    Text("Min size:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $viewModel.minFileSize) {
                        Text("1 KB").tag(Int64(1024))
                        Text("10 KB").tag(Int64(10240))
                        Text("100 KB").tag(Int64(102400))
                        Text("1 MB").tag(Int64(1048576))
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }

                HStack(spacing: 8) {
                    Button(action: { viewModel.startScan() }) {
                        Label("Scan", systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .disabled(viewModel.selectedFolders.isEmpty || viewModel.isScanning)
                }
            }
            .padding()
        }
        .background(Color(nsColor: NSColor.controlBackgroundColor))
    }

    private func smartGroupRow(_ group: SmartGroup) -> some View {
        Button(action: { selectedSmartGroup = group }) {
            HStack {
                Image(systemName: group.icon)
                    .font(.system(size: 12))
                    .foregroundColor(selectedSmartGroup?.id == group.id ? Theme.accent : .secondary)
                Text(group.name)
                    .font(.system(size: 13))
                    .foregroundColor(selectedSmartGroup?.id == group.id ? Theme.accent : .primary)
                Spacer()
                Text("\(filteredGroups(for: group).count)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(selectedSmartGroup?.id == group.id ? Theme.accent.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Duplicate Groups Sidebar

    private var duplicateGroupsSidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Duplicate Groups")
                    .font(.headline)
                Spacer()
                if viewModel.isScanning {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text(viewModel.progressMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding()

            Divider()

            if viewModel.duplicateGroups.isEmpty && !viewModel.isScanning {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "doc.on.doc")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No duplicates found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !viewModel.selectedFolders.isEmpty {
                        Text("Run a scan to find duplicates")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredGroups) { group in
                            DuplicateGroupView(
                                group: group,
                                isExpanded: selectedGroup?.id == group.id,
                                onToggle: { selectedGroup = group.id == selectedGroup?.id ? nil : group },
                                onFileSelect: { selectedFile = $0 },
                                onSelectExceptOldest: { viewModel.selectExceptOldest(in: group) },
                                onSelectExceptNewest: { viewModel.selectExceptNewest(in: group) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(nsColor: NSColor.windowBackgroundColor))
    }

    // MARK: - File Detail View

    private var fileDetailView: some View {
        VStack {
            if let file = selectedFile {
                FileDetailView(file: file)
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "info.circle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Select a file to view details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(nsColor: NSColor.controlBackgroundColor))
    }

    // MARK: - Helpers

    private var filteredGroups: [DuplicateGroup] {
        guard let smartGroup = selectedSmartGroup else {
            return viewModel.duplicateGroups
        }
        return filteredGroups(for: smartGroup)
    }

    private func filteredGroups(for smartGroup: SmartGroup) -> [DuplicateGroup] {
        viewModel.duplicateGroups.filter(smartGroup.filter)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Scan settings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CLOUD STORAGE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .tracking(0.05)

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(CloudStorageProvider.defaultProviders) { provider in
                                Toggle(provider.name, isOn: .constant(false))
                                    .toggleStyle(.switch)
                                    .controlSize(.small)
                            }
                        }
                        .padding(12)
                        .background(Color(nsColor: NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
                .padding(16)
            }
        }
        .frame(width: 400, height: 400)
    }
}

// MARK: - File Detail View

struct FileDetailView: View {
    let file: FileItem
    @State private var previewImage: NSImage?
    @State private var previewText: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // File Icon & Name
                HStack(spacing: 12) {
                    FileIconView(url: file.url)
                        .frame(width: 48, height: 48)
                    VStack(alignment: .leading) {
                        Text(file.name)
                            .font(.headline)
                        Text(file.formattedSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Details
                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(label: "Path", value: file.path)
                    DetailRow(label: "Modified", value: file.modificationDate.formatted())
                    if let hash = file.hash {
                        DetailRow(label: "SHA256", value: String(hash.prefix(24)) + "...")
                    }
                }

                // Preview
                if let image = previewImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(Theme.cornerRadiusSmall)
                } else if let text = previewText {
                    Text(text)
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .background(Color(nsColor: NSColor.textBackgroundColor))
                        .cornerRadius(Theme.cornerRadiusSmall)
                }
            }
            .padding()
        }
        .onAppear { loadPreview() }
    }

    private func loadPreview() {
        let url = file.url

        // Try image preview
        if let image = NSImage(contentsOf: url) {
            previewImage = image
            return
        }

        // Try text preview (files under 1MB)
        if file.size < 1_048_576 {
            if let text = try? String(contentsOf: url, encoding: .utf8) {
                previewText = String(text.prefix(500))
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .lineLimit(2)
        }
    }
}

struct FileIconView: View {
    let url: URL
    var size: CGFloat = 24

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}
