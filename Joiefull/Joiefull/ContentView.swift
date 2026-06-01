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

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                tabletLayout
            } else {
                phoneLayout
            }
        }
        .environment(\.locale, Locale(identifier: "fr_FR"))
    }

    private var tabletLayout: some View {
        HStack(spacing: 0) {
            NavigationStack {
                CatalogView(
                    clothesByCategory: viewModel.clothesByCategory,
                    rating: viewModel.averageRating(for:),
                    selectedItem: $selectedItem
                )
                .navigationTitle("Joiefull")
            }
            .frame(maxWidth: .infinity)

            if let item = selectedItem {
                Divider()
                ClothingDetailView(item: item, onSubmit: { [viewModel] in
                    await viewModel.refreshAverages()
                })
                    .id(item.id)
                    .frame(maxWidth: .infinity)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.default, value: selectedItem?.id)
        .task {
            await viewModel.loadClothes()
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
                selectedItem: $selectedItem
            )
            .navigationTitle("Joiefull")
            .navigationDestination(item: $selectedItem) { item in
                ClothingDetailView(item: item, onSubmit: { [viewModel] in
                    await viewModel.refreshAverages()
                })
            }
        }
        .task {
            await viewModel.loadClothes()
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
