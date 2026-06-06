//
//  CatalogView.swift
//  CatalogView
//
//  Created by Mathieu ARRIO on 13/05/2026.
//

import SwiftUI

struct CatalogView: View {
    let clothesByCategory: [Category: [ClothingItem]]
    let rating: (ClothingItem) -> Double
    let likesCount: (ClothingItem) -> Int
    let isLiked: (ClothingItem) -> Bool
    let toggleLike: (ClothingItem) async -> Void
    let selectedItem: Binding<ClothingItem?>

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(Category.allCases, id: \.self) { category in
                    if let items = clothesByCategory[category], !items.isEmpty {
                        CategorySection(
                            category: category,
                            items: items,
                            rating: rating,
                            likesCount: likesCount,
                            isLiked: isLiked,
                            toggleLike: toggleLike,
                            selectedItem: selectedItem
                        )
                    }
                }
            }
        }
    }
}

private struct CategorySection: View {
    let category: Category
    let items: [ClothingItem]
    let rating: (ClothingItem) -> Double
    let likesCount: (ClothingItem) -> Int
    let isLiked: (ClothingItem) -> Bool
    let toggleLike: (ClothingItem) async -> Void
    let selectedItem: Binding<ClothingItem?>

    var body: some View {
        VStack(alignment: .leading) {
            Text(category.displayName)
                .font(.title2.bold())
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(items) { item in
                        Button {
                            selectedItem.wrappedValue = item
                        } label: {
                            ClothingCardView(
                                viewModel: ClothingCardViewModel(
                                    item: item,
                                    rating: rating(item),
                                    likesCount: likesCount(item),
                                    isLiked: isLiked(item),
                                    toggleLike: { await toggleLike(item) }
                                ),
                                isSelected: selectedItem.wrappedValue?.id == item.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }
}
