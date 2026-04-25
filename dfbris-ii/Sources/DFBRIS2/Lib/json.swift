import SwiftyJSON
import Foundation

func ApkMessageParser() async -> String {
    let urlString = "https://www.dopravnifotoakce.cz/admin/data/apk_info.json"

    guard let url = URL(string: urlString) else {
        return ""
    }

    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSON(data: data)

        return json["text"].stringValue

    } catch {
        return ""
    }
}
