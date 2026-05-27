import SwiftUI

struct ClothingDetailView: View {
    @State private var viewModel: ClothingDetailViewModel
    private let onSubmit: (@Sendable () async -> Void)?

    init(item: ClothingItem, onSubmit: (@Sendable () async -> Void)? = nil) {
        _viewModel = State(initialValue: ClothingDetailViewModel(item: item))
        self.onSubmit = onSubmit
    }

    private var item: ClothingItem { viewModel.item }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                imageSection
                infoSection
                descriptionSection
                ratingSection(reviewText: $viewModel.reviewText)
                reviewsSection
            }
            .frame(maxWidth: 430)
        }
        .task {
            await viewModel.load()
        }
        .onDisappear {
            let model = self.viewModel
            let onSubmit = self.onSubmit
            Task {
                await model.submitReview()
                await onSubmit?()
            }
        }
    }

    private var imageSection: some View {
        AsyncImage(url: item.picture.url) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Rectangle()
                .foregroundStyle(.quaternary)
                .overlay {
                    ProgressView()
                }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 400)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(alignment: .topTrailing) {
            ShareLink(item: item.picture.url) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .padding(10)
                    .background(.ultraThinMaterial, in: .circle)
            }
            .padding(12)
            .frAccessibilityLabel("Partager")
        }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 4) {
                Image(systemName: "heart")
                Text("\(item.likes)")
            }
            .font(.title3)
            .bold()
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: .capsule)
            .padding(12)
            .accessibilityElement(children: .ignore)
            .frAccessibilityLabel("\(item.likes) j'aime")
        }
        .padding(.horizontal)
        .frAccessibilityLabel(item.picture.description)
    }

    private var infoSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.title2)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                Text(item.price, format: .currency(code: "EUR"))
                    .font(.title3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.orange)
                    Text(viewModel.averageRating, format: .number.precision(.fractionLength(1)))
                }
                .font(.title3)
                .accessibilityElement(children: .ignore)
                .frAccessibilityLabel("Note moyenne \(String(format: "%.1f", viewModel.averageRating)) sur 5")
                if item.originalPrice != item.price {
                    Text(item.originalPrice, format: .currency(code: "EUR"))
                        .strikethrough()
                        .foregroundStyle(.secondary)
                        .frAccessibilityLabel("Ancien prix \(item.originalPrice.formatted(.currency(code: "EUR")))")
                }
            }
        }
        .padding(.horizontal)
    }

    private var descriptionSection: some View {
        Text(item.picture.description)
            .font(.body)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
    }

    private func ratingSection(reviewText: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                UserAvatar(url: viewModel.currentUser?.avatarURL, size: 40)
                    .accessibilityHidden(true)

                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            viewModel.userRating = star
                        } label: {
                            Image(systemName: star <= viewModel.userRating ? "star.fill" : "star")
                                .foregroundStyle(star <= viewModel.userRating ? .orange : .gray)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)

                        .frAccessibilityLabel(starLabel(for: star))
                        .accessibilityAddTraits(star == viewModel.userRating ? [.isButton, .isSelected] : .isButton)
                    }
                }
            }

            TextField("Partagez ici vos impressions sur cet article", text: reviewText, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
                .frAccessibilityLabel("Votre avis")
                .frAccessibilityHint("Partagez ici vos impressions sur cet article")
        }
        .padding(.horizontal)
    }

    private func starLabel(for star: Int) -> String {
        let plural = star > 1 ? "s" : ""
        return "Noter \(star) étoile\(plural)"
    }

    @ViewBuilder
    private var reviewsSection: some View {
        if !viewModel.itemReviews.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Avis (\(viewModel.itemReviews.count))")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                ForEach(viewModel.itemReviews) { review in
                    ReviewRow(review: review, author: viewModel.user(for: review))
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct ReviewRow: View {
    let review: Review
    let author: User?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                UserAvatar(url: author?.avatarURL, size: 28)
                    .accessibilityHidden(true)
                Text(author?.fullName ?? "Utilisateur")
                    .font(.subheadline)
                    .bold()
                Spacer()
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= review.rating ? "star.fill" : "star")
                            .foregroundStyle(star <= review.rating ? .orange : .gray)
                            .font(.caption)
                    }
                }
            }
            Text(review.text)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .frAccessibilityLabel("\(author?.fullName ?? "Utilisateur"), \(review.rating) étoile\(review.rating > 1 ? "s" : "") sur 5. \(review.text)")
    }
}
private struct UserAvatar: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
    }

    private var placeholder: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
    }
}

