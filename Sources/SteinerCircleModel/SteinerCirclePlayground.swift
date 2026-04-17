import SwiftUI

#Preview("Steiner Circle Demo") {
    SteinerCircleDemo()
}

// MARK: - Demo View

struct SteinerCircleDemo: View {
    @State private var circleCount: Double = 6
    @State private var gap: Double = 0.001
    @State private var inversionOffset: CGSize = .zero
    @State private var showInversion = false

    private let outerRadius: CGFloat = 140

    private var model: SteinerCircle {
        SteinerCircle(
            outerRadius: outerRadius,
            circleCount: Int(circleCount),
            gap: gap
        )
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(showInversion ? "Inverted Steiner Chain" : "Steiner Circle")
                .font(.title2.bold())

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let sc = model

                if showInversion {
                    drawInverted(context: context, center: center, sc: sc)
                } else {
                    drawConcentric(context: context, center: center, sc: sc)
                }
            }
            .frame(width: 360, height: 360)
            .background(Color.black.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if showInversion {
                            inversionOffset = value.translation
                        }
                    }
            )

            VStack(spacing: 10) {
                LabeledSlider(
                    label: "Circles: \(Int(circleCount))",
                    value: $circleCount,
                    range: 2...20,
                    step: 1
                )
                LabeledSlider(
                    label: "Gap: \(String(format: "%.3f", gap))",
                    value: $gap,
                    range: 0.001...0.5
                )
                Toggle("Circle Inversion", isOn: $showInversion)
                    .font(.caption)
                if showInversion {
                    Text("Drag to move inversion center")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 400)
    }

    // MARK: - Concentric Drawing

    private func drawConcentric(context: GraphicsContext, center: CGPoint,
                                sc: SteinerCircle) {
        strokeCircle(context: context, center: center,
                     radius: sc.outerRadius, color: .blue)
        strokeCircle(context: context, center: center,
                     radius: sc.innerRadius, color: .red)

        for circle in sc.chainCircles {
            let pos = CGPoint(x: center.x + circle.center.x,
                              y: center.y + circle.center.y)
            fillCircle(context: context, center: pos,
                       radius: circle.radius, color: .green.opacity(0.3))
            strokeCircle(context: context, center: pos,
                         radius: circle.radius, color: .green)
        }
    }

    // MARK: - Inverted Drawing

    private func drawInverted(context: GraphicsContext, center: CGPoint,
                              sc: SteinerCircle) {
        // Inversion center offset from the origin, clamped inside the inner circle
        let maxOffset = max(sc.innerRadius * 0.9, 1)
        let dx = min(max(inversionOffset.width, -maxOffset), maxOffset)
        let dy = min(max(inversionOffset.height, -maxOffset), maxOffset)
        let invCenter = CGPoint(x: dx, y: dy)
        let inversion = CircleInversion(center: invCenter, radius: outerRadius)

        guard let inverted = sc.inverted(through: inversion) else { return }

        // Find the bounding extent of the inverted outer circle to scale-to-fit
        let allCircles = [inverted.outerCircle, inverted.innerCircle] + inverted.chainCircles
        let maxExtent = allCircles.map { circle in
            max(abs(circle.center.x) + circle.radius,
                abs(circle.center.y) + circle.radius)
        }.max() ?? outerRadius
        let canvasHalf = min(center.x, center.y) - 4
        let scale = maxExtent > canvasHalf ? canvasHalf / maxExtent : 1.0

        // Draw inverted outer circle
        drawScaledCircle(context: context, center: center, circle: inverted.outerCircle,
                         scale: scale, fill: nil, stroke: .blue)

        // Draw inverted inner circle
        drawScaledCircle(context: context, center: center, circle: inverted.innerCircle,
                         scale: scale, fill: nil, stroke: .red)

        // Draw inverted chain circles
        for circle in inverted.chainCircles {
            drawScaledCircle(context: context, center: center, circle: circle,
                             scale: scale, fill: .orange.opacity(0.3), stroke: .orange)
        }

        // Mark inversion center
        let invPos = CGPoint(x: center.x + invCenter.x * scale,
                             y: center.y + invCenter.y * scale)
        let dotSize: CGFloat = 6
        let dotRect = CGRect(x: invPos.x - dotSize / 2, y: invPos.y - dotSize / 2,
                             width: dotSize, height: dotSize)
        context.fill(Path(ellipseIn: dotRect), with: .color(.white))
        context.stroke(Path(ellipseIn: dotRect), with: .color(.primary), lineWidth: 1)
    }

    private func drawScaledCircle(context: GraphicsContext, center: CGPoint,
                                  circle: Circle2D, scale: CGFloat,
                                  fill: Color?, stroke: Color) {
        let pos = CGPoint(x: center.x + circle.center.x * scale,
                          y: center.y + circle.center.y * scale)
        let r = circle.radius * scale
        if let fill {
            fillCircle(context: context, center: pos, radius: r, color: fill)
        }
        strokeCircle(context: context, center: pos, radius: r, color: stroke)
    }

    // MARK: - Drawing Helpers

    private func strokeCircle(context: GraphicsContext, center: CGPoint,
                              radius: CGFloat, color: Color) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius,
                          width: radius * 2, height: radius * 2)
        context.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: 1.5)
    }

    private func fillCircle(context: GraphicsContext, center: CGPoint,
                            radius: CGFloat, color: Color) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius,
                          width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }
}

// MARK: - Labeled Slider

private struct LabeledSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).monospacedDigit()
            if let step {
                Slider(value: $value, in: range, step: step)
            } else {
                Slider(value: $value, in: range)
            }
        }
    }
}
