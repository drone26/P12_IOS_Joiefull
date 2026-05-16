//
//  ClothingDetailView.swift
//  ClothingDetailView
//
//  Created by Mathieu ARRIO on 13/05/2026.
//

import SwiftUI

struct ClothingDetailView: View {
    let item: ClothingItem

    @State private var userRating = 0
    @State private var reviewText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                imageSection
                infoSection
                descriptionSection
                ratingSection
            }
            .frame(maxWidth: 430)
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
        }
        .padding(.horizontal)
        .accessibilityLabel(item.picture.description)
    }

    private var infoSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.title2)
                    .bold()
                Text(item.price, format: .currency(code: "EUR"))
                    .font(.title3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.orange)
                    Text(item.rating, format: .number.precision(.fractionLength(1)))
                }
                .font(.title3)
                if item.originalPrice != item.price {
                    Text(item.originalPrice, format: .currency(code: "EUR"))
                        .strikethrough()
                        .foregroundStyle(.secondary)
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

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            userRating = star
                        } label: {
                            Image(systemName: star <= userRating ? "star.fill" : "star")
                                .foregroundStyle(star <= userRating ? .orange : .gray)
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(star) étoile\(star > 1 ? "s" : "")")
                    }
                }
            }

            TextField("Partagez ici vos impressions sur cette pièce", text: $reviewText, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal)
    }
}
