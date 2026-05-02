import SwiftUI
import SkipFuse

struct ContentView: View {

    @State internal var selectedTab: TabItem = .home
    @State internal var navigationVersions: [TabItem: Int] = [
        .home: 0,
        .transport: 0,
        .dfb: 0,
        .rezsys: 0,
    ]
    @State internal var tabSwitchObserver: NSObjectProtocol?

    var body: some View {
        TabView(selection: $selectedTab) {

            Tab("Home",
                systemImage: icon(.home, "house"),
                value: .home) {
                NavigationStack {
                    HomeScreen()
                }
                .id(navigationVersion(for: .home))
            }

            Tab("Transport",
                systemImage: icon(.transport, "lightrail"),
                value: .transport) {
                NavigationStack {
                    Transport()
                }
                .id(navigationVersion(for: .transport))
            }

            Tab("DFB",
                systemImage: icon(.dfb, "camera"),
                value: .dfb) {
                NavigationStack {
                    DFB()
                }
                .id(navigationVersion(for: .dfb))
            }

            Tab("RezSys",
                systemImage: icon(.rezsys, "wallet.bifold"),
                value: .rezsys) {
                NavigationStack {
                    RezSys()
                }
                .id(navigationVersion(for: .rezsys))
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            resetNavigation(for: newTab)
        }
        .onAppear {
            if tabSwitchObserver == nil {
                tabSwitchObserver = AppState.observeTabSwitch { tab in
                    selectedTab = tab
                }
            }
        }
        .onDisappear {
            if let tabSwitchObserver {
                AppState.removeObserver(tabSwitchObserver)
                self.tabSwitchObserver = nil
            }
        }
        #if targetEnvironment(macCatalyst)
            .tabViewStyle(.sidebarAdaptable)
        #else
            .tabViewStyle(.automatic)
        #endif
        .tint(colorForTab(selectedTab))
    }

    // MARK: - ikonky (.fill pro aktivní tab)
    func icon(_ tab: TabItem, _ name: String) -> String {
        selectedTab == tab ? "\(name).fill" : name
    }

    func navigationVersion(for tab: TabItem) -> Int {
        navigationVersions[tab, default: 0]
    }

    func resetNavigation(for tab: TabItem) {
        navigationVersions[tab, default: 0] += 1
    }

    // MARK: - barvy tabů
    func colorForTab(_ tab: TabItem) -> Color {
        switch tab {
        case .transport:
            return AppColor("TransportColor", fallback: .red)
        case .dfb:
            return AppColor("DFBColor", fallback: .yellow)
        case .rezsys:
            return AppColor("RezSysColor", fallback: .blue)
        default:
            return .accentColor
        }
    }
}
