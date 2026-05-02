import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: "Další akce? Možná někdy...

private let jsonSession: URLSession = {
    let config = URLSessionConfiguration.default
    // Vynutíme stažení čerstvých dat ze serveru a ignorujeme lokální mezipaměť
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    return URLSession(configuration: config)
}()

func ApkMessageParser() async -> String {
    guard let url = URL(string: "https://www.dopravnifotoakce.cz/admin/data/apk_info.json") else {
        return ""
    }

    do {
        let (data, _) = try await jsonSession.data(from: url)
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let text = json["text"] as? String {
            return text
        }
        
    } catch {
        print("Error: \(error)")
    }

    return ""
}

// MARK: Contact parser

internal struct ContactItem: Identifiable, Decodable {
    var id: String { name }
    let name: String
    let description: String
    let phone: String
    let emails: [String]
    let permission: String?

    private enum CodingKeys: String, CodingKey {
        case name = "Name"
        case description
        case phone = "Phone"
        case emails = "Emails"
        case permission
    }
}

fileprivate struct ISResponse: Decodable {
    let generalInfo: GeneralInfo
    
    struct GeneralInfo: Decodable {
        let contacts: [ContactItem]
        enum CodingKeys: String, CodingKey {
            case contacts = "Contacts"
        }
    }
}

func ContactParser(isOrganizator: Bool) async -> [ContactItem] {
    guard let url = URL(string: "https://www.dopravnifotoakce.cz/admin/data/IS.json") else {
        return []
    }

    do {
        let (data, _) = try await jsonSession.data(from: url)
        let decoded = try JSONDecoder().decode(ISResponse.self, from: data)
        
        if isOrganizator {
            return decoded.generalInfo.contacts
        } else {
            return decoded.generalInfo.contacts.filter { $0.permission == "public" }
        }
    } catch {
        print("Error parsing contacts: \(error)")
        return []
    }
}
