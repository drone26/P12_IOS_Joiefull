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
    
    @Environment(FavoritesManager.self) private var favoritesManager

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
        .accessibilityElement(children: .ignore)
        .frAccessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: favoritesManager.isFavorite(id: item.id) ? "Retirer des favoris" : "Ajouter aux favoris") {
            favoritesManager.toggleFavorite(for: item.id)
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
        if favoritesManager.isFavorite(id: item.id) {
            parts.append("Favori")
        }
        parts.append("\(favoritesManager.likesCount(for: item)) jaime")
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
            favoritesManager.toggleFavorite(for: item.id)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: favoritesManager.isFavorite(id: item.id) ? "heart.fill" : "heart")
                    .foregroundStyle(favoritesManager.isFavorite(id: item.id) ? .red : .primary)
                Text("\(favoritesManager.likesCount(for: item))")
                    .foregroundStyle(.primary)
            }
            .font(.caption)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: .capsule)
        }
        .buttonStyle(.borderless)
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
            Text(rating, format: .number.precision(.fractionLength(1)))
        }
        .font(.caption)
    }
}
