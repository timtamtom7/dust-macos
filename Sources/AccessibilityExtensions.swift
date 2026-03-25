import SwiftUI
import AppKit

extension View {
    func accessibilityFileLabel(name: String, size: String) -> some View {
        self.accessibilityLabel("\(name), size \(size)")
    }
}
