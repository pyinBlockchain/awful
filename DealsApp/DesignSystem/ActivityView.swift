import SwiftUI
import UIKit

/// System share sheet with a completion callback. Used instead of `ShareLink` because
/// ShareLink reports nothing back, so `store_shared` couldn't tell a share from a cancel.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    let onComplete: (_ completed: Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in onComplete(completed) }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
