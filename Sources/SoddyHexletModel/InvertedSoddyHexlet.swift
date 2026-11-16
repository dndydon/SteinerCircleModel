/// A general Soddy's hexlet: three mutually tangent spheres A, B, and C,
/// and a ring of six spheres each tangent to A, B, C, and its two neighbors.
///
/// Inverting the standard-form `SoddyHexlet` produces one, and
/// `init(tangentTo:_:_:phase:)` builds one around any three mutually
/// tangent spheres. A and B are the
/// images of the two planes, and C is the image of the nucleus. When the
/// inversion center lies inside one of the original regions, that sphere's
/// image encloses all the others; `enclosingSphere` returns it.

import simd

public struct InvertedSoddyHexlet: Sendable {
  public let a: Sphere3D
  public let b: Sphere3D
  public let c: Sphere3D
  /// The ring, in the same order as `SoddyHexlet.ringSpheres`.
  public let spheres: [Sphere3D]

  /// The sphere that contains every other sphere, or nil when none does
  /// (the inversion center was outside every original region).
  public var enclosingSphere: Sphere3D? {
    let all = [a, b, c] + spheres
    return all.first { outer in
      all.allSatisfy { $0 == outer || Self.encloses(outer, $0) }
    }
  }

  /// Whether `outer` contains `inner`, allowing internal tangency.
  private static func encloses(_ outer: Sphere3D, _ inner: Sphere3D) -> Bool {
    simd_distance(outer.center, inner.center) + inner.radius <= outer.radius * (1 + 1e-9)
  }
}

// MARK: - Errors

/// Why a hexlet can't be built from three spheres.
public enum HexletError: Error, Equatable, Sendable {
  /// The three spheres aren't pairwise tangent (internally or externally),
  /// or two of them coincide.
  case notMutuallyTangent
  /// A sphere has a non-positive radius, all three spheres touch at one
  /// point, or at this phase a ring sphere would pass through the A–B
  /// contact point (its image would be a plane).
  case degenerate
}

// MARK: - From Three Tangent Spheres

extension InvertedSoddyHexlet {

  /// The hexlet whose ring touches the three mutually tangent spheres
  /// `a`, `b`, and `c`.
  ///
  /// Inverting at the point where `a` and `b` touch turns them into
  /// parallel planes and `c` into a sphere between them. That is a standard
  /// hexlet, built here and inverted back. Any pair may touch internally,
  /// so `a` can enclose the others. `phase` turns the ring; phase 0 is a
  /// fixed but arbitrary starting position. Tangency is checked to a
  /// relative tolerance of 1e-9.
  public init(tangentTo a: Sphere3D, _ b: Sphere3D, _ c: Sphere3D,
              phase: Double = 0) throws(HexletError) {
    guard a.radius > 0, b.radius > 0, c.radius > 0 else { throw .degenerate }
    guard Self.areTangent(a, b), Self.areTangent(a, c), Self.areTangent(b, c) else {
      throw .notMutuallyTangent
    }

    // Contact point of a and b. Centers are distinct (checked above).
    let axis = simd_normalize(b.center - a.center)
    let external = abs(simd_distance(a.center, b.center) - (a.radius + b.radius))
      <= Self.tolerance(a, b)
    let contact = external || a.radius > b.radius
      ? a.center + axis * a.radius
      : a.center - axis * a.radius

    let inversion = SphereInversion(center: contact, radius: a.radius + b.radius)
    guard let nucleus = inversion.invert(c) else { throw .degenerate }

    // Frame of the standard form: z along the slab axis, origin at the
    // nucleus. Any perpendicular pair works for x and y.
    let helper: SIMD3<Double> = abs(axis.x) < 0.9 ? [1, 0, 0] : [0, 1, 0]
    let x = simd_normalize(simd_cross(axis, helper))
    let y = simd_cross(axis, x)

    var spheres: [Sphere3D] = []
    for local in SoddyHexlet(radius: nucleus.radius, phase: phase).ringSpheres {
      let p = local.center
      let world = Sphere3D(center: nucleus.center + x * p.x + y * p.y + axis * p.z,
                           radius: local.radius)
      guard let inverted = inversion.invert(world) else { throw .degenerate }
      spheres.append(inverted)
    }

    self.init(a: a, b: b, c: c, spheres: spheres)
  }

  /// Whether two spheres touch internally or externally. Coincident
  /// spheres don't count.
  private static func areTangent(_ s: Sphere3D, _ t: Sphere3D) -> Bool {
    let d = simd_distance(s.center, t.center)
    let tolerance = tolerance(s, t)
    return d > tolerance
      && (abs(d - (s.radius + t.radius)) <= tolerance
          || abs(d - abs(s.radius - t.radius)) <= tolerance)
  }

  private static func tolerance(_ s: Sphere3D, _ t: Sphere3D) -> Double {
    1e-9 * max(s.radius, t.radius)
  }
}

extension InvertedSoddyHexlet: CustomStringConvertible {
  public var description: String {
    """
    InvertedSoddyHexlet(\(spheres.count) spheres)
      a: \(a)
      b: \(b)
      c: \(c)
    """
  }
}
