/// A general Soddy's hexlet: three mutually tangent spheres A, B, and C,
/// and a ring of six spheres each tangent to A, B, C, and its two neighbors.
///
/// Inverting the standard-form `SoddyHexlet` produces one. A and B are the
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
