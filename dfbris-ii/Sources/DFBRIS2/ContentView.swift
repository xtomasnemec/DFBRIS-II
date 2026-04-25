import SwiftUI

// test
let isOrganizator = true

struct ContentView: View {
    
    enum TabItem: Hashable {
        case home, transport, dfb, rezsys
    }
    
    @State var selectedTab: TabItem = .home
    
    //tab system
    var body: some View {
        TabView(selection: $selectedTab) {
            
            Tab("Home",
                systemImage: selectedTab == .home ? "house.fill" : "house",
                value: .home) {
                NavigationStack {
                    HomeScreen()
                }
            }
            
            Tab("Transport",
                systemImage: selectedTab == .transport ? "lightrail.fill" : "lightrail",
                value: .transport) {
                NavigationStack {
                    Transport()
                }
            }
            
            Tab("DFB",
                systemImage: selectedTab == .dfb ? "camera.fill" : "camera",
                value: .dfb) {
                NavigationStack {
                    DFB()
                }
            }
            
            Tab("RezSys",
                systemImage: selectedTab == .rezsys ? "wallet.bifold.fill" : "wallet.bifold",
                value: .rezsys) {
                NavigationStack {
                    RezSys()
                }
            }
        }
        .tabViewStyle(.tabBarOnly)
        .tint(selectedTab == .transport ? Color("TransportColor", bundle: .module):
              selectedTab == .dfb ? Color("DFBColor", bundle: .module):
              selectedTab == .rezsys ? Color("RezSysColor", bundle: .module):
            .accentColor)
    }
}
