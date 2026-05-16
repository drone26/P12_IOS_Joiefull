import Foundation

@Observable
final class CatalogViewModel {
    private(set) var clothesByCategory: [Category: [ClothingItem]] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let repository: ClothesRepositoryProtocol

    init(repository: ClothesRepositoryProtocol = ClothesRepository()) {
        self.repository = repository
    }

    func loadClothes() async {
        isLoading = true
        errorMessage = nil
        do {
            let items = try await repository.fetchClothes()
            clothesByCategory = Dictionary(grouping: items, by: \.category)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
