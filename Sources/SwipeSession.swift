import Foundation
import Photos
import SwiftUI

/// Bir kaydırma oturumunun durumu: sıra, kararlar, geri alma, silinecekler
@MainActor
final class SwipeSession: ObservableObject {
    enum Decision { case keep, delete }

    private struct Action {
        let asset: PHAsset
        let decision: Decision
    }

    let mode: CleanMode
    @Published private(set) var queue: [PHAsset] = []
    @Published private(set) var index = 0
    @Published private(set) var toDelete: [PHAsset] = []
    @Published private(set) var keptCount = 0
    @Published private(set) var isLoading = true
    @Published private(set) var hasLoaded = false
    private var history: [Action] = []

    init(mode: CleanMode) {
        self.mode = mode
    }

    var current: PHAsset? { index < queue.count ? queue[index] : nil }
    var next: PHAsset? { index + 1 < queue.count ? queue[index + 1] : nil }
    var remaining: Int { max(queue.count - index, 0) }
    var total: Int { queue.count }
    var canUndo: Bool { !history.isEmpty }

    func load(skipReviewed: Bool) async {
        isLoading = true
        let reviewed = ReviewedStore.shared.ids
        let mode = self.mode
        let result = await Task.detached(priority: .userInitiated) {
            PhotoLibrary.assets(for: mode, skipReviewed: skipReviewed, reviewed: reviewed)
        }.value
        queue = result
        index = 0
        isLoading = false
        hasLoaded = true
        preheat()
    }

    func decide(_ d: Decision) {
        guard let a = current else { return }
        history.append(Action(asset: a, decision: d))
        switch d {
        case .keep:
            keptCount += 1
            ReviewedStore.shared.mark(a.localIdentifier)
        case .delete:
            toDelete.append(a)
        }
        index += 1
        preheat()
    }

    func undo() {
        guard let last = history.popLast() else { return }
        switch last.decision {
        case .keep:
            keptCount -= 1
            ReviewedStore.shared.unmark(last.asset.localIdentifier)
        case .delete:
            toDelete.removeAll { $0.localIdentifier == last.asset.localIdentifier }
        }
        index = max(index - 1, 0)
    }

    /// İnceleme ekranında "vazgeçtim, kalsın" denilen öğe
    func rescue(_ a: PHAsset) {
        toDelete.removeAll { $0.localIdentifier == a.localIdentifier }
        keptCount += 1
        ReviewedStore.shared.mark(a.localIdentifier)
        history.removeAll() // sıra bozulmasın diye geri alma geçmişi sıfırlanır
    }

    /// Silinecekleri gerçekten siler. Başarılıysa (adet, bayt) döner.
    func commitDelete() async throws -> (count: Int, bytes: Int64) {
        let assets = toDelete
        guard !assets.isEmpty else { return (0, 0) }
        let bytes = await Task.detached(priority: .userInitiated) {
            assets.reduce(Int64(0)) { $0 + PhotoLibrary.fileSize($1) }
        }.value
        try await PhotoLibrary.delete(assets)
        toDelete.removeAll()
        history.removeAll()
        return (assets.count, bytes)
    }

    private func preheat() {
        let upcoming = Array(queue.dropFirst(index).prefix(4))
        ImageLoader.preheat(upcoming)
    }
}
