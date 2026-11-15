// Slider and DragGesture are unavailable on tvOS.
#if !os(tvOS)
import SteinerCircleModel
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
  @State private var isRotating = false

  private let outerRadius: CGFloat = 140
  /// Chain rotation speed in radians per second.
  private let rotationSpeed: Double = 0.5

  private func model(phase: CGFloat) -> SteinerCircle {
    SteinerCircle(
      outerRadius: outerRadius,
      circleCount: Int(circleCount),
      gap: gap,
      phase: phase
    )
  }

  var body: some View {
    VStack(spacing: 16) {
      Text(showInversion ? "Inverted Steiner Chain" : "Steiner Circle")
        .font(.title2.bold())

      TimelineView(.animation(paused: !isRotating)) { timeline in
        // Wrap the phase so it stays small; the chain looks identical
        // after every full turn.
        let elapsed = timeline.date.timeIntervalSinceReferenceDate * rotationSpeed
        let phase = isRotating ? CGFloat(elapsed.truncatingRemainder(dividingBy: 2 * .pi)) : 0

        Canvas { context, size in
          let center = CGPoint(x: size.width / 2, y: size.height / 2)
          let sc = model(phase: phase)

          if showInversion {
            drawInverted(context: context, center: center, sc: sc)
          } else {
            drawConcentric(context: context, center: center, sc: sc)
          }
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
      .onTapGesture(count: 2) {
        if showInversion {
          inversionOffset = .zero
        }
      }
      
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
        Toggle("Rotate Chain", isOn: $isRotating)
          .font(.caption)
        Text("Drag to move inversion center")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .opacity(showInversion ? 1.0 : 0.0)
      }
      .padding(.horizontal)
    }
    .padding()
    .frame(width: 400)
  }

    // MARK: - Concentric Drawing

  private func drawConcentric(context: GraphicsContext, center: CGPoint,
                              sc: SteinerCircle) {
    drawCircle(context: context, center: center, circle: sc.outerCircle,
               scale: 1, fill: nil, stroke: .blue)
    drawCircle(context: context, center: center, circle: sc.innerCircle,
               scale: 1, fill: nil, stroke: .red)

    for circle in sc.chainCircles {
      drawCircle(context: context, center: center, circle: circle,
                 scale: 1, fill: .green.opacity(0.3), stroke: .green)
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
    let scale = maxExtent > outerRadius ? outerRadius / maxExtent : 1.0

      // Draw inverted outer circle
    drawCircle(context: context, center: center, circle: inverted.outerCircle,
               scale: scale, fill: nil, stroke: .blue)

      // Draw inverted inner circle
    drawCircle(context: context, center: center, circle: inverted.innerCircle,
               scale: scale, fill: nil, stroke: .red)

      // Draw inverted chain circles
    for circle in inverted.chainCircles {
      drawCircle(context: context, center: center, circle: circle,
                 scale: scale, fill: .orange.opacity(0.3), stroke: .orange)
    }

      // Mark inversion center
    let dot = Path(Circle2D(center: invCenter, radius: 3 / scale),
                   scale: scale, offset: center)
    context.fill(dot, with: .color(.white))
    context.stroke(dot, with: .color(.primary), lineWidth: 1)
  }

    // MARK: - Drawing Helpers

  private func drawCircle(context: GraphicsContext, center: CGPoint,
                          circle: Circle2D, scale: CGFloat,
                          fill: Color?, stroke: Color) {
    let path = Path(circle, scale: scale, offset: center)
    if let fill {
      context.fill(path, with: .color(fill))
    }
    context.stroke(path, with: .color(stroke), lineWidth: 1.5)
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
#endif
