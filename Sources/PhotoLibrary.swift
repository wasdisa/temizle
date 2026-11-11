import Foundation
import Photos
import UIKit

/// Galeriden öğe çekme, boyut hesaplama ve silme işlemleri
enum PhotoLibrary {

    static var status: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    static func requestAccess() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    // MARK: - Çekme

    private static func baseOptions(ascending: Bool = false) -> PHFetchOptions {
        let o = PHFetchOptions()
        o.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: ascending)]
        return o
    }

    private static let photoOrVideo = NSPredicate(
        format: "mediaType == %d OR mediaType == %d",
        PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue
    )

    static func toArray(_ r: PHFetchResult<PHAsset>) -> [PHAsset] {
        var a: [PHAsset] = []
        a.reserveCapacity(r.count)
        r.enumerateObjects { asset, _, _ in a.append(asset) }
        return a
    }

    static func fetchAllArray() -> [PHAsset] {
        let o = baseOptions()
        o.predicate = photoOrVideo
        return toArray(PHAsset.fetchAssets(with: o))
    }

    /// Seçilen moda göre kaydırılacak öğe listesi (arka planda çağrılmalı)
    static func assets(for mode: CleanMode, skipReviewed: Bool, reviewed: Set<String>) -> [PHAsset] {
        var list: [PHAsset]

        switch mode {
        case .all:
            list = fetchAllArray()

        case .month(let year, let month):
            let cal = Calendar.current
            var c = DateComponents()
            c.year = year
            c.month = month
            c.day = 1
            let start = cal.date(from: c) ?? Date()
            let end = cal.date(byAdding: .month, value: 1, to: start) ?? Date()
            let o = baseOptions(ascending: true)
            o.predicate = NSPredicate(
                format: "(mediaType == %d OR mediaType == %d) AND creationDate >= %@ AND creationDate < %@",
                PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue,
                start as NSDate, end as NSDate
            )
            list = toArray(PHAsset.fetchAssets(with: o))

        case .videos:
            let o = baseOptions()
            o.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
            let videos = toArray(PHAsset.fetchAssets(with: o))
                .filter { !skipReviewed || !reviewed.contains($0.localIdentifier) }
            // En büyük videolar önce
            let sized = videos.map { ($0, fileSize($0)) }
            return sized.sorted { $0.1 > $1.1 }.map { $0.0 }

        case .screenshots:
            let o = baseOptions()
            o.predicate = NSPredicate(
                format: "mediaType == %d AND (mediaSubtypes & %d) != 0",
                PHAssetMediaType.image.rawValue, Int(PHAssetMediaSubtype.photoScreenshot.rawValue)
            )
            list = toArray(PHAsset.fetchAssets(with: o))

        case .random:
            list = fetchAllArray().shuffled()

        case .onThisDay:
            let cal = Calendar.current
            let today = cal.dateComponents([.year, .month, .day], from: Date())
            list = fetchAllArray().filter { asset in
                guard let d = asset.creationDate else { return false }
                let c = cal.dateComponents([.year, .month, .day], from: d)
                return c.month == today.month && c.day == today.day && (c.year ?? 0) < (today.year ?? 0)
            }
        }

        if skipReviewed {
            list = list.filter { !reviewed.contains($0.localIdentifier) }
        }
        return list
    }

    /// Ay ay gruplama (arka planda çağrılmalı)
    static func monthBuckets(reviewed: Set<String>) -> [MonthBucket] {
        let cal = Calendar.current
        var counts: [Int: (total: Int, reviewed: Int)] = [:]
        for asset in fetchAllArray() {
            guard let d = asset.creationDate else { continue }
            let c = cal.dateComponents([.year, .month], from: d)
            let key = (c.year ?? 0) * 100 + (c.month ?? 0)
            var entry = counts[key] ?? (total: 0, reviewed: 0)
            entry.total += 1
            if reviewed.contains(asset.localIdentifier) { entry.reviewed += 1 }
            counts[key] = entry
        }
        return counts
            .map { MonthBucket(year: $0.key / 100, month: $0.key % 100, count: $0.value.total, reviewed: $0.value.reviewed) }
            .sorted { $0.id > $1.id }
    }

    // MARK: - Boyut

    static func fileSize(_ asset: PHAsset) -> Int64 {
        var total: Int64 = 0
        for r in PHAssetResource.assetResources(for: asset) {
            if let n = r.value(forKey: "fileSize") as? NSNumber {
                total += n.int64Value
            }
        }
        return total
    }

    // MARK: - Silme

    /// iOS kendi onay penceresini gösterir. Silinenler "Son Silinenler" albümüne gider (30 gün).
    static func delete(_ assets: [PHAsset]) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }
    }
}

/// Görsel yükleme (önbellekli)
enum ImageLoader {
    static let manager = PHCachingImageManager()
    static let cardSize = CGSize(width: 1200, height: 1200)
    static let thumbSize = CGSize(width: 300, height: 300)

    static var cardOptions: PHImageRequestOptions {
        let o = PHImageRequestOptions()
        o.deliveryMode = .opportunistic
        o.isNetworkAccessAllowed = true   // iCloud'daki fotoğraflar için
        o.resizeMode = .fast
        return o
    }

    @discardableResult
    static func request(_ asset: PHAsset, size: CGSize, contentMode: PHImageContentMode = .aspectFit,
                        completion: @escaping (UIImage?) -> Void) -> PHImageRequestID {
        manager.requestImage(for: asset, targetSize: size, contentMode: contentMode, options: cardOptions) { image, _ in
            DispatchQueue.main.async { completion(image) }
        }
    }

    static func preheat(_ assets: [PHAsset]) {
        guard !assets.isEmpty else { return }
        manager.startCachingImages(for: assets, targetSize: cardSize, contentMode: .aspectFit, options: cardOptions)
    }

    static func cancel(_ id: PHImageRequestID) {
        manager.cancelImageRequest(id)
    }
}
