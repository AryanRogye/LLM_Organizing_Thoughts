import SwiftUI

struct SpaceCarouselView: View {
    let spaces: [Space]
    var onTap: (Space) -> Void = { _ in }

    var body: some View {
        GeometryReader { outerGeo in
            let containerMidX = outerGeo.size.width / 2
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(spaces, id: \.self) { space in
                        Button(action: { onTap(space) }) {
                            GeometryReader { geo in
                                let card = SpaceCard(name: space.name)
                                let scale = scaleForCentering(geo: geo, containerMidX: containerMidX)
                                card
                                    .scaleEffect(scale)
                            }
                            .frame(width: outerGeo.size.width * 0.84, height: 140)
                        }
                        .buttonStyle(.plain)
                        .containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: 12)
                    }
                }
                .scrollTargetLayout()
            }
            .coordinateSpace(name: "carousel")
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
        }
        .frame(height: 170)
    }

    private func scaleForCentering(geo: GeometryProxy, containerMidX: CGFloat) -> CGFloat {
        // Compute a subtle scaling based on the card's distance from container center
        let frame = geo.frame(in: .named("carousel"))
        let distance = abs(frame.midX - containerMidX)
        // Map distance to a scale between 0.92 and 1.0
        let maxDistance: CGFloat = 220
        let normalized = max(0, min(1, 1 - (distance / maxDistance)))
        return 0.92 + (0.08 * normalized)
    }
}

private struct SpaceCard: View {
    let name: String

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 8)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("Open space")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
    }
}

#Preview {
    let sample = [
        Space(name: "Personal"),
        Space(name: "Work"),
        Space(name: "Ideas"),
        Space(name: "Reading List")
    ]
    return SpaceCarouselView(spaces: sample) { _ in }
        .padding()
        .background(Color(.systemBackground))
}
