import SwiftUI

struct ClothingCardView: View {
    let item: ClothingItem
    var isSelected = false

    private let cardWidth: CGFloat = 180
    private let imageHeight: CGFloat = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            imageSection
            infoSection
        }
        .frame(width: cardWidth)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 3)
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
        .frame(width: cardWidth, height: imageHeight)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(alignment: .bottomTrailing) {
            likeBadge
        }
        .accessibilityLabel(item.picture.description)
    }

    private var likeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart")
            Text("\(item.likes)")
        }
        .font(.caption)
        .bold()
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: .capsule)
        .padding(8)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)
                Spacer()
                ratingLabel
            }
            HStack {
                Text(item.price, format: .currency(code: "EUR"))
                    .font(.subheadline)
                    .bold()
                if item.originalPrice != item.price {
                    Text(item.originalPrice, format: .currency(code: "EUR"))
                        .font(.caption)
                        .strikethrough()
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var ratingLabel: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .foregroundStyle(.orange)
            Text(item.rating, format: .number.precision(.fractionLength(1)))
        }
        .font(.caption)
    }
}
