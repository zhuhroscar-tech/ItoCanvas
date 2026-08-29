import SwiftUI

@main
struct ItoCanvasApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("ItoCanvas") {
            RootView()
                .environmentObject(model)
                .preferredColorScheme(model.workspace.appearance.colorScheme)
                .frame(minWidth: 920, minHeight: 640)
        }
        .defaultSize(width: 1240, height: 820)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandMenu("Navigate") {
                navigationCommand("Overview", section: .overview, key: "1")
                navigationCommand("Options Pricer", section: .pricer, key: "2")
                navigationCommand("Strategy Studio", section: .strategy, key: "3")
                navigationCommand("Scenario Lab", section: .scenarios, key: "4")
                navigationCommand("Model & Privacy", section: .guide, key: "5")
            }

            CommandGroup(after: .sidebar) {
                Divider()
                Button("Reset Local Workspace…") {
                    model.navigate(to: .guide)
                }
                .help("Open workspace privacy and reset controls")
            }
        }
    }

    @ViewBuilder
    private func navigationCommand(_ title: String, section: AppSection, key: KeyEquivalent) -> some View {
        Button(title) {
            model.navigate(to: section)
        }
        .keyboardShortcut(key, modifiers: .command)
    }
}
