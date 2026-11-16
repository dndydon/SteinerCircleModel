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
  @State private var windings = 1
  @State private var gap: Double = 0.001
  @State private var inversionOffset: CGSize = .zero
  @State private var dragStartOffset: CGSize?
  @State private var showInversion = false
  @State private var isRotating = false

  private let outerRadius: CGFloat = 140
  private let canvasSize: CGFloat = 360
  /// Chain rotation speed in radians per second.
  private let rotationSpeed: Double = 0.5
  /// Largest-to-smallest size ratio when tapping a circle to focus it.
  private let focusMagnification: CGFloat = 4

  private func model(phase: CGFloat) -> SteinerCircle {
    SteinerCircle(
      outerRadius: outerRadius,
      circleCount: Int(circleCount),
      windings: windings,
      gap: gap,
      phase: phase
    )
  }

  /// Largest winding count the model allows for the current circle count.
  private var maxWindings: Int {
    max(1, (Int(circleCount) - 1) / 2)
  }

  /// Winding label, noting when the chain retraces a smaller one.
  private var windingsLabel: String {
    var a = Int(circleCount), b = windings
    while b != 0 { (a, b) = (b, a % b) }
    return a > 1
      ? "Windings: \(windings) (shares a factor with \(Int(circleCount)); circles coincide)"
      : "Windings: \(windings)"
  }

  /// Chain phase at `date`, wrapped to one full turn; the chain looks
  /// identical after every turn.
  private func phase(at date: Date) -> CGFloat {
    guard isRotating else { return 0 }
    let elapsed = date.timeIntervalSinceReferenceDate * rotationSpeed
    return CGFloat(elapsed.truncatingRemainder(dividingBy: 2 * .pi))
  }

  var body: some View {
    VStack(spacing: 16) {
      Text(showInversion ? "Inverted Steiner Chain" : "Steiner Circle")
        .font(.title2.bold())

      TimelineView(.animation(paused: !isRotating)) { timeline in
        let sc = model(phase: phase(at: timeline.date))

        Canvas { context, size in
          let center = CGPoint(x: size.width / 2, y: size.height / 2)

          if showInversion {
            drawInverted(context: context, center: center, sc: sc)
          } else {
            drawConcentric(context: context, center: center, sc: sc)
          }
        }
      }
      .frame(width: canvasSize, height: canvasSize)
      .background(Color.black.opacity(0.05))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .gesture(
        DragGesture()
          .onChanged { value in
            guard showInversion else { return }
            let start = dragStartOffset ?? inversionOffset
            dragStartOffset = start
            inversionOffset = CGSize(width: start.width + value.translation.width,
                                     height: start.height + value.translation.height)
          }
          .onEnded { _ in
            dragStartOffset = nil
          }
      )
      .onTapGesture(count: 2) {
        if showInversion {
          inversionOffset = .zero
        }
      }
      .onTapGesture { location in
        focusCircle(at: location)
      }
      
      VStack(spacing: 10) {
        LabeledSlider(
          label: "Circles: \(Int(circleCount))",
          value: $circleCount,
          range: 2...20,
          step: 1
        )
        Stepper(windingsLabel, value: $windings, in: 1...maxWindings)
          .font(.caption)
          .monospacedDigit()
        LabeledSlider(
          label: "Gap: \(String(format: "%.3f", gap))",
          value: $gap,
          range: 0...0.5
        )
        Toggle("Circle Inversion", isOn: $showInversion)
          .font(.caption)
        Toggle("Rotate Chain", isOn: $isRotating)
          .font(.caption)
        Text("Drag to move inversion center · Tap a circle to focus it")
          .font(.caption2)
          .foregroundStyle(.secondary)
          .opacity(showInversion ? 1.0 : 0.0)
      }
      .padding(.horizontal)
      .onChange(of: circleCount) {
        windings = min(windings, maxWindings)
      }
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
    guard let fitted = fittedInvertedChain(sc, center: center) else { return }

      // Draw inverted outer circle
    drawCircle(context: context, center: .zero, circle: fitted.outerCircle,
               scale: 1, fill: nil, stroke: .blue)

      // Draw inverted inner circle
    drawCircle(context: context, center: .zero, circle: fitted.innerCircle,
               scale: 1, fill: nil, stroke: .red)

      // Draw inverted chain circles
    for circle in fitted.chainCircles {
      drawCircle(context: context, center: .zero, circle: circle,
                 scale: 1, fill: .orange.opacity(0.3), stroke: .orange)
    }

      // Drag handle. The inversion center is a point in the original
      // (concentric) coordinates and has no image after inversion, so
      // show it where the drag puts it rather than inside the drawing.
    let invCenter = clampedInversionCenter(sc)
    let dot = Path(Circle2D(center: invCenter, radius: 3), offset: center)
    context.fill(dot, with: .color(.white))
    context.stroke(dot, with: .color(.primary), lineWidth: 1)
  }

  /// Inversion center offset from the origin, limited by distance (not per
  /// axis) so it stays inside the inner circle in every direction.
  private func clampedInversionCenter(_ sc: SteinerCircle) -> CGPoint {
    let maxOffset = max(sc.innerRadius * 0.9, 1)
    let length = hypot(inversionOffset.width, inversionOffset.height)
    let limit = length > maxOffset ? maxOffset / length : 1
    return CGPoint(x: inversionOffset.width * limit,
                   y: inversionOffset.height * limit)
  }

  /// The inverted chain fitted to the canvas, so its bounding circle stays
  /// fixed while the inner circle and chain move.
  private func fittedInvertedChain(_ sc: SteinerCircle,
                                   center: CGPoint) -> InvertedSteinerChain? {
    let inversion = CircleInversion(center: clampedInversionCenter(sc), radius: outerRadius)
    guard let inverted = sc.inverted(through: inversion) else { return nil }

    let rect = CGRect(x: center.x - outerRadius, y: center.y - outerRadius,
                      width: outerRadius * 2, height: outerRadius * 2)
    return inverted.fitted(in: rect)
  }

    // MARK: - Focus

  /// Focuses the tapped chain circle by moving the inversion center toward it.
  private func focusCircle(at location: CGPoint) {
    guard showInversion else { return }
    let sc = model(phase: phase(at: .now))
    let center = CGPoint(x: canvasSize / 2, y: canvasSize / 2)
    guard let fitted = fittedInvertedChain(sc, center: center),
          let index = fitted.chainIndex(containing: location) else { return }

    let focus = sc.inversion(focusingOn: index, magnification: focusMagnification)
    inversionOffset = CGSize(width: focus.center.x, height: focus.center.y)
  }

    // MARK: - Drawing Helpers

  private func drawCircle(context: GraphicsContext, center: CGPoint,
                          circle: Circle2D, scale: CGFloat,
                          fill: Color?, stroke: Color) {
    let path = Path(circle, scale: scale, offset: center)
    if let fill {
      context.fill(path, with: .color(fill))
    }
    context.stroke(path, with: .color(stroke), lineWidth: 1.1)
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
