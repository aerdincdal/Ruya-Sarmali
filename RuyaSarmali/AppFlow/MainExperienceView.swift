import SwiftUI

struct MainExperienceView: View {
    @EnvironmentObject private var repository: DreamRepository
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var generator: DreamGenerationViewModel
    @ObservedObject private var localization = LocalizationManager.shared
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                DreamNarrationView()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label(L10n.tabDream, systemImage: "sparkles") }
            .tag(0)

            NavigationStack {
                DreamInterpretationsView()
            }
            .tabItem { Label(L10n.tabInterpretations, systemImage: "moon.stars.fill") }
            .tag(1)

            NavigationStack {
                DreamHistoryView()
            }
            .tabItem { Label(L10n.tabArchive, systemImage: "film") }
            .tag(2)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label(L10n.tabSettings, systemImage: "gearshape") }
            .tag(3)
        }
        .tint(Color(hex: 0xE6B6FF))
        .environmentObject(repository)
        .environmentObject(generator)
        .environmentObject(themeManager)
    }
}

