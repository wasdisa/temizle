import SwiftUI
import Photos
import AVKit

/// Kaydırılan büyük kart
struct AssetCardView: View {
    let asset: PHAsset
    @State private var image: UIImage?
    @State private var requestID: PHImageRequestID?
    @State private var sizeText = ""
    @State private var showPlayer = false

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
            }

            if asset.mediaType == .video {
                Button {
                    showPlayer = true
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.white)
                        .shadow(radius: 8)
                }
            }

            VStack {
                Spacer()
                infoBar
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        .onAppear(perform: load)
        .onDisappear {
            if let requestID { ImageLoader.cancel(requestID) }
        }
        .sheet(isPresented: $showPlayer) {
            VideoPlayerSheet(asset: asset)
        }
    }

    private var infoBar: some View {
        HStack(spacing: 10) {
            Image(systemName: asset.mediaType == .video ? "video.fill" : "photo")
            Text(MonthFormatter.dateText(asset.creationDate))
            Spacer()
            if asset.mediaType == .video {
                Text(durationText(asset.duration))
            }
            if !sizeText.isEmpty {
                Text(sizeText).bold()
            }
        }
        .font(.footnote)
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.45))
    }

    private func load() {
        requestID = ImageLoader.request(asset, size: ImageLoader.cardSize) { img in
            if let img { image = img }
        }
        let a = asset
        Task.detached(priority: .utility) {
            let bytes = PhotoLibrary.fileSize(a)
            await MainActor.run {
                sizeText = bytes > 0 ? ByteText.text(bytes) : ""
            }
        }
    }

    private func durationText(_ t: TimeInterval) -> String {
        let s = Int(t.rounded())
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

/// İnceleme ekranındaki küçük kare
struct ThumbnailView: View {
    let asset: PHAsset
    @State private var image: UIImage?

    var body: some View {
        Color(.secondarySystemBackground)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .overlay(alignment: .bottomLeading) {
                if asset.mediaType == .video {
                    Image(systemName: "video.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(5)
                        .shadow(radius: 2)
                }
            }
            .clipped()
            .onAppear {
                ImageLoader.request(asset, size: ImageLoader.thumbSize, contentMode: .aspectFill) { img in
                    if let img { image = img }
                }
            }
    }
}

/// Videoyu oynatmak için açılan sayfa
struct VideoPlayerSheet: View {
    let asset: PHAsset
    @State private var player: AVPlayer?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let player {
                    VideoPlayer(player: player)
                        .onAppear { player.play() }
                } else {
                    ProgressView("Video yükleniyor…")
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
        .onAppear {
            let o = PHVideoRequestOptions()
            o.isNetworkAccessAllowed = true
            o.deliveryMode = .automatic
            PHImageManager.default().requestPlayerItem(forVideo: asset, options: o) { item, _ in
                DispatchQueue.main.async {
                    if let item { player = AVPlayer(playerItem: item) }
                }
            }
        }
        .onDisappear { player?.pause() }
    }
}
