import Foundation
import Photos

/// Uygulamadaki temizlik modları
enum CleanMode: Hashable {
    case all
    case month(year: Int, month: Int)
    case videos
    case screenshots
    case random
    case onThisDay

    var title: String {
        switch self {
        case .all: return "Tümü"
        case .month(let y, let m): return MonthFormatter.title(year: y, month: m)
        case .videos: return "Videolar"
        case .screenshots: return "Ekran Görüntüleri"
        case .random: return "Rastgele"
        case .onThisDay: return "Geçmişte Bugün"
        }
    }
}

enum MonthFormatter {
    private static let trLocale = Locale(identifier: "tr_TR")

    static func title(year: Int, month: Int) -> String {
        let df = DateFormatter()
        df.locale = trLocale
        df.dateFormat = "LLLL yyyy"
        var c = DateComponents()
        c.year = year
        c.month = month
        c.day = 1
        let date = Calendar.current.date(from: c) ?? Date()
        return df.string(from: date).capitalized(with: trLocale)
    }

    static func dateText(_ date: Date?) -> String {
        guard let date else { return "" }
        let df = DateFormatter()
        df.locale = trLocale
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }
}

struct MonthBucket: Identifiable, Hashable {
    let year: Int
    let month: Int
    let count: Int
    let reviewed: Int
    var id: Int { year * 100 + month }
    var isDone: Bool { reviewed >= count }
}

enum ByteText {
    static func text(_ bytes: Int64) -> String {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f.string(fromByteCount: bytes)
    }
}

/// "Tut" denilen öğeleri hatırlar; böylece bir dahaki sefere tekrar karşına çıkmazlar.
final class ReviewedStore {
    static let shared = ReviewedStore()
    private let key = "reviewedIDs"
    private(set) var ids: Set<String>

    private init() {
        ids = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    func mark(_ id: String) { ids.insert(id); save() }
    func unmark(_ id: String) { ids.remove(id); save() }
    func reset() { ids.removeAll(); save() }
    var count: Int { ids.count }

    private func save() {
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}
