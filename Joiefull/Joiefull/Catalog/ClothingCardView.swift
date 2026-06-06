//
//  ClothingCardView.swift
//  ClothingCardView
//
//  Created by Mathieu ARRIO on 13/05/2026.
//

import SwiftUI

struct ClothingCardView: View {
    let viewModel: ClothingCardViewModel
    var isSelected = false

    @ScaledMetric private var cardWidth: CGFloat = 198
    @ScaledMetric private var imageHeight: CGFloat = 198

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
        .frAccessibilityLabel(viewModel.accessibilityDescription)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(named: viewModel.isLiked ? "Retirer des favoris" : "Ajouter aux favoris") {
            Task { await viewModel.toggleLike() }
        }
    }

    private var imageSection: some View {
        AsyncImage(url: viewModel.item.picture.url) { image in
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
            Task { await viewModel.toggleLike() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(viewModel.isLiked ? .red : .primary)
                    .font(.caption.bold())
                    .accessibilityHidden(true)
                Text("\(viewModel.likesCount)")
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
                Text(viewModel.item.name)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                ratingLabel
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            HStack {
                Text(viewModel.formattedPrice)
                    .font(.subheadline.bold())
                    .fixedSize(horizontal: false, vertical: true)
                if let oldPrice = viewModel.formattedOriginalPrice {
                    Text(oldPrice)
                        .font(.caption)
                        .strikethrough()
                        .fixedSize(horizontal: false, vertical: true)
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
            Text(viewModel.formattedRating)
                .font(.caption)
        }
    }
}
