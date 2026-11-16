/// Inversion through a reference sphere — the 3D form of `CircleInversion`.
///
/// Given an inversion sphere with center O and radius s:
///   - A point P maps to P' = O + s²/|OP|² · (P − O)
///   - Spheres map to spheres, unless they pass through O (then planes).
///   - Planes map to spheres through O, unless they contain O.
///
/// Signed curvature: a sphere's image has curvature (|c − O|² − ρ²)/(s²ρ),
/// and a plane x · n = h has curvature 2δ/s² with δ = h − O · n. A negative
/// value means the image encloses the others (O lay inside the original).

import simd

public struct SphereInversion: Sendable, Equatable {
  public let center: SIMD3<Double>
  public let radius: Double

  /// s² — cached for efficiency.
  public var radiusSquared: Double { radius * radius }

  public init(center: SIMD3<Double>, radius: Double) {
    self.center = center
    self.radius = radius
  }

  // MARK: - Point Inversion

  /// Invert a point through this sphere.
  /// Returns nil if the point coincides with the inversion center.
  public func invert(_ point: SIMD3<Double>) -> SIMD3<Double>? {
    let d = point - center
    let distSq = simd_length_squared(d)
    guard distSq > 1e-12 else { return nil }
    return center + d * (radiusSquared / distSq)
  }

  // MARK: - Sphere Inversion

  /// Invert a sphere through this inversion sphere.
  /// Returns nil if the sphere passes through the inversion center,
  /// where its image would be a plane.
  public func invert(_ sphere: Sphere3D) -> Sphere3D? {
    guard let power = power(of: sphere) else { return nil }
    let scale = radiusSquared / power
    return Sphere3D(center: center + (sphere.center - center) * scale,
                    radius: abs(scale) * sphere.radius)
  }

  /// Signed curvature of the image of `sphere`, or nil if it passes
  /// through the inversion center.
  public func signedCurvature(ofImageOf sphere: Sphere3D) -> Double? {
    guard let power = power(of: sphere) else { return nil }
    return power / (radiusSquared * sphere.radius)
  }

  // MARK: - Plane Inversion

  /// Invert a plane through this inversion sphere. The image is a sphere
  /// through the inversion center. Returns nil if the plane contains the
  /// inversion center, where its image would be the plane itself.
  public func invert(_ plane: Plane3D) -> Sphere3D? {
    guard let delta = delta(of: plane) else { return nil }
    // The foot of the perpendicular from O maps to the far end of a
    // diameter through O, so the center sits halfway along the normal.
    let half = radiusSquared / (2 * delta)
    return Sphere3D(center: center + plane.normal * half, radius: abs(half))
  }

  /// Signed curvature of the image of `plane`, or nil if the plane
  /// contains the inversion center.
  public func signedCurvature(ofImageOf plane: Plane3D) -> Double? {
    guard let delta = delta(of: plane) else { return nil }
    return 2 * delta / radiusSquared
  }

  // MARK: - Helpers

  /// Power of the inversion center with respect to `sphere`, or nil near 0.
  private func power(of sphere: Sphere3D) -> Double? {
    let power = simd_distance_squared(sphere.center, center) - sphere.radius * sphere.radius
    guard abs(power) > 1e-12 else { return nil }
    return power
  }

  /// δ = h − O · n, the signed distance from the inversion center to the
  /// plane (positive outside the interior), or nil near 0.
  private func delta(of plane: Plane3D) -> Double? {
    let delta = -plane.signedDistance(to: center)
    guard abs(delta) > 1e-12 else { return nil }
    return delta
  }
}

extension SphereInversion: CustomStringConvertible {
  public var description: String {
    "SphereInversion(center: (\(center.x), \(center.y), \(center.z)), radius: \(radius))"
  }
}
