import SwiftUI
import AppKit

// MARK: - DuplicateGroupView
struct DuplicateGroupView: View {
    let group: DuplicateGroup
    let isExpanded: Bool
    let onToggle: () -> Void
    let onFileSelect: (FileItem) -> Void
    let onSelectExceptOldest: () -> Void
    let onSelectExceptNewest: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 16)

                    Image(systemName: "doc.on.doc.fill")
                        .foregroundColor(Theme.accent)

                    Text("\(group.files.count) files")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(group.formattedWastedSpace + " wasted")
                        .font(.caption)
                        .foregroundColor(Theme.destructive)

                    Spacer()

                    Menu {
                        Button("Select All Except Oldest") { onSelectExceptOldest() }
                        Button("Select All Except Newest") { onSelectExceptNewest() }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 24)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(NSColor.controlBackgroundColor))
            }
            .buttonStyle(.plain)

            // Expanded file list
            if isExpanded {
                Divider()
                VStack(spacing: 0) {
                    ForEach(group.files) { file in
                        FileRowView(file: file, onSelect: { onFileSelect(file) })
                        if file.id != group.files.last?.id {
                            Divider()
                                .padding(.leading, 48)
                        }
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}

// MARK: - File Row View
struct FileRowView: View {
    @ObservedObject var file: ObservableFileItem
    let onSelect: () -> Void

    init(file: FileItem, onSelect: @escaping () -> Void) {
        self._file = ObservedObject(wrappedValue: ObservableFileItem(file))
        self.onSelect = onSelect
    }

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $file.isSelected)
                .toggleStyle(.checkbox)
                .labelsHidden()

            FileIconView(url: file.wrappedValue.url, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.wrappedValue.name)
                    .font(.caption)
                    .lineLimit(1)
                Text(file.wrappedValue.path)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(file.wrappedValue.formattedSize)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .trailing)

            Text(file.wrappedValue.modificationDate, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Observable File Item (for toggle binding)
class ObservableFileItem: ObservableObject {
    @Published var isSelected: Bool {
        didSet { wrappedValue.isSelected = isSelected }
    }
    var wrappedValue: FileItem

    init(_ item: FileItem) {
        self.wrappedValue = item
        self.isSelected = item.isSelected
    }
}
