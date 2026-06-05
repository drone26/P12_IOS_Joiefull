//
//  ClothingCardView.swift
//  ClothingCardView
//
//  Created by Mathieu ARRIO on 13/05/2026.
//

import SwiftUI

struct ClothingCardView: View {
    let item: ClothingItem
    let rating: Double
    var isSelected = false
    
    @Environment(LikesViewModel.self) private var likesViewModel

    @ScaledMetric private var cardWidth: CGFloat = 180
    @ScaledMetric private var imageHeight: CGFloat = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            imageSection
            infoSection
        }
        .frame(width: cardWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 3)
            }
        }
        .accessibilityElement(children: .ignore)
        .frAccessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: likesViewModel.isLiked(clothingId: item.id) ? "Retirer des favoris" : "Ajouter aux favoris") {
            Task { await likesViewModel.toggleLike(for: item.id) }
        }
    }

    private var accessibilityDescription: String {
        let ratingText = String(format: "%.1f", rating)
        let priceText = item.price.formatted(.currency(code: "EUR"))
        var parts = [
            item.name,
            item.picture.description,
            "noté \(ratingText) sur 5",
            "prix \(priceText)"
        ]
        if item.originalPrice != item.price {
            parts.append("ancien prix \(item.originalPrice.formatted(.currency(code: "EUR")))")
        }
        if likesViewModel.isLiked(clothingId: item.id) {
            parts.append("Favori")
        }
        parts.append("\(likesViewModel.likesCount(for: item.id)) jaime")
        return parts.joined(separator: ", ")
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
    }

    private var likeBadge: some View {
        Button {
            Task { await likesViewModel.toggleLike(for: item.id) }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: likesViewModel.isLiked(clothingId: item.id) ? "heart.fill" : "heart")
                    .foregroundStyle(likesViewModel.isLiked(clothingId: item.id) ? .red : .primary)
                    .font(.caption.bold())
                    .accessibilityHidden(true)
                Text("\(likesViewModel.likesCount(for: item.id))")
                    .foregroundStyle(.primary)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.regularMaterial, in: .capsule)
        }
        .buttonStyle(.plain)
        .padding(8)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top) {
                Text(item.name)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                ratingLabel
            }
            Spacer(minLength: 0)
            HStack {
                Text(item.price, format: .currency(code: "EUR"))
                    .font(.subheadline.bold())
                if item.originalPrice != item.price {
                    Text(item.originalPrice, format: .currency(code: "EUR"))
                        .font(.caption)
                        .strikethrough()
                }
            }
        }
    }

    private var ratingLabel: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .foregroundStyle(.orange)
                .font(.caption)
                .accessibilityHidden(true)
            Text(rating, format: .number.precision(.fractionLength(1)))
                .font(.caption)
        }
    }
}
