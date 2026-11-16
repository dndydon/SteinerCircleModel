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
  /// This circle mapped through a similarity transform (uniform scale,
  /// rotation, translation). Non-uniform transforms would turn circles
  /// into ellipses, so this stays internal to the fitting code.
  func applying(_ transform: CGAffineTransform) -> Circle2D {
    Circle2D(center: center.applying(transform),
             radius: radius * hypot(transform.a, transform.b))
  }
}

extension Circle2D: CustomStringConvertible {
  public var description: String {
    "Circle2D(center: (\(center.x), \(center.y)), radius: \(radius))"
  }
}
