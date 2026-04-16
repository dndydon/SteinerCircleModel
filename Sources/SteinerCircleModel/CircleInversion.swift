/// Circle inversion (Möbius inversion) through a reference circle.
///
/// Given an inversion circle with center O and radius k:
///   - A point P maps to P' such that |OP| * |OP'| = k²
///   - P' = O + k²/|OP|² * (P - O)
///   - Circles map to circles (unless passing through O, then to lines).
///
/// This is the key operation for transforming a concentric Steiner chain
/// (equal-sized circles) into a non-concentric chain (varying sizes),
/// producing the classic "cascading circles" visual.

import Foundation

public struct CircleInversion: Sendable {
  public let center: CGPoint
  public let radius: CGFloat

  /// k² — cached for efficiency.
  public var radiusSquared: CGFloat { radius * radius }

  public init(center: CGPoint, radius: CGFloat) {
    self.center = center
    self.radius = radius
  }

  // MARK: - Point Inversion

  /// Invert a point through this circle.
  /// Returns nil if the point coincides with the inversion center.
  public func invert(_ point: CGPoint) -> CGPoint? {
    let dx = point.x - center.x
    let dy = point.y - center.y
    let distSq = dx * dx + dy * dy
    guard distSq > 1e-12 else { return nil }
    let scale = radiusSquared / distSq
    return CGPoint(x: center.x + dx * scale, y: center.y + dy * scale)
  }

  // MARK: - Circle Inversion

  /// Invert a circle through this inversion circle.
  ///
  /// Maps a `Circle2D` to another `Circle2D`. If the input circle passes
  /// through the inversion center, the result degenerates to a line
  /// (not handled here — returns nil in that edge case).
  public func invert(_ circle: Circle2D) -> Circle2D? {
    let dx = circle.center.x - center.x
    let dy = circle.center.y - center.y
    let dSq = dx * dx + dy * dy
    let rSq = circle.radius * circle.radius

    // Circle passes through (or very near) the inversion center
    let denominator = dSq - rSq
    guard abs(denominator) > 1e-12 else { return nil }

    let k2 = radiusSquared
    let scale = k2 / denominator

    let newCenter = CGPoint(
      x: center.x + dx * scale,
      y: center.y + dy * scale
    )
    let newRadius = abs(scale) * circle.radius

    return Circle2D(center: newCenter, radius: newRadius)
  }
}

extension CircleInversion: CustomStringConvertible {
  public var description: String {
    "CircleInversion(center: (\(center.x), \(center.y)), radius: \(radius))"
  }
}
