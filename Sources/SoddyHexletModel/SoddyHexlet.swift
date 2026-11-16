/// SoddyHexlet
/// Soddy's hexlet in standard form: a ring of six equal spheres, each
/// tangent to its two neighbors, to a central nucleus, and to two parallel
/// planes. It is the 3D analog of a Steiner chain.
///
/// Given:
///   - `radius` r — radius of the nucleus and of every ring sphere
///   - `phase` — rotation of the ring about the z-axis
///
/// Layout:
///   - planes A and B at z = r and z = −r
///   - nucleus C of radius r at the origin
///   - six ring spheres of radius r, centers at distance 2r in the z = 0
///     plane, 60° apart
///
/// The z = 0 slice is a six-circle Steiner chain with outer radius 3r,
/// so the ring is built from `SteinerCircle` and lifted into 3D. Any
/// hexlet is this standard form inverted through a sphere.

import CoreGraphics
import SteinerCircleModel
import simd

public struct SoddyHexlet: Sendable {

  /// Number of spheres in the ring.
  public static let ringCount = 6

  public let radius: Double
  /// Rotation (radians) of the ring about the z-axis.
  /// The ring stays tangent to everything at any phase.
  public let phase: Double

  public init(radius: Double, phase: Double = 0) {
    self.radius = radius
    self.phase = phase
  }

  /// The z = 0 cross-section: a tangent six-circle Steiner chain.
  public var slice: SteinerCircle {
    SteinerCircle(outerRadius: CGFloat(3 * radius), circleCount: Self.ringCount,
                  gap: 0, phase: CGFloat(phase))
  }

  // MARK: - Spheres and Planes

  /// Radius of each ring sphere (equal to `radius`).
  public var ringRadius: Double { Double(slice.rho) }

  /// Center of the i-th ring sphere (0-based), in the z = 0 plane.
  /// Sphere 0 is on the −y axis when `phase` is 0, matching `SteinerCircle`.
  public func centerPoint(at index: Int) -> SIMD3<Double> {
    let p = slice.centerPoint(at: index)
    return SIMD3(Double(p.x), Double(p.y), 0)
  }

  /// The six ring spheres.
  public var ringSpheres: [Sphere3D] {
    (0..<Self.ringCount).map { Sphere3D(center: centerPoint(at: $0), radius: ringRadius) }
  }

  /// The nucleus C at the origin — the slice's inner circle.
  public var nucleus: Sphere3D {
    Sphere3D(center: .zero, radius: Double(slice.innerRadius))
  }

  /// Plane A at z = r. Its normal points away from the ring.
  public var planeA: Plane3D {
    Plane3D(normal: [0, 0, 1], offset: ringRadius)
  }

  /// Plane B at z = −r. Its normal points away from the ring.
  public var planeB: Plane3D {
    Plane3D(normal: [0, 0, -1], offset: ringRadius)
  }

  /// Index of the ring sphere opposite `index`. Wraps around the ring.
  public static func opposite(_ index: Int) -> Int {
    ((index + ringCount / 2) % ringCount + ringCount) % ringCount
  }

  // MARK: - Inversion

  /// Invert this hexlet through a `SphereInversion`, producing a general
  /// hexlet whose planes become spheres and whose ring spheres vary in size.
  /// Returns nil if the inversion center lies on any sphere or plane.
  public func inverted(through inversion: SphereInversion) -> InvertedSoddyHexlet? {
    guard let a = inversion.invert(planeA),
          let b = inversion.invert(planeB),
          let c = inversion.invert(nucleus) else {
      return nil
    }

    var spheres: [Sphere3D] = []
    for sphere in ringSpheres {
      guard let inverted = inversion.invert(sphere) else { return nil }
      spheres.append(inverted)
    }

    return InvertedSoddyHexlet(a: a, b: b, c: c, spheres: spheres)
  }
}

// MARK: - CustomStringConvertible

extension SoddyHexlet: CustomStringConvertible {
  public var description: String {
    "SoddyHexlet(radius: \(radius), phase: \(phase))"
  }
}
