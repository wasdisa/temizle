import SwiftUI
import Photos

struct HomeView: View {
    @State private var status = PhotoLibrary.status
    @AppStorage("skipReviewed") private var skipReviewed = true
    @AppStorage("freedBytes") private var freedBytes = 0
    @AppStorage("deletedCount") private var deletedCount = 0
    @State private var reviewedCount = 0
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                switch status {
                case .authorized, .limited:
                    modeList
                case .notDetermined:
                    permissionView
                default:
                    deniedView
                }
            }
            .navigationTitle("Temizle")
            .navigationDestination(for: CleanMode.self) { mode in
                SwipeSessionView(mode: mode)
            }
        }
    }

    // MARK: - Mod listesi

    private var modeList: some View {
        List {
            Section {
                HStack(spacing: 0) {
                    stat(value: "\(deletedCount)", label: "Silinen")
                    Divider()
                    stat(value: ByteText.text(Int64(freedBytes)), label: "Açılan yer")
                    Divider()
                    stat(value: "\(reviewedCount)", label: "Tutulan")
                }
                .padding(.vertical, 6)

                HStack {
                    Label("Sola: Tut", systemImage: "arrow.left")
                        .foregroundColor(.green)
                    Spacer()
                    Label("Sağa: Sil", systemImage: "arrow.right")
                        .labelStyle(TrailingIconLabelStyle())
                        .foregroundColor(.red)
                }
                .font(.subheadline.bold())
            }

            Section("Modlar") {
                NavigationLink(value: CleanMode.all) {
                    modeRow("Tümü", "En yeniden eskiye tüm fotoğraf ve videolar", "photo.stack", .blue)
                }
                NavigationLink {
                    MonthListView()
                } label: {
                    modeRow("Aya göre", "Galeriyi ay ay temizle", "calendar", .orange)
                }
                NavigationLink(value: CleanMode.videos) {
                    modeRow("Videolar", "En çok yer kaplayan videolar önce", "video", .purple)
                }
                NavigationLink(value: CleanMode.screenshots) {
                    modeRow("Ekran görüntüleri", "Sadece ekran görüntüleri", "camera.viewfinder", .teal)
                }
                NavigationLink(value: CleanMode.random) {
                    modeRow("Rastgele", "Karışık sırayla göz at", "shuffle", .pink)
                }
                NavigationLink(value: CleanMode.onThisDay) {
                    modeRow("Geçmişte bugün", "Önceki yıllarda bugün çekilenler", "clock.arrow.circlepath", .indigo)
                }
            }

            Section {
                Toggle("Tuttuklarımı tekrar gösterme", isOn: $skipReviewed)
                Button("Tutulanlar listesini sıfırla (\(reviewedCount))", role: .destructive) {
                    showResetConfirm = true
                }
                .disabled(reviewedCount == 0)
            } header: {
                Text("Ayarlar")
            } footer: {
                Text("Hiçbir şey sen onaylamadan silinmez. Silinenler 30 gün boyunca \"Son Silinenler\" albümünde kalır.")
            }
        }
        .onAppear { reviewedCount = ReviewedStore.shared.count }
        .confirmationDialog("Daha önce tuttuğun tüm öğeler yeniden gösterilecek.",
                            isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Sıfırla", role: .destructive) {
                ReviewedStore.shared.reset()
                reviewedCount = 0
            }
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func modeRow(_ title: String, _ subtitle: String, _ icon: String, _ color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(RoundedRectangle(cornerRadius: 9).fill(color))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - İzin ekranları

    private var permissionView: some View {
        VStack(spacing: 18) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.blue)
            Text("Galerine erişim gerekiyor")
                .font(.title2.bold())
            Text("Fotoğraf ve videolarını kaydırarak temizleyebilmen için galeri izni ver.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("İzin ver") {
                Task { @MainActor in status = await PhotoLibrary.requestAccess() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(30)
    }

    private var deniedView: some View {
        VStack(spacing: 18) {
            Image(systemName: "lock.shield")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            Text("Galeri izni kapalı")
                .font(.title2.bold())
            Text("Ayarlar > Temizle > Fotoğraflar bölümünden \"Tam Erişim\" seç.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Ayarları aç") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(30)
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon
        }
    }
}

/// Aya göre mod: ayları listeler
struct MonthListView: View {
    @State private var buckets: [MonthBucket] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading && buckets.isEmpty {
                ProgressView("Aylar hesaplanıyor…")
            } else {
                List(buckets) { b in
                    NavigationLink(value: CleanMode.month(year: b.year, month: b.month)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(MonthFormatter.title(year: b.year, month: b.month))
                                    .font(.body.weight(.semibold))
                                Text("\(b.count) öğe · \(b.reviewed) tutuldu")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                ProgressView(value: Double(min(b.reviewed, b.count)), total: Double(max(b.count, 1)))
                                    .tint(b.isDone ? .green : .orange)
                            }
                            if b.isDone {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Aya göre")
        .onAppear { reload() }
    }

    private func reload() {
        let reviewed = ReviewedStore.shared.ids
        Task { @MainActor in
            let result = await Task.detached(priority: .userInitiated) {
                PhotoLibrary.monthBuckets(reviewed: reviewed)
            }.value
            buckets = result
            isLoading = false
        }
    }
}
