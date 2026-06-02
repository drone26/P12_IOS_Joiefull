import Foundation
import Observation

@Observable
final class FavoritesManager {
    static let shared = FavoritesManager()
    
    private let defaults = UserDefaults.standard
    private let favoritesKey = "joiefull_favorites"
    
    private(set) var favoriteIDs: Set<Int> = []
    
    init() {
        if CommandLine.arguments.contains("-resetFavorites") {
            defaults.removeObject(forKey: favoritesKey)
        }
        if let data = defaults.data(forKey: favoritesKey),
           let savedFavorites = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            self.favoriteIDs = savedFavorites
        }
    }
    
    func toggleFavorite(for id: Int) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
        save()
    }
    
    func isFavorite(id: Int) -> Bool {
        favoriteIDs.contains(id)
    }
    
    func likesCount(for item: ClothingItem) -> Int {
        return item.likes + (isFavorite(id: item.id) ? 1 : 0)
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(favoriteIDs) {
            defaults.set(encoded, forKey: favoritesKey)
        }
    }
}
