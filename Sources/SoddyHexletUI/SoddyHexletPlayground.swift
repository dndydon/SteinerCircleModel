// Slider is unavailable on tvOS, and RealityKit on watchOS.
#if canImport(RealityKit) && !os(tvOS)
import RealityKit
import SoddyHexletModel
import SwiftUI

#Preview("Soddy Hexlet Demo") {
  if #available(iOS 18, macOS 15, visionOS 1, *) {
    SoddyHexletDemo()
  }
}

  // MARK: - Demo View

@available(iOS 18, macOS 15, visionOS 1, *)
struct SoddyHexletDemo: View {
  @State private var basePhase: Double = 0
  @State private var isRotating = false
  @State private var offset = SIMD3<Double>(0.35, 0, 0.25)
  @State private var showEnclosing = true
  @State private var scene = HexletScene()

  /// Radius (meters) of the enclosing sphere. Elsewhere it is sized for
  /// RealityKit's default camera; on visionOS it must fit in the window.
  #if os(visionOS)
  private let displayRadius: Double = 0.15
  #else
  private let displayRadius: Double = 0.45
  #endif
  /// Inversion center limit, as a fraction of the nucleus radius, so the
  /// nucleus always becomes the enclosing sphere.
  private let maxOffset: Double = 0.9
  /// Ring rotation speed in radians per second.
  private let rotationSpeed: Double = 0.5

  /// Ring phase at `date`, starting from the Phase slider.
  private func phase(at date: Date) -> Double {
    guard isRotating else { return basePhase }
    let elapsed = date.timeIntervalSinceReferenceDate * rotationSpeed
    return (basePhase + elapsed).truncatingRemainder(dividingBy: 2 * .pi)
  }

  /// Inversion center limited by distance (not per axis) so it stays
  /// inside the nucleus in every direction.
  private var inversionCenter: SIMD3<Double> {
    let length = simd_length(offset)
    return length > maxOffset ? offset * (maxOffset / length) : offset
  }

  /// The standard hexlet (unit radius) inverted from inside its nucleus.
  /// The center never touches a sphere or plane, so this never fails.
  private func model(phase: Double) -> InvertedSoddyHexlet? {
    SoddyHexlet(radius: 1, phase: phase)
      .inverted(through: SphereInversion(center: inversionCenter, radius: 1))
  }

  var body: some View {
    VStack(spacing: 16) {
      Text("Soddy's Hexlet")
        .font(.title2.bold())

      TimelineView(.animation(paused: !isRotating)) { timeline in
        hexletView(model(phase: phase(at: timeline.date)))
      }
      .frame(width: 360, height: 360)
      .background(Color.black.opacity(0.05))
      .clipShape(RoundedRectangle(cornerRadius: 8))

      VStack(spacing: 10) {
        LabeledSlider(label: "Phase: \(String(format: "%.2f", basePhase))",
                      value: $basePhase, range: 0...(2 * .pi))
        LabeledSlider(label: "Inversion X: \(String(format: "%.2f", offset.x))",
                      value: $offset.x, range: -maxOffset...maxOffset)
        LabeledSlider(label: "Inversion Y: \(String(format: "%.2f", offset.y))",
                      value: $offset.y, range: -maxOffset...maxOffset)
        LabeledSlider(label: "Inversion Z: \(String(format: "%.2f", offset.z))",
                      value: $offset.z, range: -maxOffset...maxOffset)
        Toggle("Rotate Ring", isOn: $isRotating)
          .font(.caption)
        Toggle("Show Enclosing Sphere", isOn: $showEnclosing)
          .font(.caption)
        Button("Center Inversion") { offset = .zero }
          .font(.caption)
        #if !os(visionOS)
        Text("Drag to orbit the camera")
          .font(.caption2)
          .foregroundStyle(.secondary)
        #endif
      }
      .padding(.horizontal)
    }
    .padding()
    .frame(width: 400)
  }

    // MARK: - RealityView

  private func hexletView(_ hexlet: InvertedSoddyHexlet?) -> some View {
    RealityView { content in
      content.add(scene.root)
      #if os(iOS)
      content.camera = .virtual
      #endif
    } update: { _ in
      guard let hexlet else { return }
      scene.update(hexlet, displayRadius: displayRadius, showEnclosing: showEnclosing)
    }
    #if !os(visionOS)
    .realityViewCameraControls(.orbit)
    #endif
  }
}

  // MARK: - Scene

/// Entities for one hexlet: unit spheres that `update` moves and scales.
@MainActor
private final class HexletScene {
  let root = Entity()
  private let a: ModelEntity
  private let b: ModelEntity
  private let c: ModelEntity
  private let ring: [ModelEntity]

  init() {
    let mesh = MeshResource.generateSphere(radius: 1)
    // A and B stay neutral so the six ring colors stand out.
    a = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: .lightGray, roughness: 0.4, isMetallic: false)])
    b = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: .darkGray, roughness: 0.4, isMetallic: false)])

    var shell = PhysicallyBasedMaterial()
    shell.baseColor = .init(tint: .white)
    shell.blending = .transparent(opacity: 0.15)
    c = ModelEntity(mesh: mesh, materials: [shell])

    ring = (0..<SoddyHexlet.ringCount).map { i in
      let color = SimpleMaterial.Color(hue: CGFloat(i) / CGFloat(SoddyHexlet.ringCount),
                                       saturation: 0.7, brightness: 0.95, alpha: 1)
      return ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: color, roughness: 0.3, isMetallic: false)])
    }

    for entity in [a, b, c] + ring {
      root.addChild(entity)
    }

    // The model's z-axis (through A and B) points up, tipped toward the
    // viewer so the ring reads as a ring rather than an edge.
    root.orientation = simd_quatf(angle: -(.pi / 2 - 0.35), axis: [1, 0, 0])
  }

  /// Places every sphere so the enclosing one is centered at the origin
  /// with radius `displayRadius`.
  func update(_ hexlet: InvertedSoddyHexlet, displayRadius: Double, showEnclosing: Bool) {
    let bound = hexlet.enclosingSphere ?? hexlet.c
    let scale = displayRadius / bound.radius

    func place(_ entity: ModelEntity, at sphere: Sphere3D) {
      entity.position = SIMD3<Float>((sphere.center - bound.center) * scale)
      entity.scale = SIMD3(repeating: Float(sphere.radius * scale))
    }

    place(a, at: hexlet.a)
    place(b, at: hexlet.b)
    place(c, at: hexlet.c)
    for (entity, sphere) in zip(ring, hexlet.spheres) {
      place(entity, at: sphere)
    }
    c.isEnabled = showEnclosing
  }
}

  // MARK: - Labeled Slider

private struct LabeledSlider: View {
  let label: String
  @Binding var value: Double
  let range: ClosedRange<Double>

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(label).font(.caption).monospacedDigit()
      Slider(value: $value, in: range)
    }
  }
}
#endif
