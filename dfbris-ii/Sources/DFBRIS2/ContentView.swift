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

            homeTab
            transportTab
            dfbTab
            rezsysTab
        }
        .onChange(of: selectedTab) { _, newTab in
            resetNavigation(for: newTab)
        }
        .onAppear {
            if tabSwitchObserver == nil {
                tabSwitchObserver = AppState.observeTabSwitch { tab in
                    Task { @MainActor in
                        selectedTab = tab
                    }
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

    // MARK: - Tabs

    private var homeTab: some View {
        NavigationStack {
            HomeScreen()
        }
        .id(navigationVersion(for: .home))
        .tabItem {
            Label("Home", systemImage: icon(.home, "house"))
        }
        .tag(TabItem.home)
    }

    private var transportTab: some View {
        NavigationStack {
            Transport()
        }
        .id(navigationVersion(for: .transport))
        .tabItem {
            Label("Transport", systemImage: icon(.transport, "lightrail"))
        }
        .tag(TabItem.transport)
    }

    private var dfbTab: some View {
        NavigationStack {
            DFB()
        }
        .id(navigationVersion(for: .dfb))
        .tabItem {
            Label("DFB", systemImage: icon(.dfb, "camera"))
        }
        .tag(TabItem.dfb)
    }

    private var rezsysTab: some View {
        NavigationStack {
            RezSys()
        }
        .id(navigationVersion(for: .rezsys))
        .tabItem {
            Label("RezSys", systemImage: icon(.rezsys, "wallet.bifold"))
        }
        .tag(TabItem.rezsys)
    }

    // MARK: - ikonky (.fill pro aktivní tab)

    func icon(_ tab: TabItem, _ name: String) -> String {
        selectedTab == tab ? "\(name).fill" : name
    }

    // MARK: - Navigation reset

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
            return AppColor("DFBColor", fallback: .green)
        case .rezsys:
            return AppColor("RezSysColor", fallback: .blue)
        default:
            return .accentColor
        }
    }
}
