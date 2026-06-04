import Foundation
import Observation

@Observable
final class LikesRepository: @unchecked Sendable {
    static let shared = LikesRepository()
    
    private let apiService: APIService
    private(set) var likes: [Like] = []
    
    // For now, let's use a static user ID since auth isn't fully implemented
    var currentUserId: Int = 2
    
    init(apiService: APIService = APIService()) {
        self.apiService = apiService
    }
    
    func loadLikes() async {
        do {
            let fetchedLikes: [Like] = try await apiService.request(Endpoint.fetchLikes)
            await MainActor.run {
                self.likes = fetchedLikes
            }
        } catch {
            print("Error fetching likes: \(error)")
        }
    }
    
    func toggleLike(for clothingId: Int) {
        if let index = likes.firstIndex(where: { $0.clothingId == clothingId && $0.userId == currentUserId }) {
            likes.remove(at: index)
        } else {
            let newId = (likes.map { $0.id }.max() ?? 0) + 1
            let newLike = Like(id: newId, clothingId: clothingId, userId: currentUserId)
            likes.append(newLike)
        }
    }
    
    func isLiked(clothingId: Int) -> Bool {
        likes.contains(where: { $0.clothingId == clothingId && $0.userId == currentUserId })
    }
    
    func likesCount(for clothingId: Int) -> Int {
        likes.filter { $0.clothingId == clothingId }.count
    }
    
    private enum Endpoint: APIEndpoint {
        case fetchLikes
        
        var baseURL: URL? { Constants.API.baseURL }
        
        var path: String {
            switch self {
            case .fetchLikes:
                return "likes/"
            }
        }
        
        var method: HTTPMethod { .get }
        var headers: [String: String]? { nil }
        var body: Data? { nil }
    }
}
