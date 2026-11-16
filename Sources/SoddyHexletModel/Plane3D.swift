/// A plane in 3D space: the points x with x · normal = offset.
///
/// The plane's interior is the half-space the normal points into
/// (x · normal ≥ offset). Inversion uses this to orient the image sphere,
/// so the sign of its curvature matches the side the plane bounds.

import simd

public struct Plane3D: Sendable, Equatable {
  /// Unit normal, pointing into the interior.
  public let normal: SIMD3<Double>
  /// Signed distance from the origin along `normal`.
  public let offset: Double

  /// A plane with the given normal (normalized here) and offset.
  public init(normal: SIMD3<Double>, offset: Double) {
    let length = simd_length(normal)
    self.normal = normal / length
    self.offset = offset / length
  }

  /// The plane through `point` with the given normal.
  public init(normal: SIMD3<Double>, through point: SIMD3<Double>) {
    let unit = simd_normalize(normal)
    self.normal = unit
    self.offset = simd_dot(unit, point)
  }

  /// Signed distance from `point` to the plane; positive on the interior side.
  public func signedDistance(to point: SIMD3<Double>) -> Double {
    simd_dot(normal, point) - offset
  }
}

extension Plane3D: CustomStringConvertible {
  public var description: String {
    "Plane3D(normal: (\(normal.x), \(normal.y), \(normal.z)), offset: \(offset))"
  }
}
