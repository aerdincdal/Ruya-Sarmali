import SwiftUI

struct AstroBackgroundView: View {
    @State private var stars = StarParticle.generate(count: 95)
    @State private var constellations = ConstellationPath.generate(count: 5)

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                drawGradient(in: &context, size: size, date: timeline.date)
                drawStars(in: &context, size: size, date: timeline.date)
                drawConstellations(in: &context, size: size, date: timeline.date)
                drawShootingStar(in: &context, size: size, date: timeline.date)
            }
        }
        .blur(radius: 0.5)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func drawGradient(in context: inout GraphicsContext, size: CGSize, date: Date) {
        let gradient = Gradient(colors: [Color(hex: 0x02050f), Color(hex: 0x0b1030), Color(hex: 0x39185c)])
        let shading = GraphicsContext.Shading.linearGradient(gradient,
                                                             startPoint: .zero,
                                                             endPoint: CGPoint(x: size.width, y: size.height))
        context.fill(Path(CGRect(origin: .zero, size: size)), with: shading)

        let pulse = (sin(date.timeIntervalSinceReferenceDate) + 1) / 2
        let overlay = Color.purple.opacity(0.05 + pulse * 0.05)
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(overlay))
    }

    private func drawStars(in context: inout GraphicsContext, size: CGSize, date: Date) {
        for star in stars {
            let phase = CGFloat(date.timeIntervalSince1970 * star.speed).truncatingRemainder(dividingBy: 1)
            let x = (star.basePosition.x + phase * 0.02).truncatingRemainder(dividingBy: 1)
            let position = CGPoint(x: x * size.width, y: star.basePosition.y * size.height)
            let pulse = 0.5 + 0.5 * sin(date.timeIntervalSinceReferenceDate * star.twinkleFrequency)
            let circle = Path(ellipseIn: CGRect(x: position.x, y: position.y, width: star.size, height: star.size))
            context.fill(circle, with: .color(Color.white.opacity(0.4 + 0.4 * pulse)))
        }
    }

    private func drawConstellations(in context: inout GraphicsContext, size: CGSize, date: Date) {
        for constellation in constellations {
            var path = Path()
            guard let first = constellation.points.first else { continue }
            path.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))
            for point in constellation.points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
            }
            let animation = 0.4 + 0.2 * sin(date.timeIntervalSinceNow * 0.3 + constellation.phase)
            context.stroke(path, with: .color(Color.white.opacity(0.18 + animation)), lineWidth: 1.2)
        }
    }

    private func drawShootingStar(in context: inout GraphicsContext, size: CGSize, date: Date) {
        let interval = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 6)
        guard interval < 1.3 else { return }
        let progress = interval / 1.3
        let start = CGPoint(x: size.width * (0.2 + progress * 0.6), y: size.height * (0.1 + progress * 0.2))
        let end = CGPoint(x: start.x - 120, y: start.y + 90)
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(path, with: .color(Color.white.opacity(0.2 + progress * 0.7)), lineWidth: 2.4)
    }
}

private struct StarParticle {
    let basePosition: CGPoint
    let speed: Double
    let size: CGFloat
    let twinkleFrequency: Double

    static func generate(count: Int) -> [StarParticle] {
        (0..<count).map { _ in
            StarParticle(
                basePosition: CGPoint(x: Double.random(in: 0...1), y: Double.random(in: 0...1)),
                speed: Double.random(in: 0.2...0.8),
                size: CGFloat.random(in: 0.6...2.8),
                twinkleFrequency: Double.random(in: 0.8...1.6)
            )
        }
    }
}

private struct ConstellationPath {
    let points: [CGPoint]
    let phase: Double

    static func generate(count: Int) -> [ConstellationPath] {
        (0..<count).map { _ in
            let start = CGPoint(x: Double.random(in: 0.05...0.95), y: Double.random(in: 0.05...0.95))
            let segments = Int.random(in: 3...5)
            let points = (0..<segments).scan(start) { previous, _ in
                CGPoint(x: min(max(previous.x + Double.random(in: -0.08...0.08), 0.05), 0.95),
                        y: min(max(previous.y + Double.random(in: -0.08...0.08), 0.05), 0.95))
            }
            return ConstellationPath(points: points, phase: Double.random(in: 0...1))
        }
    }
}

private extension Sequence {
    func scan<T>(_ initial: T, _ transform: (T, Element) -> T) -> [T] {
        var result: [T] = []
        var value = initial
        for element in self {
            value = transform(value, element)
            result.append(value)
        }
        return result
    }
}
