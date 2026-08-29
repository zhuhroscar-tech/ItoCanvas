import SwiftUI

extension Color {
    static let itoAccent = Color(red: 0.20, green: 0.45, blue: 0.96)
    static let itoMint = Color(red: 0.12, green: 0.72, blue: 0.58)
    static let itoAmber = Color(red: 0.95, green: 0.62, blue: 0.16)
    static let itoRose = Color(red: 0.91, green: 0.29, blue: 0.42)
    static let itoIndigo = Color(red: 0.45, green: 0.35, blue: 0.94)
}

struct PageHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.1)
                    .foregroundStyle(Color.itoAccent)
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            if let trailing { trailing }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

struct Panel<Content: View>: View {
    let title: String?
    let subtitle: String?
    @ViewBuilder let content: Content

    init(title: String? = nil, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if title != nil || subtitle != nil {
                VStack(alignment: .leading, spacing: 3) {
                    if let title {
                        Text(title)
                            .font(.headline)
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            content
        }
        .padding(18)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    var detail: String? = nil
    var symbol: String
    var tint: Color = .itoAccent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                if let detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.primary.opacity(0.07), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value)\(detail.map { ", \($0)" } ?? "")")
    }
}

struct LabeledNumberField: View {
    let title: String
    @Binding var value: Double
    var suffix: String? = nil
    var help: String? = nil
    var validation: (Double) -> String? = { _ in nil }

    private var error: String? { validation(value) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                if let error {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                        .help(error)
                        .accessibilityLabel(error)
                }
            }
            HStack(spacing: 6) {
                TextField(title, value: $value, format: .number.precision(.fractionLength(0...4)))
                    .textFieldStyle(.plain)
                    .monospacedDigit()
                    .accessibilityLabel(title)
                    .accessibilityValue(value.formatted())
                if let suffix {
                    Text(suffix)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(error == nil ? Color.primary.opacity(0.12) : Color.red.opacity(0.8), lineWidth: error == nil ? 1 : 1.5)
            }
            .help(help ?? error ?? title)
        }
    }
}

struct ValidationBanner: View {
    let title: String
    let messages: [String]

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                ForEach(messages, id: \.self) { message in
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.orange.opacity(0.25))
        }
        .accessibilityElement(children: .combine)
    }
}

struct AppEmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Color.itoAccent)
                .frame(width: 56, height: 56)
                .background(Color.itoAccent.opacity(0.10), in: Circle())
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 240)
        .accessibilityElement(children: .combine)
    }
}

struct StatusPill: View {
    let text: String
    let symbol: String
    var color: Color = .itoMint

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.10), in: Capsule())
            .accessibilityLabel(text)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

extension Double {
    var currencyText: String {
        formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }

    var signedCurrencyText: String {
        let prefix = self > 0 ? "+" : ""
        return prefix + currencyText
    }

    var compactNumberText: String {
        formatted(.number.precision(.fractionLength(2...4)))
    }
}
