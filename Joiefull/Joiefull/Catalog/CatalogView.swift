import SwiftUI

struct CatalogView: View {
    let clothesByCategory: [Category: [ClothingItem]]
    let selectedItem: Binding<ClothingItem?>

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(Category.allCases, id: \.self) { category in
                    if let items = clothesByCategory[category], !items.isEmpty {
                        CategorySection(
                            category: category,
                            items: items,
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
    let selectedItem: Binding<ClothingItem?>

    var body: some View {
        VStack(alignment: .leading) {
            Text(category.displayName)
                .font(.title2)
                .bold()
                .padding(.horizontal)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach(items) { item in
                        Button {
                            selectedItem.wrappedValue = item
                        } label: {
                            ClothingCardView(item: item, isSelected: selectedItem.wrappedValue?.id == item.id)
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
