import SwiftUI
import Photos

/// Ana kaydırma ekranı: SOLA = TUT, SAĞA = SİL
struct SwipeSessionView: View {
    @StateObject private var session: SwipeSession
    @AppStorage("skipReviewed") private var skipReviewed = true
    @Environment(\.dismiss) private var dismiss

    @State private var offset: CGSize = .zero
    @State private var isFlinging = false
    @State private var showReview = false
    @State private var showExitDialog = false

    private let threshold: CGFloat = 110

    init(mode: CleanMode) {
        _session = StateObject(wrappedValue: SwipeSession(mode: mode))
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            ZStack {
                if session.isLoading {
                    ProgressView("Yükleniyor…")
                } else if let current = session.current {
                    if let next = session.next {
                        AssetCardView(asset: next)
                            .id("next-" + next.localIdentifier)
                            .scaleEffect(0.94)
                            .opacity(0.5)
                            .allowsHitTesting(false)
                    }
                    AssetCardView(asset: current)
                        .id(current.localIdentifier)
                        .overlay(alignment: .top) { swipeBadge }
                        .offset(x: offset.width, y: offset.height * 0.15)
                        .rotationEffect(.degrees(Double(offset.width / 22)))
                        .gesture(dragGesture)
                } else {
                    finishedView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)

            if session.current != nil && !session.isLoading {
                controls
            }
        }
        .padding(.bottom, 8)
        .navigationTitle(session.mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if session.toDelete.isEmpty { dismiss() } else { showExitDialog = true }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Modlar")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showReview = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("\(session.toDelete.count)")
                    }
                }
                .disabled(session.toDelete.isEmpty)
            }
        }
        .confirmationDialog("Silinmeyi bekleyen \(session.toDelete.count) öğe var",
                            isPresented: $showExitDialog, titleVisibility: .visible) {
            Button("Gözden geçir ve sil") { showReview = true }
            Button("Silmeden çık", role: .destructive) { dismiss() }
            Button("Vazgeç", role: .cancel) {}
        }
        .sheet(isPresented: $showReview) {
            ReviewView(session: session)
        }
        .task {
            if !session.hasLoaded {
                await session.load(skipReviewed: skipReviewed)
            }
        }
    }

    // MARK: - Parçalar

    private var header: some View {
        VStack(spacing: 6) {
            if session.total > 0 {
                ProgressView(value: Double(session.total - session.remaining), total: Double(session.total))
                    .tint(.blue)
            }
            HStack {
                Label("Kalan \(session.remaining)", systemImage: "square.stack")
                Spacer()
                Label("Tutulan \(session.keptCount)", systemImage: "checkmark.circle")
                    .foregroundColor(.green)
                Spacer()
                Label("Silinecek \(session.toDelete.count)", systemImage: "trash")
                    .foregroundColor(.red)
            }
            .font(.caption)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var swipeBadge: some View {
        let progress = min(abs(offset.width) / threshold, 1)
        let isKeep = offset.width < 0
        return Text(isKeep ? "TUT" : "SİL")
            .font(.system(size: 34, weight: .heavy))
            .foregroundColor(isKeep ? .green : .red)
            .padding(.horizontal, 18)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isKeep ? Color.green : Color.red, lineWidth: 4)
            )
            .background(Color(.systemBackground).opacity(0.75).cornerRadius(10))
            .rotationEffect(.degrees(isKeep ? 12 : -12))
            .padding(.top, 30)
            .opacity(offset.width == 0 ? 0 : Double(progress))
    }

    private var controls: some View {
        HStack(spacing: 28) {
            circleButton(icon: "checkmark", color: .green, label: "Tut") { fling(.keep) }
            circleButton(icon: "arrow.uturn.backward", color: .gray, label: "Geri al", small: true) {
                withAnimation(.spring()) { session.undo() }
            }
            .disabled(!session.canUndo)
            .opacity(session.canUndo ? 1 : 0.4)
            circleButton(icon: "trash", color: .red, label: "Sil") { fling(.delete) }
        }
    }

    private func circleButton(icon: String, color: Color, label: String, small: Bool = false,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: small ? 20 : 28, weight: .bold))
                    .foregroundColor(color)
                    .frame(width: small ? 52 : 70, height: small ? 52 : 70)
                    .background(Circle().fill(color.opacity(0.15)))
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var finishedView: some View {
        VStack(spacing: 16) {
            Image(systemName: session.total == 0 ? "tray" : "sparkles")
                .font(.system(size: 56))
                .foregroundColor(.blue)
            Text(session.total == 0 ? "Bu modda gösterilecek öğe yok" : "Hepsi bu kadar!")
                .font(.title2.bold())
            if session.total > 0 {
                Text("\(session.keptCount) tutuldu · \(session.toDelete.count) silinecek")
                    .foregroundColor(.secondary)
            }
            if !session.toDelete.isEmpty {
                Button {
                    showReview = true
                } label: {
                    Label("Silinecekleri gözden geçir (\(session.toDelete.count))", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.horizontal, 30)
            } else {
                Button("Ana sayfaya dön") { dismiss() }
                    .buttonStyle(.bordered)
            }
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Hareket

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isFlinging else { return }
                offset = value.translation
            }
            .onEnded { value in
                guard !isFlinging else { return }
                let dx = value.translation.width
                let predicted = value.predictedEndTranslation.width
                if dx < -threshold || predicted < -350 {
                    fling(.keep)           // SOLA = TUT
                } else if dx > threshold || predicted > 350 {
                    fling(.delete)         // SAĞA = SİL
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { offset = .zero }
                }
            }
    }

    private func fling(_ decision: SwipeSession.Decision) {
        guard !isFlinging, session.current != nil else { return }
        isFlinging = true
        let generator = UIImpactFeedbackGenerator(style: decision == .delete ? .medium : .light)
        generator.impactOccurred()
        let targetX: CGFloat = decision == .keep ? -700 : 700
        withAnimation(.easeIn(duration: 0.22)) {
            offset = CGSize(width: targetX, height: offset.height)
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            session.decide(decision)
            offset = .zero
            isFlinging = false
        }
    }
}
