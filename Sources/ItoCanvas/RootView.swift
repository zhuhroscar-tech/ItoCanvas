import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 235, ideal: 260, max: 300)
        } detail: {
            Group {
                switch model.selectedSection {
                case .overview: OverviewView()
                case .pricer: PricerView()
                case .strategy: StrategyView()
                case .scenarios: ScenarioView()
                case .guide: GuideView()
                }
            }
            .frame(minWidth: 680, minHeight: 560)
        }
        .navigationTitle(model.selectedSection.title)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.itoAccent, .itoIndigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "waveform.path.ecg.rectangle.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text("ItoCanvas")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    Text("Options Workbench")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 16)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("ItoCanvas Options Workbench")

            List(AppSection.allCases, selection: $model.selectedSection) { section in
                NavigationLink(value: section) {
                    Label {
                        Text(section.title)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: section.symbol)
                            .foregroundStyle(model.selectedSection == section ? Color.itoAccent : .secondary)
                            .frame(width: 22)
                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .tag(section)
                .help(section.subtitle)
                .accessibilityLabel("\(section.title), \(section.subtitle)")
            }
            .listStyle(.sidebar)

            Divider()
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Label("Appearance", systemImage: "circle.lefthalf.filled")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("Appearance", selection: $model.workspace.appearance) {
                        ForEach(AppearancePreference.allCases) { appearance in
                            Text(appearance.title).tag(appearance)
                        }
                    }
                    .labelsHidden()
                    .controlSize(.small)
                    .frame(width: 90)
                    .help("Choose System, Light, or Dark appearance")
                    .accessibilityLabel("App appearance")
                }
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.itoMint)
                    Text("Saved locally")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("No cloud sync")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(14)
        }
    }
}
