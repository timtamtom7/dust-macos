import SwiftUI
import AppKit

// MARK: - ContentView (Main Window)
struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var selectedGroup: DuplicateGroup?
    @State private var selectedFile: FileItem?

    var body: some View {
        HSplitView {
            // Left: Folder List
            folderSidebar
                .frame(minWidth: 200, maxWidth: 280)

            // Center: Duplicate Groups
            duplicateListView
                .frame(minWidth: 300)

            // Right: File Details / Preview
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
    }

    // MARK: - Folder Sidebar
    private var folderSidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Folders")
                    .font(.headline)
                Spacer()
                Button(action: { viewModel.addFolder() }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Divider()

            if viewModel.selectedFolders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No folders selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Add Folder") {
                        viewModel.addFolder()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.selectedFolders, id: \.path) { folder in
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(Theme.accent)
                            Text(folder.name)
                                .lineLimit(1)
                            Spacer()
                            Button(action: { viewModel.removeFolder(folder) }) {
                                Image(systemName: "xmark")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.sidebar)
            }

            Divider()

            VStack(spacing: 8) {
                HStack {
                    Text("Min size:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("", selection: $viewModel.minFileSize) {
                        Text("1 KB").tag(1024)
                        Text("10 KB").tag(10240)
                        Text("100 KB").tag(102400)
                        Text("1 MB").tag(1048576)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }

                Button(action: { viewModel.startScan() }) {
                    Label("Start Scan", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .disabled(viewModel.selectedFolders.isEmpty || viewModel.isScanning)
            }
            .padding()
        }
        .cardStyle()
    }

    // MARK: - Duplicate List
    private var duplicateListView: some View {
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
                }
            }
            .padding()

            Divider()

            if viewModel.duplicateGroups.isEmpty && !viewModel.isScanning {
                VStack(spacing: 12) {
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
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.duplicateGroups) { group in
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
        .cardStyle()
    }

    // MARK: - File Detail View
    private var fileDetailView: some View {
        VStack {
            if let file = selectedFile {
                FileDetailView(file: file)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "info.circle")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Select a file to view details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .cardStyle()
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
                        DetailRow(label: "SHA256", value: String(hash.prefix(16)) + "...")
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
                        .background(Color(NSColor.textBackgroundColor))
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

// MARK: - File Icon View
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
