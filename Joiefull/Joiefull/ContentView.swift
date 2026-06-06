//
//  ContentView.swift
//  ContentView
//
//  Created by Mathieu ARRIO on 12/05/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = CatalogViewModel()
    @State private var selectedItem: ClothingItem?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var likesViewModel = LikesViewModel()

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                tabletLayout
            } else {
                phoneLayout
            }
        }
        .environment(\.locale, Locale(identifier: "fr_FR"))
        .onChange(of: likesViewModel.likes) { _, _ in }
        .onChange(of: viewModel.averagesByItemID) { _, _ in }
    }

    private var tabletLayout: some View {
        HStack(spacing: 0) {
            NavigationStack {
                CatalogView(
                    clothesByCategory: viewModel.clothesByCategory,
                    rating: viewModel.averageRating(for:),
                    likesCount: { item in likesViewModel.likesCount(for: item.id) },
                    isLiked: { item in likesViewModel.isLiked(clothingId: item.id) },
                    toggleLike: { item in await likesViewModel.toggleLike(for: item.id) },
                    selectedItem: $selectedItem
                )
                .navigationTitle("Joiefull")
            }
            .frame(maxWidth: .infinity)

            if let item = selectedItem {
                Divider()
                ClothingDetailView(
                    item: item,
                    likesCount: likesViewModel.likesCount(for: item.id),
                    isLiked: likesViewModel.isLiked(clothingId: item.id),
                    toggleLike: { await likesViewModel.toggleLike(for: item.id) },
                    onSubmit: {
                        await viewModel.refreshAverages()
                    }
                )
                    .id(item.id)
                    .frame(maxWidth: .infinity)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.default, value: selectedItem?.id)
        .task {
            await viewModel.loadClothes()
            await likesViewModel.loadLikes()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }

    private var phoneLayout: some View {
        NavigationStack {
            CatalogView(
                clothesByCategory: viewModel.clothesByCategory,
                rating: viewModel.averageRating(for:),
                likesCount: { item in likesViewModel.likesCount(for: item.id) },
                isLiked: { item in likesViewModel.isLiked(clothingId: item.id) },
                toggleLike: { item in await likesViewModel.toggleLike(for: item.id) },
                selectedItem: $selectedItem
            )
            .navigationTitle("Joiefull")
            .navigationDestination(item: $selectedItem) { item in
                ClothingDetailView(
                    item: item,
                    likesCount: likesViewModel.likesCount(for: item.id),
                    isLiked: likesViewModel.isLiked(clothingId: item.id),
                    toggleLike: { await likesViewModel.toggleLike(for: item.id) },
                    onSubmit: {
                        await viewModel.refreshAverages()
                    }
                )
            }
        }
        .task {
            await viewModel.loadClothes()
            await likesViewModel.loadLikes()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}

#Preview {
    ContentView()
}
