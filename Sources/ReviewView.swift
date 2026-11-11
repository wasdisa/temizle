import SwiftUI
import Photos

/// Silinecekleri son kez gözden geçirme ve toplu silme
struct ReviewView: View {
    @ObservedObject var session: SwipeSession
    @Environment(\.dismiss) private var dismiss
    @AppStorage("freedBytes") private var freedBytes = 0
    @AppStorage("deletedCount") private var deletedCount = 0

    @State private var isDeleting = false
    @State private var errorText: String?
    @State private var doneText: String?

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 3)]

    var body: some View {
        NavigationStack {
            Group {
                if let doneText {
                    resultView(doneText)
                } else if session.toDelete.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        Text("Silinecek öğe yok").font(.headline)
                    }
                } else {
                    ScrollView {
                        Text("Kurtarmak istediğin öğeye dokun, silinecekler listesinden çıkar.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        LazyVGrid(columns: columns, spacing: 3) {
                            ForEach(session.toDelete, id: \.localIdentifier) { asset in
                                ThumbnailView(asset: asset)
                                    .overlay(alignment: .topTrailing) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .background(Circle().fill(Color.white))
                                            .padding(5)
                                    }
                                    .onTapGesture {
                                        withAnimation { session.rescue(asset) }
                                    }
                            }
                        }
                        .padding(.bottom, 90)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if doneText == nil && !session.toDelete.isEmpty {
                    Button(action: deleteAll) {
                        HStack {
                            if isDeleting { ProgressView().tint(.white) }
                            Text(isDeleting ? "Siliniyor…" : "\(session.toDelete.count) öğeyi sil")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(isDeleting)
                    .padding()
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Silinecekler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .alert("Silinemedi", isPresented: Binding(
                get: { errorText != nil },
                set: { if !$0 { errorText = nil } }
            )) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorText ?? "")
            }
        }
    }

    private func resultView(_ text: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 54))
                .foregroundColor(.blue)
            Text(text)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Silinenler Fotoğraflar uygulamasındaki \"Son Silinenler\" albümünde 30 gün durur. Yer hemen açılsın istersen oradan da silebilirsin.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Devam et") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding(30)
    }

    private func deleteAll() {
        isDeleting = true
        Task { @MainActor in
            do {
                let result = try await session.commitDelete()
                deletedCount += result.count
                freedBytes += Int(result.bytes)
                doneText = "\(result.count) öğe silindi\n~\(ByteText.text(result.bytes)) yer açıldı"
            } catch {
                if let pe = error as? PHPhotosError, pe.code == .userCancelled {
                    errorText = "Silme işlemi iptal edildi."
                } else {
                    errorText = error.localizedDescription
                }
            }
            isDeleting = false
        }
    }
}
