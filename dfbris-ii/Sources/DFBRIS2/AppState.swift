//
//  Untitled.swift
//  dfbris-ii
//
//  Created by Tomáš Němec on 27.04.2026.
//

import SwiftUI
import SkipFuse

// MARK: - Tab enum (globální)
enum TabItem: Hashable {
    case home
    case transport
    case dfb
    case rezsys
}

enum AppState {
    private static let switchTabName = Notification.Name("DFBRIS2.SwitchTab")
    private static let tabKey = "tab"

    static func requestTabSwitch(to tab: TabItem) {
        NotificationCenter.default.post(name: switchTabName, object: nil, userInfo: [tabKey: tab])
    }

    static func observeTabSwitch(_ handler: @Sendable @escaping (TabItem) -> Void) -> NSObjectProtocol {
        NotificationCenter.default.addObserver(forName: switchTabName, object: nil, queue: .main) { notification in
            guard let tab = notification.userInfo?[tabKey] as? TabItem else {
                return
            }
            handler(tab)
        }
    }

    static func removeObserver(_ observer: NSObjectProtocol) {
        NotificationCenter.default.removeObserver(observer)
    }
}
