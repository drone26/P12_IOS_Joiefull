import Foundation

struct Like: Codable, Identifiable, Sendable {
    let id: Int
    let clothingId: Int
    let userId: Int

    enum CodingKeys: String, CodingKey {
        case id
        case clothingId = "clothing_id"
        case userId = "user_id"
    }
}
