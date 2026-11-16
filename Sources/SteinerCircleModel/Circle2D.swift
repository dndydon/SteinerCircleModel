/// A circle in 2D space, defined by its center and radius.

import CoreGraphics
import Foundation

public struct Circle2D: Sendable {
  public var center: CGPoint
  public var radius: CGFloat

  public init(center: CGPoint = .zero, radius: CGFloat) {
    self.center = center
    self.radius = radius
  }

  public static func == (lhs: Circle2D, rhs: Circle2D) -> Bool {
    lhs.center.x == rhs.center.x &&
    lhs.center.y == rhs.center.y &&
    lhs.radius == rhs.radius
  }
}

extension Circle2D: Equatable {}

extension Circle2D: Hashable {
  // CGPoint isn't Hashable, so hash its components.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(center.x)
    hasher.combine(center.y)
    hasher.combine(radius)
  }
}

extension Circle2D: Codable {}

// MARK: - Hit Testing

extension Circle2D {
  /// Whether `point` lies inside or on this circle.
  public func contains(_ point: CGPoint) -> Bool {
    let dx = point.x - center.x
    let dy = point.y - center.y
    return dx * dx + dy * dy <= radius * radius
  }
}

// MARK: - Transforms

extension Circle2D {
  /// This circle moved by `dx` and `dy`.
  public func offsetBy(dx: CGFloat, dy: CGFloat) -> Circle2D {
    Circle2D(center: CGPoint(x: center.x + dx, y: center.y + dy), radius: radius)
  }

  /// This circle scaled by `factor` about `anchor`. The radius scales by
  /// the factor's magnitude, so a negative factor reflects through `anchor`.
  public func scaled(by factor: CGFloat, about anchor: CGPoint = .zero) -> Circle2D {
    Circle2D(center: CGPoint(x: anchor.x + (center.x - anchor.x) * factor,
                             y: anchor.y + (center.y - anchor.y) * factor),
             radius: radius * abs(factor))
  }

  /// This circle mapped through a similarity transform (uniform scale,
  /// rotation, translation). Non-uniform transforms would turn circles
  /// into ellipses, so this stays internal to the fitting code.
  func applying(_ transform: CGAffineTransform) -> Circle2D {
    Circle2D(center: center.applying(transform),
             radius: radius * hypot(transform.a, transform.b))
  }
}

// MARK: - Float Conversion

extension Circle2D {
  /// A circle from single-precision values, such as RealityKit positions.
  public init(center: SIMD2<Float>, radius: Float) {
    self.init(center: CGPoint(x: CGFloat(center.x), y: CGFloat(center.y)),
              radius: CGFloat(radius))
  }

  /// `center` as single precision, for RealityKit transforms.
  public var floatCenter: SIMD2<Float> {
    SIMD2<Float>(Float(center.x), Float(center.y))
  }

  /// `radius` as single precision, for RealityKit meshes and scales.
  public var floatRadius: Float { Float(radius) }
}

extension Circle2D: CustomStringConvertible {
  public var description: String {
    "Circle2D(center: (\(center.x), \(center.y)), radius: \(radius))"
  }
}
